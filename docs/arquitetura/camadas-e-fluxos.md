# Camadas e fluxos

Estado do código em **18/11/2026**; [ponto de integração/ativação](../execucao/v1/handoff.md). O aplicativo Flutter usa a API Go; cinco consultas públicas passam por ela para o catálogo Go separado. O núcleo privado e o catálogo têm bancos e papéis próprios. [Visão geral](README.md) · [Mapas visuais](diagramas/README.md).

## Onde cada responsabilidade fica

| Peça | Papel | Onde alterar |
|---|---|---|
| Flutter: apresentação | Campos, foco, validação visual, navegação e estados de carregamento/ausência/conflito | `lib/features/*/presentation`, `lib/shared` |
| Controllers e repositories | Coordenam estado, contratos tipados, paginação e invalidação por conta/geração | `lib/features/*`, `lib/composition` |
| AppDio e sessão | Origem da API, transporte, refresh coordenado e tratamento seguro de falhas | `lib/core/http`, `lib/features/auth` |
| Handler e DTO Go | Decodificam formato, obtêm principal e traduzem resposta/erro HTTP | `services/api/internal/<domínio>` |
| Serviço e regras Go | Caso de uso, autorização por recurso, transições e idempotência | Arquivos de serviço/modelo de cada domínio |
| Persistência PostgreSQL | SQL parametrizado, locks, revisão, transações e consultas projetadas | Arquivos `postgres*.go`, migrations e funções SQL |
| Composição e plataforma | Montam dependências, configuração, pools, servidor e encerramento | `services/api/cmd`, `internal/platform` |
| Importadores e ferramentas | Revisão/publicação explícita, operação local e verificações | `services/api/cmd`, `tools`, `content/manifests` |

Uma camada representa uma responsabilidade. Dentro do núcleo, handler, serviço e persistência se chamam no mesmo processo. Interfaces pequenas ficam próximas de quem as consome, quando há motivo real; não há exigência de criar adapters ou casos de uso vazios para cada operação.

Exceção conhecida: partes da escrita alimentar ainda usam `NutritionStore` concreto a partir do handler. SQL/transações ficam em `postgres_entries.go`, cálculo/regras em `entries.go`; a fronteira de caso de uso pode ser refinada ao expandir esse módulo. A coordenação de privacidade sobre dados dos módulos é explícita, com inventário, transação e testes; não representa acesso livre entre domínios.

## Composição do Flutter

`TrainForgeApp` recebe `AppDependencies` ou compõe as fábricas de produção na raiz. `AppDependencyScope` fica acima do Navigator; serviços são criados sob demanda e os privados são vinculados à identidade. Widgets recebem dependências; o diário não usa um singleton de estado compartilhado entre contas.

Na abertura, aparência e idioma são carregados em paralelo, depois `AuthGate` restaura a sessão. Falha de rede oferece recuperação e preserva credenciais. A troca de conta remove rotas privadas e invalida respostas antigas. Hoje/Diário usam o resumo real da data escolhida; ausência de atividade ou programa não é substituída por exemplo. [Composição](../execucao/v1/frontend-composition-verification.json) · [Estado](../execucao/v1/frontend-state-verification.json).

`APP_ENV` aceita `development`, `staging` e `production`: debug usa development por padrão; profile/release usam production. `API_BASE_URL` vem de `dart-define`. HTTP só é aceito para hosts locais exatos em development/debug; os outros recortes exigem HTTPS. A origem não aceita credenciais, query, fragmento ou path extra. Isso configura o cliente, sem criar hospedagem.

O idioma da UI segue o aparelho ou a escolha local entre pt-BR, pt-PT, en e es; fallback pt-BR. ARB/delegates tipados apresentam a interface. Conteúdo original, nome de apresentação e tradução editorial são camadas distintas: mudar locale não muda o alimento, a fonte ou os nutrientes. iOS mantém validação nativa própria.

## Caminho de uma consulta

Na alimentação, `LocalFoodRepository` consulta o SQLite assinado e `OfflineNutritionRepository` lê o armazenamento cifrado da conta. FTS4, porções e GTIN funcionam sem buscar alimentos em fornecedores. O primeiro login é online; o perfil local pode ser reaberto offline enquanto não há revogação conhecida.

Nas jornadas que consultam o servidor:

1. A pessoa abre uma tela e o controller solicita a leitura ao repository.
2. AppDio envia a requisição à API; consultas privadas carregam a sessão da conta.
3. Handler valida parâmetros; serviço/persistência validam titularidade e leem o PostgreSQL.
4. O repository decodifica a resposta e só a aplica se conta, geração, revisão e contexto ainda forem os mesmos.

O [mapa 02](diagramas/02-arquitetura.svg) mostra comunicação; o [mapa 03](diagramas/03-telas.svg), navegação. Imports e referências de construtor presentes no [inventário](gerado/referencia.md) são evidência estática, não um teste de clique.

## Escritas e respostas incertas

O usuário revisa a intenção; o cliente mantém corpo e chave estáveis enquanto o resultado é incerto. O servidor revalida credencial/titular na transação, confere revisão e grava resultado/idempotência juntos. Reenvio igual recupera o resultado permitido; outra intenção com a mesma chave conflita. O cliente só anuncia o estado confirmado.

Na alimentação, salvar grava recurso, snapshot e operação UUID na mesma transação SQLCipher. A fila mantém o corpo original, dependências, revisão e resultado; o ledger Go permite reconciliar resposta perdida sem duplicar. Conta trocada, 401 conhecido e exclusão bloqueiam acesso/reenvio. Confirmação exige paridade de cálculo. Na atividade, rascunhos e intenções atuais ainda ficam em memória; fechar o processo pode perdê-los, mantendo V1-026 aberta. Retomar atividade recupera os eventos confirmados no servidor; não infere repetições, tempo praticado ou uma intenção não confirmada pelo tempo que o aplicativo ficou fechado.

## Jornadas e fronteiras

| Jornada | Fluxo e limite atual | Fonte detalhada |
|---|---|---|
| Sessão | Google → troca Go → par de tokens → refresh coordenado → logout/revogação; rede não apaga sessão | [Aceite local](../execucao/v1/implementacao.md), [mapa 04](diagramas/04-login.svg) |
| Configuração | Conta/Planos → locais/contexto → recursos → disponibilidade/fuso → revisão → versão privada; conflito preserva rascunho | [V1-047](../execucao/v1/implementacao.md) |
| Catálogo | Cinco GETs via API → reader do catálogo → banco editorial separado; falha não usa cópia antiga silenciosa | [Decisão e transição](decisoes.md), [mapa 06](diagramas/06-catalogo.svg) |
| Execução | Atividade → ocorrência real → sessão/eventos/comandos → revisão/replay durável no Go | [V1-017](../execucao/v1/implementacao.md#atividade) |
| Alimentação | SQLite público → quantidade/porção → snapshot e fila SQLCipher → diário local → sync Go com revisão/paridade; refeições agrupam os mesmos registros | [Registro](../execucao/v1/implementacao.md), [refeições](../execucao/v1/implementacao.md), [mapa 05](diagramas/05-consumo.svg) |
| Privacidade | Política pública; conta → exportação por seção ou intenção temporária/frase → exclusão transacional/revogação → limpeza local condicional | [V1-013](../execucao/v1/implementacao.md) |

O código de execução não fornece um programa revisado. V1-015/016 ainda dependem de conteúdo humano aprovado, adesão/agenda e demais critérios próprios. Seleção, composição, fotos, offline e master não ficam concluídos por compartilhar esta estrutura.

## Publicação editorial

Fonte pesquisada → evidência de direitos/revisão por versão → manifesto limitado → importador idempotente → banco → API → repository → tela. O fornecedor não precisa ser consultado a cada toque. Conteúdo público pode usar revisão/ETag; dados privados exigem titularidade e invalidação por conta. Mídia só entra com direitos para o uso exato.

Nomes alimentares têm regras em `names.go`, escrita operacional em `names_postgres.go`, consulta/projeção em `names_read.go`/`names_localized.go` e composição em `cmd/food-names`/`internal/foodnamesops`. O runtime lê; o CLI publica ou retira com pacote confirmado. Não existe endpoint editorial público. [Modelo e contratos](modelo-e-contratos.md).

[Operação diária](../aprendizado/operacao-local.md) · [Segurança](seguranca-operacao.md) · [Como a documentação é mantida](manutencao.md).
