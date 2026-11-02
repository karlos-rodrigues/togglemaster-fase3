#!/usr/bin/env python3
"""Renderiza a captura de terminal (script -T/-O) em vídeo 1920x1080, sem áudio.

Uso: renderiza_terminal.py timing.txt saida.log pasta_frames video.mp4 [pasta_ui]
- comprime pausas longas (MAXGAP) para a espera do CI não ocupar minutos de vídeo
- a linha @@UI@@ no terminal vira uma sequência de telas (PNGs de pasta_ui + captions.txt)
"""
import codecs
import os
import re
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
COLS, ROWS = 130, 33
FS = 23
LH = 31
MARGIN_Y = 24
MAXGAP_ESPERA = 1.2   # esperas longas (CI, apply) viram 1,2 s
LENTO = 2.0           # pausas curtas ficam o dobro para dar tempo de ler sem áudio
FPS = 30
UI_SEG = 10.0
BG = (12, 12, 14)
FG = (229, 229, 229)
PALETA = {1: (255, 100, 100), 2: (60, 220, 100), 3: (250, 230, 80), 4: (110, 160, 255),
          5: (220, 130, 255), 6: (60, 225, 235), 7: FG, 0: (140, 140, 140)}
MARCADOR = "@@UI@@"

FONTE = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", FS)
FONTE_B = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf", FS)
FONTE_T = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 34)
CW = FONTE.getlength("M")
X0 = (W - COLS * CW) / 2


class Tela:
    def __init__(self):
        self.limpa()
        self.fg = 7
        self.bold = False
        self.pend = ""

    def limpa(self):
        self.linhas = [[(" ", 7, False)] * COLS for _ in range(ROWS)]
        self.r = 0
        self.c = 0

    def lf(self):
        if self.r == ROWS - 1:
            self.linhas.pop(0)
            self.linhas.append([(" ", 7, False)] * COLS)
        else:
            self.r += 1

    def poe(self, ch):
        if self.c >= COLS:
            self.c = 0
            self.lf()
        self.linhas[self.r][self.c] = (ch, self.fg, self.bold)
        self.c += 1

    def sgr(self, params):
        nums = [int(p) if p.isdigit() else 0 for p in (params.split(";") if params else ["0"])]
        i = 0
        while i < len(nums):
            n = nums[i]
            if n == 0:
                self.fg, self.bold = 7, False
            elif n == 1:
                self.bold = True
            elif n == 22:
                self.bold = False
            elif 30 <= n <= 37:
                self.fg = n - 30
            elif n == 39:
                self.fg = 7
            elif 90 <= n <= 97:
                self.fg = n - 90
                self.bold = True
            elif n in (38, 48):
                i += 2 if i + 1 < len(nums) and nums[i + 1] == 5 else 4
            i += 1

    def escreve(self, texto):
        s = self.pend + texto
        self.pend = ""
        i = 0
        while i < len(s):
            ch = s[i]
            if ch == "\x1b":
                m = re.compile(r"\x1b\[([0-9;?]*)([A-Za-z])").match(s, i)
                if m:
                    p, cmd = m.group(1), m.group(2)
                    if cmd == "m":
                        self.sgr(p)
                    elif cmd == "H":
                        self.r = self.c = 0
                    elif cmd == "J" and p in ("2", "3"):
                        self.limpa()
                    elif cmd == "K":
                        for k in range(self.c, COLS):
                            self.linhas[self.r][k] = (" ", 7, False)
                    i = m.end()
                    continue
                mo = re.compile(r"\x1b\][^\x07\x1b]*(\x07|\x1b\\)").match(s, i)
                if mo:
                    i = mo.end()
                    continue
                m2 = re.compile(r"\x1b[()=>][A-Za-z0-9]?").match(s, i)
                if m2:
                    i = m2.end()
                    continue
                if len(s) - i < 12:
                    self.pend = s[i:]
                    return
                i += 1
                continue
            if ch == "\r":
                self.c = 0
            elif ch == "\n":
                self.c = 0
                self.lf()
            elif ch == "\t":
                self.c = min(COLS - 1, (self.c // 8 + 1) * 8)
            elif ch == "\b":
                self.c = max(0, self.c - 1)
            elif ch >= " ":
                self.poe(ch)
            i += 1

    def imagem(self):
        img = Image.new("RGB", (W, H), BG)
        d = ImageDraw.Draw(img)
        for ri, linha in enumerate(self.linhas):
            y = MARGIN_Y + ri * LH
            ci = 0
            while ci < COLS:
                ch, fg, b = linha[ci]
                cj = ci
                while cj < COLS and linha[cj][1] == fg and linha[cj][2] == b:
                    cj += 1
                trecho = "".join(x[0] for x in linha[ci:cj])
                if trecho.strip():
                    cor = PALETA.get(fg, FG)
                    d.text((X0 + ci * CW, y), trecho, font=FONTE_B if b else FONTE, fill=cor)
                ci = cj
        return img


def le_eventos(timing, log):
    dados = open(log, "rb").read()
    dados = dados[dados.index(b"\n") + 1:]
    dec = codecs.getincrementaldecoder("utf-8")("replace")
    pos, eventos = 0, []
    for linha in open(timing):
        a, b = linha.split()
        n = int(b)
        pedaco = dados[pos:pos + n]
        if len(pedaco) < n:
            break
        pos += n
        eventos.append((float(a), dec.decode(pedaco)))
    return eventos


def tela_ui(caminho, legenda):
    img = Image.open(caminho).convert("RGB").resize((W, H))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W, 64], fill=(18, 18, 24))
    d.text((24, 12), legenda, font=FONTE_T, fill=(250, 230, 80))
    return img


def main():
    timing, log, pasta, video = sys.argv[1:5]
    ui_dir = sys.argv[5] if len(sys.argv) > 5 else None
    os.makedirs(pasta, exist_ok=True)
    for f in os.listdir(pasta):
        os.remove(os.path.join(pasta, f))

    eventos = []
    for atraso, texto in le_eventos(timing, log):
        if MARCADOR in texto:
            antes, depois = texto.split(MARCADOR, 1)
            if antes:
                eventos.append((atraso, antes))
            eventos.append((0.0, "\x00UI"))
            eventos.append((0.0, depois.lstrip("\r\n")))
        else:
            eventos.append((atraso, texto))

    uis = []
    if ui_dir and os.path.isdir(ui_dir):
        legs = open(os.path.join(ui_dir, "captions.txt"), encoding="utf-8").read().splitlines()
        arqs = sorted(f for f in os.listdir(ui_dir) if f.endswith(".png"))
        uis = [(os.path.join(ui_dir, a), legs[i] if i < len(legs) else "") for i, a in enumerate(arqs)]

    tela = Tela()
    quadros = []  # (imagem, duracao)
    t_cena = 0.0

    def emite(img, dur):
        quadros.append([img, dur])

    ef = [(a * LENTO if a < 3.0 else MAXGAP_ESPERA) for a, _ in eventos]
    for i, (atraso, texto) in enumerate(eventos):
        if quadros:
            quadros[-1][1] += ef[i]
        if texto == "\x00UI":
            for caminho, legenda in uis:
                emite(tela_ui(caminho, legenda), UI_SEG)
            continue
        tela.escreve(texto)
        prox = ef[i + 1] if i + 1 < len(eventos) else 9
        if prox < 0.08 and i + 1 < len(eventos) and eventos[i + 1][1] != "\x00UI":
            if not quadros:
                emite(tela.imagem(), 0.0)
            continue
        emite(tela.imagem(), 0.0)
    quadros[-1][1] += 5.0

    lista = os.path.join(pasta, "lista.ffconcat")
    with open(lista, "w") as lf:
        lf.write("ffconcat version 1.0\n")
        ult = None
        for n, (img, dur) in enumerate(quadros):
            nome = f"f{n:05d}.png"
            img.save(os.path.join(pasta, nome), optimize=False, compress_level=1)
            lf.write(f"file {nome}\nduration {max(dur, 0.04):.3f}\n")
            ult = nome
        lf.write(f"file {ult}\n")
    total = sum(max(d, 0.04) for _, d in quadros)
    print(f"{len(quadros)} quadros, {total:.1f} s")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", lista,
                    "-vf", f"fps={FPS},format=yuv420p", "-c:v", "libx264", "-preset", "medium",
                    "-crf", "24", "-movflags", "+faststart", video], check=True)
    print("vídeo:", video, os.path.getsize(video) // 1024, "KB")


if __name__ == "__main__":
    main()
