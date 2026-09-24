# Viabilidade operacional — mapas, hospedagem e custo

**Revisão de escopo em 24/09/2026:** preservar as evidências operacionais datadas abaixo. A visão atual inclui [R01–R18](README.md); complementar a viabilidade com reconhecimento por imagem, conexão a plataformas/dispositivos, conteúdo visual, planeamento alimentar e manutenção por modalidade. Essas capacidades ainda não foram dimensionadas/testadas. Preços/termos abaixo não foram reconferidos neste incremento. O [balanço da etapa 01](etapa-01-pesquisa.md) registra a cobertura real.


Pesquisa em 22/09/2026. Sem criação de contas, chaves privadas, deploy, assinatura ou cobrança. Limites são um retrato da documentação, não garantia permanente. A recomendação é para piloto, sujeita às provas técnicas das etapas 5–7.

## Mapas

| Opção | Constatação | Uso recomendado |
|---|---|---|
| [Geoapify](https://www.geoapify.com/pricing/) | Gratuito anuncia 3.000 créditos/dia, sem cartão, 5 pedidos/s; FAQ admite projetos comerciais com atribuição. Cada serviço consome créditos segundo sua regra. | **Primeiro candidato de piloto**. Criar chave apenas no incremento autorizado; medir tiles por sessão e limites reais no Flutter. |
| [MapTiler](https://www.maptiler.com/terms/cloud/) | Gratuito limitado a não comercial ou pesquisa/desenvolvimento de produto comercial. | Pode servir a protótipo; não base gratuita do app comercial publicado. |
| [Tiles públicos OSM](https://operations.osmfoundation.org/policies/tiles/) | Serviço best effort, sem SLA; atribuição/identificação e cache obrigatórios; sem download em massa para offline. | Não assumir infraestrutura ilimitada de produção nem oferecer baixar cidade por esse serviço. |

A página comercial do Geoapify descreve limites flexíveis, enquanto seus [termos](https://www.geoapify.com/terms-and-conditions/) preveem suspensão ou excedentes. Confirmar controle de gasto antes de publicar; implementar limite interno e não repartir chamadas em várias contas para contornar quotas. Cache persistente/offline e redistribuição de tiles permanecem pendentes de regra específica; não presumir autorização a partir da permissão comercial.

Captura de GPS, desenho da linha percorrida, mapa-base, geocodificação e cálculo de rotas são capacidades separadas. Primeira proposta: registrar percurso do dispositivo e exibir mapa; não incluir navegação curva a curva ou download offline sem necessidade demonstrada. Fallback: cronómetro/dados manuais e aviso de mapa indisponível. Não enviar localização a redes de anúncios. Não foram feitas chamadas com coordenadas pessoais nem testes de GPS nesta pesquisa.

## Componentes de hospedagem

| Componente | Candidato / limites consultados | Implicação |
|---|---|---|
| API mantendo runtime Node | [Render Free](https://render.com/docs/free): 750 horas por workspace/mês, suspende após 15 min sem tráfego; retomada descrita em cerca de um minuto; disco efémero. | **Desenvolvimento/beta tolerante**, não satisfaz por si a intenção de abertura rápida. Não guardar fotos/banco no disco local nem criar pings artificiais para contornar suspensão. |
| API em outro runtime | [Cloudflare Workers](https://developers.cloudflare.com/workers/platform/pricing/): plano gratuito com 100 mil pedidos/dia, limites próprios de CPU e execução. | **Candidato a prova técnica**. Verificar Fastify/Prisma, autenticação, bibliotecas, conexões e latência. Não reescrever a API só por comparação de preços. |
| Banco | [Neon Free — limites oficiais](https://github.com/neondatabase/website/blob/main/content/faqs/free-plan-limits-and-quotas.md): 100 CU-h/projeto/mês, 0,5 GB/projeto, 5 GB de transferência pública/projeto/mês. | **Manter como candidato preferido do autor**. Pooling, região, retomada, retenção/backup e crescimento precisam de prova. Catálogos/mídia podem consumir a quota rapidamente. |
| Fotografias privadas | [R2 Standard](https://developers.cloudflare.com/r2/pricing/): 10 GB-mês, 1 milhão de operações classe A e 10 milhões classe B incluídos; saída direta sem taxa de egress. | Candidato com cobrança por excedente; livre franquia não é teto de custo. Avaliar cadastro/faturamento, URLs temporárias, remoção de EXIF, retenção e limites. |
| E-mail transacional | [Resend](https://resend.com/pricing/): gratuito com 3.000 e-mails/mês e 100/dia. | Candidato para confirmação/recuperação; domínio/DNS e entrega real ainda precisam ser configurados/testados. Não substitui autenticação. |
| Páginas de suporte/privacidade | Hospedagem estática comercial compatível a escolher junto do backend | Custo de domínio e canal de suporte separado do app nativo. |
| Vercel Hobby | [Política](https://vercel.com/docs/limits/fair-use-guidelines) limita a uso pessoal não comercial. | **Descartado como base gratuita para produto comercial**. Reavaliar plano pago apenas se orçamento permitir. |

Render Free Postgres não é alternativa duradoura ao Neon: a documentação consultada descreve expiração em 30 dias. Acesso a banco externo também entra nas restrições de tráfego do Render; ler limites completos antes de aceitar esse piloto.

Conclusão: há candidatos para um piloto pequeno sem mensalidade, mas **não foi comprovada uma configuração simultaneamente gratuita, comercial, rápida e pronta para este backend**. A prova de hospedagem pertence à etapa técnica; não declarar que uma soma de free tiers é arquitetura homologada. Caminho de pesquisa preferido: Neon + prova Workers; comparação de controle: Node compatível em Render para medir o custo de manter stack e efeito da retomada. Se nenhuma alternativa cumprir, escolher explicitamente entre reduzir o piloto e aceitar um pequeno orçamento.

## Dimensionamento sem inventar receita

Hipóteses, não medições do aplicativo:

| Cenário | Cálculo | Alerta |
|---|---|---|
| 100 ativos/dia | 2 sessões × 10 pedidos × 100 = 2.000 pedidos/dia | Contagem cabe em muitas franquias; CPU, banco e bursts podem ser o verdadeiro limite. |
| 1.000 ativos/dia | Mesmas hipóteses = 20.000 pedidos/dia | Cada consulta a fornecedor precisa de cache; limite por IP compartilhado importa. |
| Fotos | 1.000 fotos de 2 MB ≈ 2 GB, antes de cópias/miniaturas | Crescimento acumulativo; prever compressão e retenção, não apenas custo do primeiro mês. |
| Mapa | Créditos/dia = utilizadores × sessões de mapa × créditos efetivos/sessão | Só definir capacidade após medição no protótipo técnico; um mapa pode disparar vários tiles. |
| E-mail | 150 cadastros com um e-mail no mesmo dia | Excede 100/dia mesmo abaixo de 3.000/mês; tratar fila, abuso e experiência de recuperação. |

Manter €0 recorrente como meta inicial de piloto. Taxas das lojas, domínio e ambiente de build Apple são custos separados já apontados no [plano de fontes/custos](fontes-custos-e-hospedagem.md). Não há promessa de ganho em euro/dólar por disponibilizar o app em Portugal.

## Critérios da futura prova técnica

1. Usar ambiente com dados fictícios e orçamento/limites explícitos.
2. Validar uma autenticação, consulta e escrita idempotente no runtime candidato; medir primeira chamada e chamadas quentes separadamente.
3. Validar pooling, conexão perdida, saturação, migrações e restauração; não rodar tarefas longas na requisição.
4. Medir uma sessão real de mapa com chave restrita, atribuição, permissão negada e quota esgotada; não fazer teste de carga contra fornecedor público.
5. Validar upload privado limitado e exclusão; impedir armazenamento público acidental e remover metadados de localização de foto.
6. Documentar custo observado e forma de parar consumo; só então escolher hospedagem/fornecedor definitivo.

## Limites de privacidade e operação

Aplicar as tarefas de RGPD, políticas das lojas, anúncios sem dados sensíveis, exclusão/exportação e acessibilidade já previstas em [qualidade e lançamento](qualidade-e-lancamento.md). A escolha de região europeia sozinha não comprova conformidade. Não foram contratados processadores nem implementado consentimento nesta pesquisa.
