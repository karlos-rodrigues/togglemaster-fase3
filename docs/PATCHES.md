# Correções de lint e SAST aplicadas ao código dos serviços (Fase 3)

O pipeline bloqueia o merge se o lint ou o SAST falharem, então o código recebido da FIAP precisou de ajustes mínimos, sem mudar comportamento.

| Serviço | Ferramenta | Achado | Correção |
|---|---|---|---|
| auth-service | golangci-lint (errcheck) | retorno de Encode e de db.Close ignorado | atribuído a _ explicitamente |
| evaluation-service | golangci-lint (errcheck, staticcheck SA1019) | retornos ignorados em Encode, Set e Body.Close; uso de io/ioutil, obsoleto desde o Go 1.19 | _ explícito; io.ReadAll no lugar de ioutil.ReadAll |
| evaluation-service | gosec G704 (SSRF, HIGH) | requisição HTTP com URL variável | anotado com #nosec e justificativa: a URL vem de FLAG_SERVICE_URL e TARGETING_SERVICE_URL, definidas pelo operador no ConfigMap, nunca por entrada do usuário |
| flag, targeting, analytics | flake8 | 17 a 43 avisos de estilo (E261, E302, E305, E701, W291, W292, W293) e um import sem uso (F401) | autopep8 e autoflake |

SCA (Trivy fs, severidade CRITICAL) e bandit (severidade alta) não apontaram nada no código original.
