# Decisões de produto e viabilidade

Síntese de propostas de **09–26/09/2026** e das decisões de execução posteriores. As condições de serviços e licenças citadas são registros da pesquisa original, sem nova verificação nesta limpeza. Contratação, publicação e uso de dados exigem conferir a condição aplicável naquele momento. [Visão completa R01–R18](visao-produto.md) · [histórico](../historico/README.md) · [estado vigente](../execucao/v1/handoff.md).

<a id="produto"></a>
## Produto e decisões

TrainForge é um guia pessoal de treino, movimento e alimentação para começar, aprender, organizar e acompanhar uma rotina. A pessoa deve poder seguir programas humanos com origem verificável ou compor seu próprio plano dentro de regras humanas revisadas. O catálogo pronto continua necessário para iniciantes; importar o plano do usuário não o substitui.

O planejamento de setembro separou problemas que não cabem numa única API: exercícios e instruções; programa com sequência/dose/progressão; composição de alimentos; receita; plano alimentar; captura e acompanhamento. Dor, diagnóstico e retorno após operação são contextos de pesquisa, não definição de todo o produto nem autorização de tratamento automático.

| Decisão ou restrição | Consequência de produto |
|---|---|
| Conteúdo humano existente, autoria e direitos rastreáveis | Não gerar prescrição por IA nem completar dose, instrução ou progressão ausentes. |
| Academia, casa, praça/parque e diferentes modalidades | Compatibilidade depende de equipamento, tempo, preparo, população e apoio; não basta o nome do local. |
| Cuidador pratica para si durante suas pausas | Atividade do paciente e acompanhamento de terceiros são responsabilidades distintas. |
| Configuração completa em etapas curtas, com revisão | Seleção/adesão exige contexto e conteúdo aprovado; nenhuma configuração cria programa inexistente. |
| Foto gera candidatos editáveis; pessoa informa quantidade e confirma | Identificação visual não mede gramas nem autoriza lançamento automático. |
| Refeição e alimento são visões dos mesmos registros | Editar/excluir precisa preservar identidade e refletir no histórico; exclusão de refeição inclui sua foto conforme decisão Q4. |
| Recuperação de fotos pela conta e cache; offline desejado | Exigem privacidade, isolamento por conta, durabilidade, conflitos e idempotência. Um estado apenas em memória não satisfaz esse requisito. |
| Português de Portugal como público pretendido e quatro idiomas no cliente | Mensagem da interface, nome original e nome editorial revisado têm proveniências diferentes. |
| Custo mínimo, sem parceria ou conteúdo contratado presumidos | Medir curadoria, revisão, armazenamento, transferência e suporte; “sem mensalidade de API” não demonstra operação sem custo. |

As respostas Q1–Q6 de 24–25/10 foram incorporadas ao [escopo de execução](../execucao/v1/escopo.md). Hospedagem, monetização e expansão clínica conservam decisões próprias. Master requer identidade/permissão revogável e auditoria; não deriva de e-mail, GitHub ou informação do cliente.

<a id="experiencia-e-figma"></a>
## Experiência e Figma

A proposta de 09/09 era um conceito claro de Hoje, Planos, Sessão, Atividade, Alimentação e Evolução, com fundo quente e verde. Foi uma etapa de exploração; a direção posterior aprovada adotou TF/Inter, grafite e lima. A [documentação de design](../design/README.md) identifica a referência e seus limites. O [arquivo Figma do TrainForge](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl) representa navegação e experiência; não comprova API, login real, GPS, reconhecimento ou persistência.

Referências efetivamente observadas na proposta inicial:

| Referência | Princípio observado e limite |
|---|---|
| [FIT.AI](https://www.figma.com/design/FuPFfoVyIp0QOViMNjh6C0?node-id=47-1546) | Organização do treino e contexto do curso. Chat e geração por IA não foram adotados como direção do produto. |
| [AI Fitness / Health](https://www.figma.com/design/doaUlA7YglxS1uIHldNSnG?node-id=0-1) | Separação de registro de atividade e análise; identidade e fluxos de IA não foram incorporados. |
| [Highfits](https://www.figma.com/design/FIQlkRhLYNrQLREKAMCGLH?node-id=0-1) | Rotina diária e cartões; foi observado o preview, sem auditoria de todas as telas anunciadas. |
| [FITBODY](https://www.figma.com/design/71zjiSv7mYq4IBIeHuaVrI?node-id=3263-101) | Visão modular de treino, alimentação e tracking; amplitude de referência não definiu escopo de lançamento. |
| [Nakafit](https://www.figma.com/design/JUto8GRSmbq8uEMKzAFAnV?node-id=2513-53) | Leveza visual na seleção de assinatura. O diário alimentar mencionado pelo autor não estava no nó observado. |
| [Fitness Activity](https://www.figma.com/design/6BzPImBcCzEZ32VaueecRh?node-id=0-1) | Hierarquia de números/calendário; a prancha declarava uso não comercial, sem liberação de seus assets para o produto. |

Os critérios de experiência continuam úteis: preservar filtro/scroll e rascunhos; mostrar vazio/erro/retentativa; teclado sem encobrir a ação; foco e retorno previsíveis; texto grande, contraste e alvos adequados; movimento reduzido. Para cada animação especificar gatilho, estados, interrupção e alternativa acessível. A proposta iOS/Liquid Glass dependia de compatibilidade e ensaio próprios; não é aceite nativo pelo fato de haver um projeto Flutter.

<a id="arquitetura"></a>
## Arquitetura e persistência

Em 17–24/09, a proposta era avaliar o Flutter e o Fastify/Prisma existentes antes de reescrever, separando responsabilidades e contratos. Em outubro a implementação adotou Go/pgx/SQL/Goose, e em 29/10 foi ensaiada a primeira extração do catálogo. Essa evolução não aprova automaticamente a extração de todos os domínios. A [arquitetura atual](../arquitetura/README.md) e as decisões documentadas governam o código vigente.

Continuam relevantes os limites de desenho registrados no planejamento:

- Estado de interação, dados compartilhados em sessão, dados locais duráveis e dados canônicos do servidor têm ciclos diferentes. Navegação não determina um endpoint por tela.
- Programa original, cópia personalizada, agenda, ocorrência e realizado devem conservar identidades e versões. Trocar catálogo/plano não reescreve o que já aconteceu.
- Imagem, OCR, sensor e importação têm origem, permissões, confirmação e desconhecidos próprios. Sugestão não confirmada não vira consumo definitivo.
- Offline precisa sobreviver ao processo e à troca de conta, registrar intenção/idempotência e resolver conflito/exclusão sem ressuscitar dados.
- Invariantes de propriedade, transação e concorrência vêm antes de dividir tabelas ou serviços. Fronteiras entre serviços precisam de ownership de dados e operação mensurável.

Esses critérios descrevem responsabilidades; não afirmam que toda capacidade desejada já exista.

<a id="custos-e-operacao"></a>
## Custos e operação

Na pesquisa de setembro foram comparadas opções gratuitas e comerciais nas fontes oficiais abaixo. São **candidatos históricos**, sem contas, recursos ou contratos criados por essa pesquisa; quotas e preços precisam de nova conferência antes de uso.

| Necessidade | Fontes consultadas | Questão que ficou para a prova técnica |
|---|---|---|
| Exercícios/programas/alimentos | [wger](https://wger.readthedocs.io/en/stable/), [USDA](https://fdc.nal.usda.gov/api-guide/), [Open Food Facts](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/docs/api/index.md), [PortFIR](https://portfir.insa.min-saude.pt/pt/) | Direitos por objeto, cobertura portuguesa, unidades/ausentes, cache e programas completos; resultados no guia de pesquisa. |
| Mapa e percurso | [Geoapify](https://www.geoapify.com/pricing/), [MapTiler](https://www.maptiler.com/terms/cloud/), [tiles OSM](https://operations.osmfoundation.org/policies/tiles/) | Mapa, tiles, geocodificação e roteamento são serviços distintos. Medir consumo por sessão, atribuição, cache/offline, precisão e ausência de mapa. |
| API | [Render](https://render.com/docs/free), [Cloudflare Workers](https://developers.cloudflare.com/workers/platform/pricing/), [Vercel](https://vercel.com/docs/limits/fair-use-guidelines) | Compatibilidade real do runtime, suspensão/retomada, conexões, CPU e uso comercial. A análise de Vercel Hobby o excluiu como base gratuita do produto monetizado naquele recorte. |
| PostgreSQL | [Neon](https://neon.com/pricing) | Cotas, região, pooling, retomada, backup/restore e crescimento; preferência/candidato não constituiu contratação. |
| Fotos e e-mail | [R2](https://developers.cloudflare.com/r2/pricing/), [Resend](https://resend.com/pricing/) | Acesso privado, EXIF, retenção/exclusão, transferência, cobrança por excedente, domínio/DNS e envio real. |
| Captura e dados conectados | [ML Kit OCR](https://developers.google.com/ml-kit/vision/text-recognition/v2), [Health Connect](https://developer.android.com/health-and-fitness/health-connect/data-types), [HealthKit](https://developer.apple.com/documentation/healthkit/hkworkout) | SDK/modelo não concede direitos de todos os dados. Validar aparelho, permissões, duplicados, background e limites do retorno. |

O dimensionamento original usou hipóteses, não tráfego medido: duas sessões × dez pedidos × 100 pessoas/dia = 2.000 pedidos; com 1.000 pessoas, 20.000. Mil fotos de 2 MB aproximam 2 GB antes de cópias. As contas ilustravam custos acumulativos; não provaram capacidade, latência, receita ou viabilidade financeira.

Os tetos de cerca de US$19 e R$400 e o interesse posterior em MoveKit R$779 pertencem a momentos diferentes. Nenhum constitui autorização geral de compra. A [avaliação MoveKit de 29–30/10](../conteudo/avaliacao-movekit-2026-10-29.md) permanece separada, com 582 exercícios anunciados e perguntas de cache/offline/entrega. Conteúdo de mídia não substitui programa/dose/revisão.

Para Portugal, o planejamento identificou proteção de dados, finalidade das informações de saúde, consentimento/publicidade, localização e regras das lojas como gates. Os links originais da [Comissão Europeia](https://commission.europa.eu/law/law-topic/data-protection/rules-business-and-organisations/legal-grounds-processing-data/sensitive-data_en), [Google Play](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en) e [Apple Developer](https://developer.apple.com/programs/enroll/) documentam o que foi consultado; esta consolidação não é avaliação jurídica atual nem autorização para cadastro, contato ou deploy.

<a id="qualidade-e-entrega"></a>
## Qualidade e entrega

O plano de setembro exigia rastrear requisito → fluxo/estado → contrato → invariantes → teste → evidência. Os principais cenários eram sessão/token concorrente, troca de conta sem vazamento, treino recorrente, histórico entre planos, data/fuso, unidades e desconhecidos, permissões negadas, interrupção/retomada, acessibilidade e exclusão.

Para beta, a proposta exigia jornada completa com conteúdo autorizado, dados reais preservados, tratamento de erro/rede ausente, recuperação e distribuição segura. Uma suíte verde, um APK gerado ou uma tela demonstrativa não encerram todos esses critérios. O [guia de validação e entrega](../execucao/v1/validacao-e-entrega.md), o backlog e os recibos atuais discriminam implementação, ensaio e aceite pendente.

Os documentos detalhados anteriores estão na [memória documental](../historico/README.md); não devem ser retomados como uma nova fila de instalação, pesquisa ou implementação.
