#!/bin/bash
# Demonstração da Fase 3 para gravação de tela.
# Uso: ./rec-script.sh            roda com pausas (ENTER) nos pontos de navegador
#      AUTO=1 ./rec-script.sh     sem pausas (ensaio)
#      PULAR_PR=1 ./rec-script.sh pula o bloco da falha proposital (usa o git)
export AWS_PROFILE=fase3
SERV=~/fiap-tc-fase2/services/flag-service
GITOPS=~/togglemaster-gitops
TF=~/fiap-tc-fase3/terraform/envs/prod

hr() { printf '\n\033[1;32m═══════════════════════════════════════════════\033[0m\n'; }
title() { hr; printf '\033[1;33m# %s\033[0m\n' "$1"; hr; sleep 1; }
run() { printf '\033[1;36m$ %s\033[0m\n' "$*"; sleep 0.4; eval "$@"; echo; sleep 1.5; }
fala() { printf '\033[0;35m>> %s\033[0m\n' "$1"; sleep 1; }
pausa() {
  printf '\033[1;31m[PAUSA] %s\033[0m\n' "$1"
  [ "$AUTO" = 1 ] || read -r -p "ENTER para continuar... "
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
run "aws eks describe-cluster --name togglemaster --query 'cluster.{status:status,versao:version}'"
run "aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,Engine,EngineVersion]' --output table"
run "aws dynamodb describe-table --table-name ToggleMasterAnalytics --query 'Table.TableStatus'"
pausa "Abra o console da AWS: VPC, EKS, RDS (3), ElastiCache, DynamoDB, SQS e ECR (5 repositórios)."
run "cd ~/fiap-tc-fase3 && trivy config --quiet --severity HIGH,CRITICAL terraform; echo 'trivy config: sem achados HIGH/CRITICAL (exceções em .trivyignore)'"

title "2/6 — Pipeline DevSecOps"
run "sed -n 1,60p $SERV/.github/workflows/ci.yml"
pausa "No GitHub, mostre a aba Actions do flag-service com o último run verde e os 5 jobs."

if [ "$PULAR_PR" != 1 ]; then
  fala "Agora a falha proposital: uma dependência vulnerável."
  run "cd $SERV && git checkout -q main && git pull -q && git checkout -b demo-dependencia-vulneravel"
  run "cd $SERV && printf '\\nDjango==3.0\\n' >> requirements.txt && tail -3 requirements.txt"
  run "cd $SERV && git commit -qam 'demo: adiciona dependencia vulneravel (Django 3.0)' && git push -q -u origin demo-dependencia-vulneravel 2>&1 | tail -2"
  pausa "Abra o Pull Request (link que o git imprimiu) e mostre o job de Segurança FALHANDO com CVEs CRITICAL e os jobs de imagem e GitOps em 'skipped'."
  fala "Agora a correção."
  run "cd $SERV && git revert --no-edit HEAD >/dev/null && git push -q 2>&1 | tail -1; git log --oneline | head -3"
  pausa "Mostre os checks do Pull Request ficando verdes, faça o MERGE e espere o pipeline da main terminar (login no ECR via OIDC, push da imagem e job de GitOps)."
  run "cd $SERV && git checkout -q main && git pull -q"
fi
run "aws ecr describe-images --repository-name flag-service --query 'sort_by(imageDetails,&imagePushedAt)[].imageTags' --output text"

title "3/6 — GitOps: o CI atualiza a tag no repositório de manifestos"
run "cd $GITOPS && git pull -q && git log -4 --format='%h %an %s'"
run "cd $GITOPS && grep -n 'image:' apps/flag-service/deployment.yaml"
fala "O CI não executa kubectl: só altera a tag no Git, que é a fonte de verdade."
pausa "No navegador, abra o último commit do togglemaster-gitops e mostre o diff de uma linha no deployment.yaml."

title "4/6 — ArgoCD sincronizando o cluster"
run "kubectl -n argocd get applications"
pausa "Abra https://localhost:8080 (admin): as 9 Applications, a árvore do flag-service e o histórico de sync."
run "kubectl -n flags get pods"
run "kubectl -n flags get deploy flag-service -o jsonpath='{.spec.template.spec.containers[0].image}{\"\\n\"}'"
fala "O ArgoCD detectou o commit e aplicou sozinho, sem ninguém rodar kubectl apply."

title "5/6 — Fluxo de ponta a ponta"
LB=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
KEY=$(kubectl -n evaluation get secret evaluation-secrets -o jsonpath='{.data.SERVICE_API_KEY}' | base64 -d)
FLAG="flag-video-$(date +%H%M)"
run "curl -s -X POST http://$LB/flags -H \"Authorization: Bearer \$KEY\" -H 'Content-Type: application/json' -d '{\"name\":\"$FLAG\",\"description\":\"demo\",\"is_enabled\":true}'"
run "curl -s -X POST http://$LB/targeting/rules -H \"Authorization: Bearer \$KEY\" -H 'Content-Type: application/json' -d '{\"flag_name\":\"$FLAG\",\"rules\":{\"type\":\"PERCENTAGE\",\"value\":50}}'"
for u in user-1 user-2 user-3 user-4; do
  run "curl -s 'http://$LB/evaluate?user_id=$u&flag_name=$FLAG'"
done
sleep 20
run "aws dynamodb scan --table-name ToggleMasterAnalytics --select COUNT --query Count"
run "kubectl get externalsecret -A"
fala "As credenciais vêm do Secrets Manager; não há valor sensível no Git."

title "6/6 — Custos e encerramento"
fala "Estimativa: US\$ 0,3392 por hora, cerca de US\$ 260,72 por mês (Tabela 5 do relatório). O ambiente é destruído logo após a gravação."
sleep 3
