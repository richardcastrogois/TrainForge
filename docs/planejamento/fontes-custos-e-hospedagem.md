# Fontes, custo e hospedagem

**Alinhamento de 24/09/2026:** usar a [visão integral](README.md) e o [balanço atual da etapa 01](etapa-01-pesquisa.md). Programas prontos, alimentação guiada e reconhecimento assistido são necessidades do produto; plano próprio/foto manual são caminhos complementares. A pesquisa de custo deve cobrir todas as capacidades selecionadas, sem pressupor parceiros. Valores e condições de 17–22/09 abaixo são histórico; não foram todos reconferidos nesta revisão documental.

**Atualização de 23/09/2026:** a entrada atual para fontes é a [pesquisa ampliada de conteúdo](../conteudo/README.md), com 43 fontes/famílias, amostras adicionais e critérios editoriais. Mapas e hospedagem continuam em [viabilidade operacional](viabilidade-operacional.md), de 22/09, sujeitos a nova conferência antes da integração. A [primeira rodada](etapa-01-pesquisa.md) foi preservada. O texto abaixo é o retrato histórico de 17/09; não significa que a pesquisa/coleta ainda não começou nem que alguma fonte foi homologada.

Triagem documental atualizada em 17/09/2026. Não foram feitos testes de API, contratado serviço ou aprovado fornecedor. Preços, cotas e condições precisam de nova conferência antes da integração/publicação.

## O que pesquisar antes de fechar o Figma

Pesquisar cedo as capacidades que determinam campos, mídia e promessas: programas completos de treino, instruções licenciadas, composição/porções de alimentos, cobertura portuguesa, mapa e fotografia. Depois aprovar contratos internos estáveis, independentes do fornecedor. A [pesquisa anterior](../pesquisa-fontes.md) continua como histórico; não implica seleção.

| Necessidade | Candidato e evidência inicial | O que falta para aprovar |
|---|---|---|
| Exercícios e instruções | [wger API](https://github.com/wger-project/docs/blob/master/docs/api/api.rst) oferece recursos de exercícios e ingredientes; rotinas pessoais requerem autenticação. A [documentação de licença](https://wger.readthedocs.io/en/2.4/) distingue código e dados. | Avaliar português, campos, imagens por origem, atribuição, derivados, cache/offline e disponibilidade. Não tratar licença do código como licença universal de mídia. |
| Programas completos humanos | Ainda sem fonte aprovada. Catálogo de exercícios não comprova programa estruturado com autoria e revisão. | Autoria, versão, objetivo, progressão, público, direitos comerciais e limitações. Alternativa: plano do próprio utilizador/profissional ou conteúdo licenciado; não prometer adaptação clínica automática. |
| Alimentos genéricos | [USDA FoodData Central](https://fdc.nal.usda.gov/api-guide/): dados de domínio público/CC0, chave de API e limite padrão documentado de 1.000 pedidos/hora/IP. | Cobertura útil em Portugal, unidades, campos ausentes, seleção dos tipos de dados, normalização e cache; chave protegida no servidor. |
| Produtos embalados | [Open Food Facts](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/docs/api/index.md): base colaborativa sob ODbL, exigências de atribuição e limites distintos por operação. | Entender obrigações de banco derivado/redistribuição, qualidade dos rótulos e separação de dados privados; medir pesquisa/códigos portugueses. Não fazer chamada por tecla. |
| Composição portuguesa | [PortFIR/INSA](https://portfir.insa.min-saude.pt/pt/) é uma referência local para composição de alimentos. | Confirmar licença comercial, redistribuição, atualização e formato de acesso; não presumir API pública nem autorização para incorporar ficheiros. |
| Mapa | Dados OSM e serviço de tiles são recursos distintos. A [política dos tiles públicos](https://operations.osmfoundation.org/policies/tiles/) exige atribuição/cache e não autoriza downloads em massa para offline. | Selecionar provedor/infra, limites, uso comercial, cache, confiabilidade e custo. Avaliar separadamente geocodificação e rotas. |

Evitar combinar diversos catálogos sem critério: os mesmos alimentos/exercícios podem ter IDs, licenças, unidades e qualidade diferentes. Começar com uma fonte aprovada por necessidade e acrescentar outra somente para uma lacuna mensurável.

## Pesquisa profunda: entrega e aceite

Para cada candidato registrar fonte oficial, entidade responsável, atualização, custo/cotas, uso comercial, licença de dados e mídia, atribuição, derivados, armazenamento, cache/offline, autenticação, indisponibilidade, exportação e possibilidade de troca. Dúvida de licença é pendência, não autorização implícita.

Testar uma amostra proposta de 20–30 exercícios das modalidades priorizadas, 20 produtos embalados de Portugal e 15 alimentos genéricos, ajustando ao recorte aprovado. Para programas, avaliar alguns planos completos, incluindo ordem, progressão, frequência e autoria. Medir cobertura, campos faltantes, resposta, taxa de erro e duplicados. Esse era o plano de 17/09. As coletas realmente executadas estão na etapa 01 e nas amostras de 23/09; a proposta atual para produtos portugueses é avaliar 30 códigos reais, ainda pendente.

Entregar matriz comparativa, exemplos reais sanitizados de payload, campos normalizados, direitos de cada ativo, estratégia de fallback e decisão justificada. Se a fonte não permitir cache/licenciamento necessário, alterar a função ou trocar a fonte antes de fixar o desenho.

## Captura por imagem, conexões e custo

A visão pede identificação assistida de alimento/atividade. Pesquisar separadamente imagem do prato, código, OCR de rótulo/painel, identificação de movimento e sensores/dispositivos. Modelo local pode reduzir chamadas mas tem tamanho, desempenho, bateria, licença e manutenção a avaliar; serviço remoto tem custo, privacidade, disponibilidade e transferência. Nenhum foi selecionado.

O pipeline precisa de confirmação/correção e de dados apropriados: uma imagem isolada não comprova duração, calorias gastas ou gramas ingeridas. Foto privada e entrada manual preservam utilidade em caso de falha, sem substituir o requisito desejado. Triagem oficial inicial de Health Connect, HealthKit e ML Kit está na etapa 01; integração real permanece pendente.

## Infraestrutura: o que de fato precisa ser hospedado

O app nativo é distribuído pelas lojas. Backend HTTP, Postgres, arquivos/fotos, páginas de privacidade/suporte, e-mail transacional, monitorização e eventualmente trabalhos em background são partes separadas. Vercel não hospeda a instalação Android/iOS; Neon não substitui API nem armazenamento de fotografias.

| Opção | Adequação e ressalva nesta fase |
|---|---|
| Vercel Hobby | A [política oficial](https://vercel.com/docs/limits/fair-use-guidelines) restringe Hobby a uso pessoal não comercial. Não usar como premissa de hospedagem gratuita de produto monetizado. Rever plano comercial ou alternativa. |
| Neon Free | Candidato para Postgres com cotas e retomada a avaliar. Conferir [limites oficiais mantidos pela Neon](https://github.com/neondatabase/website/blob/main/content/faqs/free-plan-limits-and-quotas.md), conexão/pooling, região e limites por projeto. Não garante ausência de custo em crescimento. |
| Cloudflare Workers | Candidato de API sujeito a [limites/preços](https://developers.cloudflare.com/workers/platform/pricing/) e compatibilidade. Fastify/Prisma atuais não devem ser considerados uma migração automática: provar runtime, conexão, bibliotecas e custo de adaptação. |
| Render gratuito | Avaliar somente como candidato de protótipo conforme [documentação oficial](https://render.com/docs/free); verificar suspensão/inatividade e retomada antes de aceitar o tempo de primeira resposta. Não prometer experiência sempre disponível. |
| Arquivos de mídia | Selecionar armazenamento de objetos com acesso privado, URLs temporárias, limite de tamanho, exclusão e orçamento de transferência. Fornecedor ainda não escolhido. |

O processo de decisão deve comparar manter o backend existente num host compatível versus adaptá-lo para outro runtime. Economia de mensalidade pode aumentar custo de desenvolvimento e manutenção. Registrar limites de CPU/execução, conexões, saída de dados, logs, backup, residência/transferência de dados, política comercial e alertas de quota.

## Orçamento de piloto

“Zero custo recorrente no piloto” é uma meta a validar, não garantia de operação ilimitada. Separar gastos recorrentes, iniciais de loja/hardware e trabalho de manutenção. O programa Apple anuncia [US$ 99 por ano](https://developer.apple.com/programs/enroll/); taxas locais e condições precisam ser confirmadas no cadastro. Conferir também a [inscrição Google Play](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en), domínio, e-mail, equipamento/build iOS e eventuais taxas de fornecedores.

Estimar por cenário antes de escolher plano. Exemplo puramente quantitativo: 100 utilizadores ativos/dia × 2 sessões × 10 pedidos = 2.000 pedidos/dia; 1.000 fotos de 2 MB representam cerca de 2 GB antes de miniaturas e backups. Medir também transferência, leituras de mapa, tempo de CPU, e-mail e crescimento do banco. Esses números são hipóteses de dimensionamento, não previsão de uso ou preço.

Configurar alertas, limites de upload, retenção e comportamento ao atingir quota. Escolher entre bloqueio seguro, redução de funcionalidades ou upgrade consciente; nunca depender de cobrança automática desconhecida. Considerar exclusão/compactação de fotos e vídeo sob demanda desde o desenho.

## Portugal, privacidade e monetização

Definir português europeu, unidades métricas e fuso corretamente; localização não garante pagamento de anúncios em euros/dólares. Moeda de recebimento, conta elegível, impostos e condições da rede são verificações comerciais posteriores.

Dados de saúde exigem avaliação específica no [contexto do RGPD](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/application-gdpr_en). Identificar bases legais e, quando aplicável, condição para dados sensíveis, finalidade, minimização, retenção, exportação/exclusão e contratos com fornecedores. Não presumir que uma caixa de consentimento resolve todas as obrigações.

A Apple estabelece restrições ao uso de dados de saúde/fitness para publicidade em suas [diretrizes](https://developer.apple.com/app-store/review/guidelines/). Desenhar anúncios sem segmentação por dados sensíveis e sem enviar perfil de saúde ao SDK. Para publicidade personalizada no EEE, avaliar as [exigências de CMP da AdMob](https://support.google.com/admob/answer/16918505?hl=en-GB); anúncios não personalizados também exigem revisão das obrigações aplicáveis. Validar ATT quando houver rastreamento. Não introduzir anúncios que interrompam exercício, temporizador ou navegação segura.

Antes de publicar, revisar políticas e obrigações com apoio adequado. Não há integração de anúncios nem alegação de conformidade jurídica concluída nesta etapa.

## Custos adicionais a medir com a visão integral

- Aquisição, tradução, conferência e manutenção de programas por modalidade, instruções visuais, receitas e ensino de rótulos; conteúdo aberto pode não cobrar licença, mas exige trabalho.
- Imagens privadas, miniaturas, retenção/exclusão, processamento local/remoto, tentativas de reconhecimento e tráfego; não contar apenas tokens.
- GPS, tiles, geocodificação/rotas se escolhidas, bateria e sessões em background; não assumir serviços OSM ilimitados.
- Integração com plataformas/dispositivos, testes em Android/iOS, permissões, sincronização e manutenção de SDKs.
- Projeções do dashboard, armazenamento offline/remoto, correções e recuperação de dados, suporte e observabilidade sem dados sensíveis.

Antes de cada escolha, registrar quota gratuita, uso comercial, comportamento no limite e custo por cenário. O primeiro commit no GitHub guarda a base do projeto; não contrata hospedagem nem aprova conteúdo/fornecedor.
