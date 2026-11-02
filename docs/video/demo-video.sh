#!/bin/bash
# Demonstração real da Fase 3 para captura em vídeo (sem pausas, sem áudio).
# Exige GH_TOKEN no ambiente (passado na chamada, não gravado em arquivo).
export AWS_PROFILE=fase3 AWS_PAGER="" GIT_PAGER=cat PAGER=cat
export GIT_AUTHOR_NAME="Karlos Rodrigues" GIT_AUTHOR_EMAIL="323592744+karlos-rodrigues@users.noreply.github.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

REPO=karlos-rodrigues/flag-service
SERV=~/fiap-tc-fase2/services/flag-service
GITOPS=~/togglemaster-gitops
TF=~/fiap-tc-fase3/terraform/envs/prod
BRANCH=demo-video-fase3

hr() { printf '\n\033[1;32m═════════════════════════════════════════════════════\033[0m\n'; }
title() { hr; printf '\033[1;33m# %s\033[0m\n' "$1"; hr; sleep 1; }
fala() { printf '\033[0;35m>> %s\033[0m\n' "$1"; sleep 1; }
# exibe "texto mostrado" comando args...   (mostra o texto, executa o comando real)
exibe() { local t="$1"; shift; printf '\033[1;36m$ %s\033[0m\n' "$t"; sleep 0.4; "$@"; echo; sleep 1.2; }
run() { printf '\033[1;36m$ %s\033[0m\n' "$*"; sleep 0.4; eval "$@"; echo; sleep 1.2; }

jobs_do_run() { gh api repos/$REPO/actions/runs/$1/jobs --jq '.jobs[] | "   " + (.conclusion // .status) + "  " + .name'; }

espera_run() { # espera o run do commit $1 terminar
  local sha=$1 id st con
  for i in $(seq 1 80); do
    read -r id st con < <(gh run list --repo $REPO --commit "$sha" --limit 1 --json databaseId,status,conclusion --jq '.[0] | "\(.databaseId) \(.status) \(.conclusion)"' 2>/dev/null)
    printf '  [%s] commit %s: run %s %s %s\n' "$(date +%H:%M:%S)" "${sha:0:7}" "${id:-aguardando}" "${st:--}" "${con:-}"
    [ "$st" = completed ] && break
    sleep 12
  done
  RUN_ID=$id; RUN_CON=$con
}

cves_da_falha() {
  gh run view --repo $REPO "$1" --log-failed 2>/dev/null | sed -E 's/^[^\t]*\t[^\t]*\t[0-9T:.Z-]+ //; s/\x1b\[[0-9;]*m//g' \
    | grep -E 'Total:|CVE-' | cut -c1-135 | head -10
}

vpc_info() {
  local v; v=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=togglemaster-vpc --query 'Vpcs[0].VpcId' --output text)
  aws ec2 describe-vpcs --vpc-ids "$v" --query 'Vpcs[].[VpcId,CidrBlock]' --output text
  aws ec2 describe-subnets --filters Name=vpc-id,Values="$v" --query "Subnets[].{Nome:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,AZ:AvailabilityZone}" --output table
  aws ec2 describe-nat-gateways --filter Name=vpc-id,Values="$v" Name=state,Values=available --query 'NatGateways[].[NatGatewayId,State]' --output text
}

pr_criar() {
  cd $SERV && git checkout -q main && git pull -q && git checkout -q -b $BRANCH
  printf '\nDjango==3.0\n' >> requirements.txt
  tail -3 requirements.txt
  git commit -qam 'demo: adiciona dependencia vulneravel (Django 3.0)'
  git push -q -u origin $BRANCH 2>&1 | grep -v '^remote:\s*$' | head -3
  VULN_SHA=$(git rev-parse HEAD)
  PR_URL=$(gh pr create --repo $REPO --head $BRANCH --base main --title 'demo: dependencia vulneravel (Django 3.0)' --body 'Demonstracao do bloqueio de seguranca no CI (Fase 3).')
  echo "$PR_URL"; PR_NUM=${PR_URL##*/}
}

pr_corrigir() {
  cd $SERV && git revert --no-edit HEAD >/dev/null && git push -q 2>&1 | head -2
  FIX_SHA=$(git rev-parse HEAD); git log --oneline | head -3
}

pr_merge() {
  gh pr merge "$PR_NUM" --repo $REPO --merge --delete-branch 2>&1 | head -3
  cd $SERV && git checkout -q main && git pull -q
  MAIN_SHA=$(git rev-parse HEAD); NOVA_TAG="v1.0.0-${MAIN_SHA:0:7}"; echo "commit da main: ${MAIN_SHA:0:7}  ->  tag esperada: $NOVA_TAG"
}

espera_argocd() {
  for i in $(seq 1 40); do
    img=$(kubectl -n flags get deploy flag-service -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
    printf '  [%s] imagem no cluster: %s\n' "$(date +%H:%M:%S)" "${img##*/}"
    case "$img" in *"$NOVA_TAG") break;; esac
    sleep 10
  done
  kubectl -n flags rollout status deploy/flag-service --timeout=240s
}

clear
title "TECH CHALLENGE FASE 3 — TOGGLEMASTER — IaC, DEVSECOPS E GITOPS"
fala "Deploy manual, credencial em texto, vulnerabilidade em produção e ambiente no console: quatro dores, quatro automações."
sleep 2

title "1/6 — Infraestrutura como Código (Terraform)"
run "cd ~/fiap-tc-fase3/terraform && find . -maxdepth 2 -type d -not -path '*/.terraform*' | sort"
run "cd $TF && cat backend.tf"
run "aws s3api get-bucket-versioning --bucket togglemaster-tfstate-217579643777"
fala "O estado está no S3, com versionamento, criptografia e lockfile."
run "cd $TF && terraform plan -no-color | grep -E 'No changes|Plan:'"
run "cd $TF && terraform state list | grep -vE '(^|\\.)data\\.' | wc -l"
run "sed 's/\\x1b\\[[0-9;]*m//g' ~/apply-prod.log | grep -E 'Plan:|Apply complete'; cat ~/apply-inicio.txt ~/apply-fim.txt"
fala "O apply real criou 71 recursos em 12 minutos."
exibe "aws ec2 describe-vpcs / describe-subnets / describe-nat-gateways" vpc_info
run "aws eks describe-cluster --name togglemaster --query 'cluster.{status:status,versao:version}'"
run "aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,Engine,EngineVersion]' --output table"
run "aws elasticache describe-cache-clusters --query 'CacheClusters[].[CacheClusterId,CacheNodeType,Engine,CacheClusterStatus]' --output text"
run "aws dynamodb describe-table --table-name ToggleMasterAnalytics --query 'Table.TableStatus'"
run "aws sqs list-queues --query 'QueueUrls' --output text; aws ecr describe-repositories --query 'repositories[].repositoryName' --output text"
run "cd ~/fiap-tc-fase3 && trivy config --quiet --severity HIGH,CRITICAL terraform | head -12"

title "2/6 — Pipeline DevSecOps"
run "grep -nE '^  [a-z-]+:\$|^    name:' $SERV/.github/workflows/ci.yml"
fala "Cinco jobs: build e testes, linter, segurança (SCA e SAST), imagem (scan e push) e atualização do GitOps."
fala "Falha proposital: uma dependência vulnerável (Django 3.0) num Pull Request."
exibe "git checkout -b $BRANCH; echo Django==3.0 >> requirements.txt; git push; gh pr create" pr_criar
fala "O CI roda no Pull Request. Esperando o resultado..."
espera_run "$VULN_SHA"
exibe "gh api .../actions/runs/$RUN_ID/jobs   # resultado: $RUN_CON" jobs_do_run "$RUN_ID"
exibe "gh run view $RUN_ID --log-failed | grep CVE   # Trivy, severidade CRITICAL" cves_da_falha "$RUN_ID"
fala "O job de segurança falhou, a imagem não foi gerada e nada foi publicado."
fala "Agora a correção: reverter o commit vulnerável."
exibe "git revert HEAD; git push" pr_corrigir
espera_run "$FIX_SHA"
exibe "gh api .../actions/runs/$RUN_ID/jobs   # resultado: $RUN_CON" jobs_do_run "$RUN_ID"
fala "Tudo verde. Fazendo o merge do Pull Request na main."
exibe "gh pr merge $PR_NUM --merge" pr_merge
espera_run "$MAIN_SHA"
exibe "gh api .../actions/runs/$RUN_ID/jobs   # resultado: $RUN_CON" jobs_do_run "$RUN_ID"
fala "Na main o pipeline também fez login no ECR por OIDC, publicou a imagem e atualizou o GitOps."
run "aws ecr describe-images --repository-name flag-service --query 'sort_by(imageDetails,&imagePushedAt)[].imageTags' --output text"

title "3/6 — GitOps: o CI atualiza a tag no repositório de manifestos"
run "cd $GITOPS && git pull -q && git log -3 --format='%h %an %s'"
run "cd $GITOPS && grep -n 'image:' apps/flag-service/deployment.yaml"
fala "O CI não executa kubectl: só altera a tag no Git, que é a fonte de verdade."

title "4/6 — ArgoCD detecta a mudança e sincroniza o cluster"
run "kubectl -n argocd get applications"
fala "O ArgoCD observa o repositório. Esperando ele aplicar a nova tag..."
exibe "kubectl -n flags get deploy flag-service -w   # até a imagem mudar" espera_argocd
run "kubectl -n argocd get application flag-service -o jsonpath='{.status.sync.status}  {.status.health.status}{\"\\n\"}'"
run "kubectl -n argocd get application flag-service -o jsonpath='{range .status.history[*]}{.id}  {.revision}  {.deployedAt}{\"\\n\"}{end}' | tail -3"
run "kubectl -n flags get pods"
printf '@@UI@@\n'
sleep 1

title "5/6 — Fluxo de ponta a ponta"
LB=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
KEY=$(kubectl -n evaluation get secret evaluation-secrets -o jsonpath='{.data.SERVICE_API_KEY}' | base64 -d)
FLAG="flag-video-$(date +%H%M)"
run "curl -s -X POST http://$LB/flags -H \"Authorization: Bearer \$KEY\" -H 'Content-Type: application/json' -d '{\"name\":\"$FLAG\",\"description\":\"demo\",\"is_enabled\":true}'"
run "curl -s -X POST http://$LB/targeting/rules -H \"Authorization: Bearer \$KEY\" -H 'Content-Type: application/json' -d '{\"flag_name\":\"$FLAG\",\"rules\":{\"type\":\"PERCENTAGE\",\"value\":50}}'"
for u in user-1 user-2 user-3 user-4; do run "curl -s 'http://$LB/evaluate?user_id=$u&flag_name=$FLAG'"; done
sleep 20
run "aws dynamodb scan --table-name ToggleMasterAnalytics --select COUNT --query Count"
run "kubectl get externalsecret -A"
fala "As credenciais vêm do Secrets Manager; não há valor sensível no Git."

title "6/6 — Custos e encerramento"
fala "Estimativa: US\$ 0,3392 por hora, cerca de US\$ 260,72 por mês (Tabela 5 do relatório)."
fala "O ambiente é destruído logo após a gravação."
sleep 3
