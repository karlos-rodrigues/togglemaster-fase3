# Passos pós-apply (uma única vez por ambiente)

1. terraform apply em terraform/envs/prod (rede, EKS, bancos, filas, ECR, OIDC, segredos).
2. terraform apply em terraform/envs/gitops (External Secrets, ArgoCD e a aplicação raiz que lê o repositório togglemaster-gitops).
3. O ArgoCD sincroniza sozinho. Os Jobs de migração (hook Sync, wave 1) criam as tabelas de auth, flag e targeting a partir do ConfigMap *-schema. O ExternalSecret roda na wave -1, antes dos Jobs.
4. Chave de serviço do evaluation-service: a chave só existe depois que o auth-service sobe e as tabelas existem. Gerar com POST /auth/admin/keys (MASTER_KEY vinda do Secrets Manager togglemaster/auth), gravar o valor em SERVICE_API_KEY no segredo togglemaster/evaluation com aws secretsmanager put-secret-value, forçar o sync do ExternalSecret e reiniciar o deployment evaluation-service. O Terraform ignora mudanças nesse segredo (ignore_changes), então a chave não é sobrescrita em um novo apply.
5. Validação: criar uma flag e uma regra de 50%, chamar /evaluate com vários user_id e conferir os itens na tabela ToggleMasterAnalytics.

Resultado de 02/11/2026: 8 avaliações (7 true, 1 false) e 8 itens no DynamoDB.
