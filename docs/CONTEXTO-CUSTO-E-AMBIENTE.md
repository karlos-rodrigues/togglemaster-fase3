# Contexto para o relatório — onde o Terraform roda e o que custa

Texto-base da seção 3 (primeira pessoa). Valores conferidos nas páginas oficiais da AWS em 02/11/2026.

Desenvolvi todo o código Terraform dentro da VM forge, isolada da minha estação. O processo é o mesmo em qualquer destino: escrevo os módulos, rodo terraform init, fmt, validate, plan e apply. O que muda é só o provider e o backend, não o código.

Eu poderia criar toda a infraestrutura na AWS desde o início, mas ela é cara para ficar ligada: o plano de controle do EKS custa US$ 0,10 por hora por cluster (cerca de US$ 73 por mês), o NAT Gateway US$ 0,045 por hora mais US$ 0,045 por GB processado, cada IPv4 público US$ 0,005 por hora, fora as três instâncias RDS, o ElastiCache e o Load Balancer. Por isso mantenho o ambiente desligado e só o subo para validar e gravar.

O que é igual e o que não é:

| Etapa | Na forge, sem criar recursos | Na AWS |
|---|---|---|
| init, fmt, validate | idêntico | idêntico |
| plan | só com credencial; não cria nada e não gera custo | mostra o que seria criado de verdade, com as regras reais da conta |
| apply de rede (VPC, sub-redes, IGW, route tables) | sem custo na AWS (esses recursos não são cobrados); NAT desligado com nat_gateway=false | idêntico |
| apply de EKS, RDS, ElastiCache | não há como reproduzir localmente: o emulador LocalStack só cobre EKS, RDS, ElastiCache e ECR em planos pagos | cobrado por hora; subo, gravo o vídeo e destruo |

Conclusão que adoto: o fluxo e o código são os mesmos; o que um emulador não substitui é a prova de que a infraestrutura real sobe (IAM, cotas, tempo de criação do EKS e do RDS). Por isso a evidência do vídeo vem de um apply real, de curta duração, seguido de destroy, e o relatório traz o print da estimativa de custos.

Fontes: aws.amazon.com/vpc/pricing, aws.amazon.com/eks/pricing, docs.localstack.cloud/aws/licensing.
