# Roteiro de gravação — vídeo de demonstração da Fase 3 (até 20 min, alvo 18 min)

Comandos prontos para copiar e colar, na ordem do enunciado. Terminal na VM `forge`
(`ssh -p 2222 udefault@127.0.0.1`). Nenhuma senha está neste arquivo: o repositório é público.

| Bloco | Tempo | Mostra |
|---|---|---|
| 0. Abertura | 1:00 | contexto, arquitetura (Figura 1 do relatório) |
| 1. IaC | 3:30 | Terraform, estado remoto, plan, resultado na AWS |
| 2. Pipeline DevSecOps | 6:00 | pipeline falhando no passo de segurança e depois passando |
| 3. GitOps | 2:30 | CI atualizando a tag no repositório de manifestos |
| 4. ArgoCD | 3:00 | interface detectando e sincronizando |
| 5. Ponta a ponta | 1:30 | fluxo funcionando no cluster |
| 6. Custos e encerramento | 0:30 | estimativa e destroy |

## Antes de gravar (checklist)

1. Ambiente no ar: `kubectl get nodes` mostra 2 nós `Ready` e `kubectl -n argocd get applications` mostra tudo `Synced` e `Healthy`.
2. Acesso à interface do ArgoCD (abrir uma vez, deixar rodando). Na **estação local**:
   ```bash
   ssh -L 8080:127.0.0.1:8080 -p 2222 udefault@127.0.0.1 \
     'AWS_PROFILE=fase3 kubectl -n argocd port-forward svc/argocd-server 8080:443 --address 127.0.0.1'
   ```
   Abrir `https://localhost:8080` (aceitar o aviso de certificado, que é autoassinado). Usuário `admin`; a senha vem de:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
   ```
3. Abas do navegador prontas: repositório `togglemaster-fase3`, repositório `togglemaster-gitops`, aba Actions do `flag-service`, ArgoCD, e o console da AWS (VPC, EKS, RDS, ElastiCache, DynamoDB, SQS, ECR) em `us-east-1`.
4. No terminal da forge: `export AWS_PROFILE=fase3`, fonte grande e `clear`.
5. Ensaiar o bloco 2 uma vez sem gravar: o pipeline leva de 3 a 5 minutos, e na edição esse tempo pode ser acelerado.

## 0. Abertura (1:00)

Mostrar a Figura 1 do relatório. Fala sugerida: "As quatro dores do enunciado eram deploy manual, credencial em texto, vulnerabilidade em produção e ambiente criado no console. Resolvi cada uma: Terraform, pipeline com varreduras de segurança, GitOps com ArgoCD e segredos no Secrets Manager."

## 1. Infraestrutura como Código (3:30)

```bash
cd ~/fiap-tc-fase3/terraform
find . -maxdepth 2 -type d -not -path '*/.terraform*' | sort
```
Mostrar a divisão em módulos (`rede`, `eks`, `rds`, `elasticache`, `dynamodb`, `sqs`, `ecr`, `irsa`, `github_oidc`, `segredos`, `eso`).

```bash
cd envs/prod
cat backend.tf
aws s3api get-bucket-versioning --bucket togglemaster-tfstate-217579643777
```
Explicar: o estado está no S3, com versionamento, criptografia e `use_lockfile`.

```bash
terraform plan
```
Resultado esperado: `No changes. Your infrastructure matches the configuration.` Fala: "o código descreve exatamente o que existe na AWS".

```bash
terraform state list | grep -vE '(^|\.)data\.' | wc -l
sed 's/\x1b\[[0-9;]*m//g' ~/apply-prod.log | grep -E 'Plan:|Apply complete'
cat ~/apply-inicio.txt ~/apply-fim.txt
```
Mostrar os 71 recursos e o apply real: 71 criados em 12 minutos.

Mostrar o resultado na AWS (console ou CLI):
```bash
aws eks describe-cluster --name togglemaster --query 'cluster.{status:status,versao:version}'
aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,Engine,EngineVersion]' --output table
aws dynamodb describe-table --table-name ToggleMasterAnalytics --query 'Table.TableStatus'
```
No console, abrir VPC (sub-redes públicas e privadas), EKS, RDS (3 instâncias), ElastiCache, DynamoDB, SQS e ECR (5 repositórios).

Opcional, 20 segundos: a varredura de segurança do próprio Terraform.
```bash
cd ~/fiap-tc-fase3 && trivy config --severity HIGH,CRITICAL terraform
```
Resultado: sem achados; as três exceções estão justificadas no `.trivyignore`.

> Não recomendo rodar `destroy` e `apply` ao vivo: o apply leva 12 minutos. Se quiser mostrá-lo, grave e acelere na edição; o custo é de cerca de US$ 0,34 por hora.

## 2. Pipeline DevSecOps (6:00)

Mostrar o workflow e as execuções verdes:
```bash
cd ~/fiap-tc-fase2/services/flag-service
sed -n 1,70p .github/workflows/ci.yml
```
No GitHub, aba Actions do `flag-service`: o último run verde, com os cinco jobs (build e testes, linter, segurança, docker build e scan, atualização do GitOps).

### 2.1 Falha proposital: dependência vulnerável

```bash
cd ~/fiap-tc-fase2/services/flag-service
git checkout main && git pull
git checkout -b demo-dependencia-vulneravel
printf '\nDjango==3.0\n' >> requirements.txt
tail -3 requirements.txt
git commit -am "demo: adiciona dependencia vulneravel (Django 3.0)"
git push -u origin demo-dependencia-vulneravel
```
> Use `printf` com `\n` no início: o `requirements.txt` não termina com quebra de linha, e um `echo >>` colaria `requests==2.28.1Django==3.0` na mesma linha.

Abrir o Pull Request pelo link que o git imprime (`https://github.com/karlos-rodrigues/flag-service/pull/new/demo-dependencia-vulneravel`).
Mostrar os checks: o job **Segurança (SCA e SAST)** falha com o Trivy listando CVEs **CRITICAL** do Django 3.0 (validei na forge: CVE-2019-19844, CVE-2020-7471, CVE-2021-35042 e mais um), e os jobs **Docker build, scan e push** e **Atualiza a tag no GitOps** ficam em *skipped*. Fala: "o pipeline barrou antes de gerar imagem; a vulnerabilidade não chega ao cluster".

> Alternativa de falha pelo SAST, se preferir código em vez de dependência: acrescentar em `app.py` uma linha com `hashlib.md5(b"x")`. O bandit marca como severidade alta. A dependência vulnerável é a opção mais clara para o vídeo.

### 2.2 Correção

```bash
git revert --no-edit HEAD
git push
```
Voltar ao Pull Request: os checks reexecutam e todos passam. Mostrar o job de segurança verde.

### 2.3 Merge

No Pull Request, fazer o *Merge*. O pipeline da `main` roda inteiro: build, linter, segurança, scan da imagem, **login no ECR via OIDC e push com a tag do commit** e, por fim, o job de GitOps. Mostrar a tag no ECR:
```bash
aws ecr describe-images --repository-name flag-service \
  --query 'sort_by(imageDetails,&imagePushedAt)[].imageTags' --output text
```

Citar também, em 15 segundos, o caso real da Seção 8.2 do relatório: o scan de imagem barrou o CVE-2025-68121 na stdlib do Go dos serviços `auth` e `evaluation`.

## 3. GitOps (2:30)

Mostrar que o job `gitops` do pipeline gravou o commit no repositório de manifestos:
```bash
cd ~/togglemaster-gitops && git pull -q
git log -3 --format='%h %an %s'
grep -n 'image:' apps/flag-service/deployment.yaml
```
No navegador, abrir `togglemaster-gitops`, o último commit "flag-service: imagem v1.0.0-<hash>" e o diff de uma linha no `deployment.yaml`. Fala: "o CI não executa `kubectl`; ele só altera a tag no Git, que é a fonte de verdade".

## 4. ArgoCD (3:00)

Na interface (`https://localhost:8080`):
1. Tela de Applications: as 9 Applications `Synced` e `Healthy`, entre elas os 5 serviços.
2. Abrir `flag-service`: árvore de recursos (Deployment, ReplicaSet, Pods, ExternalSecret, Service, ConfigMap).
3. Mostrar *History and Rollback*: a revisão nova, criada pelo commit de tag, aplicada automaticamente.
4. Se o rollout já tiver terminado, mostrar o campo *Last Sync*; se quiser ver o sync acontecendo, force o refresh na interface (*Refresh*).

No terminal, em paralelo:
```bash
kubectl -n flags get pods -w
kubectl -n flags get deploy flag-service -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```
Fala: "o ArgoCD detectou o commit, comparou com o cluster e aplicou sozinho, sem ninguém rodar `kubectl apply`".

## 5. Fluxo de ponta a ponta (1:30)

```bash
LB=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
KEY=$(kubectl -n evaluation get secret evaluation-secrets -o jsonpath='{.data.SERVICE_API_KEY}' | base64 -d)
curl -s -X POST http://$LB/flags -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
  -d '{"name":"flag-demo-video","description":"demo","is_enabled":true}'
curl -s -X POST http://$LB/targeting/rules -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
  -d '{"flag_name":"flag-demo-video","rules":{"type":"PERCENTAGE","value":50}}'
for u in user-1 user-2 user-3 user-4; do curl -s "http://$LB/evaluate?user_id=$u&flag_name=flag-demo-video"; echo; done
aws dynamodb scan --table-name ToggleMasterAnalytics --select COUNT --query Count
```
Mostrar os resultados `true` e `false` e o contador do DynamoDB crescendo. Mostrar também `kubectl get externalsecret -A` (`SecretSynced`): as credenciais vêm do Secrets Manager, sem valor no Git.

## 6. Custos e encerramento (0:30)

Mostrar a Tabela 5 e a Figura 2 do relatório (US$ 0,3392 por hora, cerca de US$ 260,72 por mês) e avisar que o ambiente será destruído logo após a gravação.

---

## Depois de gravar: encerrar o ambiente

A ordem importa. O Classic Load Balancer do Ingress é criado pelo Kubernetes e não está no state do Terraform; se ele continuar de pé, a destruição da VPC falha.

```bash
export AWS_PROFILE=fase3
cd ~/fiap-tc-fase3/terraform/envs/gitops && terraform destroy
kubectl delete namespace ingress-nginx
aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text
cd ../prod && terraform destroy
```
O segundo comando só deve ser executado depois que o `terraform destroy` do `gitops` terminar; sem o ArgoCD, nada recria o Ingress. Antes do `destroy` do `prod`, confirmar que o `describe-load-balancers` não lista mais nenhum balanceador.

Itens finais, fora do Terraform: desativar e apagar a chave de acesso do usuário `tc-fase3-cli` e o token do GitHub, remover o bucket de estado `togglemaster-tfstate-217579643777` (se não for mais necessário) e, se quiser, tornar o repositório `togglemaster-gitops` privado.
