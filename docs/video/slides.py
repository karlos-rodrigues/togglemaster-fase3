#!/usr/bin/env python3
"""Gera os slides do vídeo da Fase 3 (1920x1080, tema escuro como na Fase 2), sem áudio.

Uso: slides.py pasta_saida video.mp4 [figura_arquitetura.png]
Marcação nos textos: [b]negrito[/b]
"""
import os
import re
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
BG = (28, 28, 42)
CINZA = (190, 195, 215)
SUAVE = (130, 136, 165)
BRANCO = (255, 255, 255)
LARANJA = (255, 140, 30)
D = "/usr/share/fonts/truetype/dejavu/"
F_TIT = ImageFont.truetype(D + "DejaVuSans-Bold.ttf", 72)
F_SUB = ImageFont.truetype(D + "DejaVuSans.ttf", 34)
F_TXT = ImageFont.truetype(D + "DejaVuSans.ttf", 40)
F_TXTB = ImageFont.truetype(D + "DejaVuSans-Bold.ttf", 40)
F_MONO = ImageFont.truetype(D + "DejaVuSansMono.ttf", 34)
F_CAPA = ImageFont.truetype(D + "DejaVuSans-Bold.ttf", 110)
F_PEQ = ImageFont.truetype(D + "DejaVuSans.ttf", 30)


def barra(d):
    for x in range(W):
        t = x / W
        cor = (int(255 + (150 - 255) * t), int(140 + (90 - 140) * t), int(30 + (230 - 30) * t))
        d.line([(x, 0), (x, 10)], fill=cor)


def pedacos(linha):
    saida = []
    for m in re.finditer(r"\[b\](.*?)\[/b\]|([^\[]+)", linha):
        if m.group(1) is not None:
            saida.append((True, m.group(1)))
        elif m.group(2):
            saida.append((False, m.group(2)))
    return saida


def desenha_linha(d, x, y, linha, largura_max):
    cursor = x
    for neg, trecho in pedacos(linha):
        fonte = F_TXTB if neg else F_TXT
        cor = BRANCO if neg else CINZA
        for palavra in re.split(r"(\s+)", trecho):
            if not palavra:
                continue
            w = fonte.getlength(palavra)
            if cursor + w > x + largura_max and palavra.strip():
                cursor = x + 56
                y += 54
            d.text((cursor, y), palavra, font=fonte, fill=cor)
            cursor += w
    return y + 54


def titulo_ajustado(texto, maximo=W - 200):
    for tam in range(72, 39, -2):
        fonte = ImageFont.truetype(D + "DejaVuSans-Bold.ttf", tam)
        if fonte.getlength(texto) <= maximo:
            return fonte
    return fonte


def slide(secao, titulo, itens, rodape=None):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    barra(d)
    if secao:
        d.text((100, 78), secao, font=F_SUB, fill=SUAVE)
    d.text((100, 128), titulo, font=titulo_ajustado(titulo), fill=BRANCO)
    y = 290
    for item in itens:
        d.polygon([(100, y + 12), (100, y + 38), (122, y + 25)], fill=LARANJA)
        y = desenha_linha(d, 150, y, item, W - 300) + 22
    if rodape:
        d.text((100, H - 80), rodape, font=F_PEQ, fill=SUAVE)
    return img


def capa():
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    barra(d)
    d.text((W // 2, 330), "ToggleMaster", font=F_CAPA, fill=BRANCO, anchor="mm")
    d.text((W // 2, 450), "Tech Challenge Fase 3", font=F_SUB, fill=LARANJA, anchor="mm")
    d.text((W // 2, 530), "Infraestrutura como Código, DevSecOps e GitOps na AWS", font=F_TXT, fill=CINZA, anchor="mm")
    d.text((W // 2, 760), "Karlos Rodrigues — RM 374567", font=F_SUB, fill=BRANCO, anchor="mm")
    d.text((W // 2, 820), "FIAP — DevOps e Arquitetura Cloud", font=F_PEQ, fill=SUAVE, anchor="mm")
    return img


def arquitetura(figura):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    barra(d)
    d.text((100, 78), "2. Arquitetura", font=F_SUB, fill=SUAVE)
    d.text((100, 128), "Do commit ao Pod, tudo versionado", font=F_TIT, fill=BRANCO)
    fig = Image.open(figura).convert("RGB")
    alvo_h = 790
    fig = fig.resize((int(fig.width * alvo_h / fig.height), alvo_h))
    if fig.width > W - 120:
        fig = fig.resize((W - 120, int(fig.height * (W - 120) / fig.width)))
    img.paste(fig, ((W - fig.width) // 2, 245))
    return img


def custos():
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    barra(d)
    d.text((100, 78), "6. Custos", font=F_SUB, fill=SUAVE)
    d.text((100, 128), "US$ 0,3392 por hora — cerca de US$ 260,72 por mês", font=ImageFont.truetype(D + "DejaVuSans-Bold.ttf", 58), fill=BRANCO)
    itens = [("EKS plano de controle", 0.1000), ("2 nós t3.medium", 0.0832), ("3 RDS db.t3.micro", 0.0540),
             ("NAT Gateway", 0.0450), ("Classic Load Balancer", 0.0250), ("ElastiCache Redis", 0.0170), ("3 IPv4 públicos", 0.0150)]
    y = 290
    for nome, v in itens:
        d.text((100, y), nome, font=F_TXT, fill=CINZA)
        d.rounded_rectangle([620, y + 4, 620 + int(v / 0.1 * 900), y + 44], radius=6, fill=LARANJA)
        d.text((620 + int(v / 0.1 * 900) + 18, y), f"{v:.4f}".replace(".", ","), font=F_MONO, fill=BRANCO)
        y += 76
    d.text((100, 860), "Preços da API oficial da AWS (us-east-1). Ambiente ligado só para validar e gravar; destruído em seguida.",
           font=F_PEQ, fill=SUAVE)
    d.text((100, 905), "Não inclui tráfego de dados (NAT cobra por GB), CloudWatch Logs nem armazenamento do ECR.", font=F_PEQ, fill=SUAVE)
    return img


def monta(fig):
    s = []
    s.append(("capa", capa(), 8))
    s.append(("dores", slide("1. O desafio", "Quatro dores, quatro automações", [
        "kubectl apply das máquinas locais  →  [b]GitOps[/b]: o ArgoCD sincroniza a partir do Git",
        "Credenciais do banco em arquivo de texto  →  [b]AWS Secrets Manager[/b] e External Secrets",
        "Vulnerabilidade Go que foi para produção  →  [b]CI DevSecOps[/b]: Trivy, gosec e bandit",
        "Homologação criada no console, em dias  →  [b]Terraform[/b]: 71 recursos em 12 minutos",
    ], "Se não está no código, não existe."), 11))
    s.append(("arq", arquitetura(fig), 11))
    s.append(("iac", slide("3. Infraestrutura como Código", "Terraform modular, com estado remoto", [
        "[b]11 módulos[/b]: rede, eks, rds, elasticache, dynamodb, sqs, ecr, irsa, github_oidc, segredos e eso",
        "Estado no [b]S3[/b], versionado, criptografado e com [b]use_lockfile[/b]",
        "EKS [b]1.36[/b] e PostgreSQL [b]17[/b]: o 1.31 da Fase 2 já estava em suporte estendido (US$ 0,60 por hora)",
        "[b]apply real[/b]: 71 recursos criados em 12 minutos na conta pessoal (Opção B)",
        "[b]trivy config[/b] no próprio Terraform: 8 tipos de achado corrigidos e 3 exceções justificadas",
    ], "Terraform 1.17 · provider AWS 6 · estado em S3"), 12))
    s.append(("ci", slide("4. Pipeline de CI", "Cinco jobs por serviço, em todo PR e push na main", [
        "[b]Build e testes[/b] → [b]Linter[/b] (golangci-lint, flake8) → [b]SCA[/b] (Trivy fs) e [b]SAST[/b] (gosec, bandit)",
        "[b]Docker build[/b] + scan da imagem com Trivy: vulnerabilidade [b]CRITICAL[/b] interrompe o fluxo",
        "Push ao ECR com a tag [b]v1.0.0-<hash do commit>[/b], só na main",
        "Login na AWS por [b]OIDC[/b]: nenhuma chave AWS guardada no GitHub",
        "Último job: o CI altera a tag da imagem no repositório GitOps",
    ], "5 repositórios de serviço · 2 em Go · 3 em Python"), 12))
    s.append(("cve", slide("4. Pipeline de CI", "Achado real: o Trivy barrou um CVE crítico", [
        "[b]CVE-2025-68121[/b] (CRITICAL) na biblioteca padrão do Go 1.21.13: validação incorreta de certificado no crypto/tls",
        "Corrigido ao subir o build para [b]golang:1.25-alpine[/b] (Go 1.25.14)",
        "Só o [b]scan da imagem[/b] viu: o scan de dependências do go.mod não enxerga a stdlib",
        "É a classe de falha que o enunciado conta que \"passou despercebida e foi para produção\"",
    ], None), 11))
    s.append(("gitops", slide("5. GitOps", "O Git é a única fonte de verdade", [
        "Repositório [b]togglemaster-gitops[/b] só com YAML: 5 serviços, base, ingress e Applications",
        "[b]ArgoCD[/b] no EKS (Helm pelo Terraform), app-of-apps, [b]auto-sync, prune e selfHeal[/b]",
        "CI grava a nova tag no Git; o ArgoCD detecta e aplica. [b]Ninguém roda kubectl apply[/b]",
        "Tabelas dos bancos criadas por [b]Jobs de migração[/b] (hook do ArgoCD), também versionados",
    ], "ArgoCD 3.5 · acesso ao repositório por deploy key SSH somente leitura"), 11))
    s.append(("seg", slide("6. Segredos", "Nenhuma senha em arquivo ou no Git", [
        "O [b]Terraform[/b] gera as senhas e grava um segredo por serviço no [b]AWS Secrets Manager[/b]",
        "O [b]External Secrets Operator[/b], com role IRSA de leitura mínima, cria os Secrets do Kubernetes",
        "O repositório GitOps traz só o [b]ExternalSecret[/b]: o nome do segredo, nunca o valor",
        "Bancos e Redis acessíveis apenas pelo Security Group do cluster",
    ], None), 10))
    s.append(("custos", custos(), 11))
    s.append(("desafios", slide("7. Desafios e limitações", "O que deu errado no caminho", [
        "O código recebido [b]reprovou no próprio pipeline[/b]: lint, SAST (SSRF) e estilo",
        "OIDC recusado: a conta do GitHub usa [b]subject imutável[/b] (IDs numéricos no token)",
        "As tabelas dos bancos não existiam: viraram [b]Jobs versionados[/b] no GitOps",
        "Limitações assumidas: sem testes unitários nos repositórios e [b]ingress-nginx descontinuado[/b] em março de 2026",
    ], "Detalhes na Seção 8 do relatório"), 11))
    s.append(("fim", slide("8. Entrega", "Repositórios e relatório", [
        "[b]togglemaster-fase3[/b]: Terraform, workflows-modelo, relatório e roteiro",
        "[b]togglemaster-gitops[/b]: manifestos e Applications do ArgoCD",
        "[b]auth, flag, targeting, evaluation e analytics-service[/b]: código e workflow de CI",
        "github.com/karlos-rodrigues/...  ·  Relatório de Entrega — Tech Challenge Fase 3",
    ], None), 9))
    return s


def main():
    pasta, video = sys.argv[1], sys.argv[2]
    fig = sys.argv[3] if len(sys.argv) > 3 else None
    os.makedirs(pasta, exist_ok=True)
    lista = os.path.join(pasta, "lista.ffconcat")
    with open(lista, "w") as lf:
        lf.write("ffconcat version 1.0\n")
        ult = None
        for i, (nome, img, dur) in enumerate(monta(fig)):
            arq = f"s{i:02d}-{nome}.png"
            img.save(os.path.join(pasta, arq))
            lf.write(f"file {arq}\nduration {dur}\n")
            ult = arq
        lf.write(f"file {ult}\n")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", lista,
                    "-vf", "fps=30,format=yuv420p", "-c:v", "libx264", "-preset", "medium", "-crf", "22",
                    "-movflags", "+faststart", video], check=True)
    print("vídeo:", video, os.path.getsize(video) // 1024, "KB")


if __name__ == "__main__":
    main()
