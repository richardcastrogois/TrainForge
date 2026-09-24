# TrainForge — guia de retomada

**Retomada atual — 24/09/2026:** começar pela [visão integral R01–R18](docs/planejamento/README.md), [pitch](docs/planejamento/pitch-e-decisoes.md) e [balanço da etapa 01](docs/planejamento/etapa-01-pesquisa.md). A etapa 0 tem inventário preservado e alinhamento documental; a etapa 01 continua aberta. Alterações futuras do design estão em [ajustes do Figma](docs/design/ajustes-visao-integrada.md), sem edição visual neste incremento. A publicação inicial no GitHub foi autorizada pelo autor, com revisão do conjunto.

Análise em **9 de setembro de 2026**. Primeira etapa: contexto, diagnóstico, Graphify, documentação e proposta visual. Código de aplicação preservado; publicação, refatoração e pesquisa profunda de fontes ficam para as próximas etapas.referente ao documento dfrgf

## Comece aqui

1. Leia este guia para recuperar a visão geral.
2. Consulte [diagnóstico e prioridades](docs/diagnostico.md) para avaliar as decisões anteriores.
3. Use [documentação técnica](documentacao-tecnica.md) para fluxos, contratos, banco e pontos de alteração.
4. Consulte a [base Figma v0.4](docs/design/fluxos-v04.md), o [arquivo Figma](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl) e os ajustes futuros; a proposta visual inicial é histórica.
5. Confira [validação e limites](docs/validacao.md), [Graphify](docs/graphify.md) e [próximas fases](docs/proximas-fases.md).

## O que o projeto é hoje

O TrainForge **já é um aplicativo Flutter**, não um backend isolado. Existem 42 arquivos Dart em `lib/`, incluindo telas de autenticação, início, planos, dia de treino, estatísticas, perfil e onboarding manual/com IA. A interface é uma primeira implementação com Material 3 padrão; ainda não é o frontend final desejado.

O backend de que esse app depende continua em **`C:\dev\bootcamp-treinos-api`**. Ele tem Fastify, TypeScript, Prisma e PostgreSQL, autenticação web e mobile, geração de planos, sessões e estatísticas. Portanto, essa pasta tem duas funções: origem histórica e backend atual do TrainForge. Arquivá-la como referência descartável interromperia o produto atual.

| Pasta | Estado observado | Papel na retomada |
| --- | --- | --- |
| `C:\dev\TrainForge\trainforge` | Flutter 0.1.0+1; Git iniciado em 24/09 para publicação da base | Produto principal e localização desta documentação |
| `C:\dev\bootcamp-treinos-api` | API evoluída depois da imersão; Git existente | Backend efetivamente consumido pelo app; referência a preservar |
| `C:\dev\bootcamp-treinos-frontend` | Next.js/React; Git existente | Frontend web histórico; não necessário para iniciar o Flutter |

Não existe backend separado dentro de `trainforge`. A pasta externa `C:\dev\TrainForge` é atualmente apenas a pasta que contém o app.

## História reconstruída

Segundo o relato do autor, a imersão de uma semana ensinou um site que conversa com uma IA para montar treinos. Após hospedar e testar, surgiram preocupações de velocidade, uso cotidiano no telemóvel, custo de tokens e adequação dos treinos às pessoas. A intenção passou a ser um app comercial com planos de origem humana, expandindo posteriormente para corrida, alimentação e outras atividades.

O Git local da API confirma evolução em março de 2026: melhorias de desempenho/ambiente e bootstrap em 13/03, autenticação mobile em 16/03 e geração manual/validação em 22/03. O HEAD observado é `523f6d9`. Isso explica por que as pastas antigas já contêm trabalho do novo produto. Não foi reconstruído todo o curso nem validado o estado remoto do GitHub.

## O que existe e o que falta

| Capacidade | Situação atual |
| --- | --- |
| App instalável com projeto Android/iOS | Estrutura Flutter presente; análise estática passou; publicação não preparada |
| Login Google | Fluxo implementado no Flutter e API; integração real não exercitada nesta etapa |
| Dados físicos | Peso, altura, idade e gordura corporal; formulário e API |
| Planos sem IA | Gerador determinístico local por objetivo, frequência e experiência |
| Planos de autores humanos identificados | Ausente: não há fonte, autor, licença, revisão ou catálogo |
| IA | Ainda presente no app, API e configuração obrigatória de ambiente |
| Consulta e início/fim de treino | Implementados; existe problema de repetição de treino em semanas posteriores |
| Registo de séries/carga/repetições realizadas | Ausente; os exercícios guardam a prescrição, não o realizado |
| Estatísticas | Sessões concluídas, taxa de conclusão, tempo e consistência do plano ativo |
| Offline e sincronização | Ausentes; secure storage guarda somente o token de acesso |
| Corrida/GPS, desportos, alimentação/calorias | Ausentes |
| Anúncios, assinatura, pagamento | Ausentes |
| Neon/Vercel/lojas no novo app | Intenção futura; nenhum provisionamento ou deploy nesta etapa |
| Testes automatizados de produto | Não localizados nos diretórios de código analisados |

## Direção desejada — visão revista em 24/09/2026

Guia integrado de treino, movimento, alimentação e acompanhamento, para quem precisa de ajuda e para quem quer montar/customizar. Deve oferecer programas humanos existentes, múltiplas modalidades na academia/em casa/ao ar livre, instruções visuais, objetivos e progressão por contexto, alimentação planeada e consumida, aprendizagem de rótulos e registos manuais, conectados e assistidos por imagem.

Dores, operações e retorno são contextos adicionais, não foco exclusivo. Não existe decisão atual de limitar o lançamento à musculação. O catálogo pronto é necessário; importar plano próprio não o substitui. Reconhecimento visual permanece desejado, com fonte/custo/precisão ainda pendentes. Não gerar prescrição de treino por IA.

A [visão central](docs/planejamento/README.md) detalha requisitos; a [etapa 01](docs/planejamento/etapa-01-pesquisa.md) separa evidência e lacunas. O código descrito abaixo ainda contém funcionalidades históricas que terão de ser revistas; a documentação de intenção não as removeu.

## Como executar localmente

Os comandos abaixo descrevem o código atual. **O caminho completo autenticado ainda precisa de validação com banco e configuração Google próprios.** Não copie credenciais para o app, documentação ou Git.

### Pré-requisitos

- Flutter compatível com Dart `^3.11.1`, SDK Android e dispositivo/emulador.
- Node 24 e pnpm 10.30.0 para a API, conforme `package.json`.
- PostgreSQL. O Compose de referência usa PostgreSQL 16 e porta local 5433.
- Configuração de ambiente da API conforme a tabela técnica; o arquivo `.env` não foi reproduzido.

### API — terminal separado

```powershell
Set-Location C:\dev\bootcamp-treinos-api
pnpm install --frozen-lockfile
docker compose up -d
pnpm exec prisma generate
# Só aplicar após conferir DATABASE_URL e confirmar que é o banco local desejado:
pnpm exec prisma migrate deploy
$env:PORT = '8081'
pnpm dev
```

`docker compose up -d` inicia apenas o PostgreSQL; a API roda no terminal. O valor padrão de `PORT` no código é **8080**, enquanto Flutter e `API_BASE_URL` usam **8081**. Por isso a porta é explicitada acima. O Compose usa credenciais demonstrativas locais; não é configuração de produção.

### Flutter — Android físico por USB

```powershell
Set-Location C:\dev\TrainForge\trainforge
flutter pub get
adb reverse tcp:8081 tcp:8081
flutter devices
flutter run
```

O endereço atual é `http://127.0.0.1:8081`, fixado em `lib/core/config/app_config.dart`. No telefone, esse endereço se refere ao próprio telefone: o redirecionamento USB é necessário neste fluxo. No emulador Android, pode-se configurar posteriormente `10.0.2.2` ou usar redirecionamento para o dispositivo escolhido. Fora do desenvolvimento, será necessária uma URL HTTPS configurável por ambiente.

Não é necessário `flutter clean` a cada execução. O README antigo foi preservado, mas mistura comandos de app e banco. **`docker compose down -v` apaga o volume do banco** e não faz parte da inicialização normal.

### Verificações sem banco

```powershell
Set-Location C:\dev\TrainForge\trainforge
flutter analyze --no-pub

Set-Location C:\dev\bootcamp-treinos-api
node node_modules/typescript/bin/tsc --noEmit

Set-Location C:\dev\bootcamp-treinos-frontend
node node_modules/typescript/bin/tsc --noEmit --incremental false
```

Os três comandos passaram nesta análise usando as dependências locais. Isso não equivale a reinstalação limpa, build release ou teste integrado.

## Hospedagem, lojas e custo

O aplicativo Flutter roda no aparelho; Vercel seria hospedagem de API e/ou site, enquanto Neon seria o banco acessado pelo servidor. O app não deve conter uma conexão PostgreSQL com credenciais do Neon.

Há um conflito a resolver: o plano gratuito Hobby da Vercel restringe uso a projetos pessoais não comerciais. Um produto monetizado por anúncios não deve assumir esse plano como fundação gratuita. [Documentação Vercel](https://vercel.com/docs/plans/hobby). A Neon oferece plano gratuito com limites; a adequação dependerá de uso e arquitetura, sem garantia de custo zero contínuo. [Neon](https://neon.com/pricing).

As lojas também têm custos: Google Play cobra US$25 uma vez para registo da conta; Apple Developer cobra US$99 por ano, com possíveis valores locais/impostos. [Google Play](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en), [Apple](https://developer.apple.com/programs/enroll/). Contas pessoais novas no Google Play têm requisitos adicionais de testes antes do acesso à produção. [Requisitos oficiais](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

Atender Portugal não determina, por si só, moeda de recebimento ou receita. Modelo de anúncios, conta de pagamentos, região e condições do fornecedor precisam ser definidos depois. Nenhuma receita foi estimada nesta etapa.

## Resultado desta etapa

Existe uma base aproveitável, mas ainda não um produto pronto para utilizadores. A decisão seguinte é revisar este diagnóstico e definir como preservar o backend atual ao organizar o TrainForge no GitHub. A pesquisa de fontes, a skill específica de criação do app e a arquitetura definitiva continuam reservadas às fases solicitadas.
