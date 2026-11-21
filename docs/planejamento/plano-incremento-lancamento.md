# Plano do próximo incremento: lançamento na Play Store e frentes associadas

Registrado em **20/11/2026** a pedido do autor. Reúne as frentes pedidas para depois da feira e as separa em **o que o Claude pode iniciar sozinho** e **o que depende do autor** (decisão, conta, compra, assinatura ou aprovação). O acompanhamento por item está no [checklist com passo a passo](checklist-incremento-lancamento.md).

Planos relacionados, já registrados: [pacotes regionais](melhoria-pacotes-regionais.md), [desvincular o Bootcamp](melhoria-identidade-google.md), [voz e foto](pesquisa-registro-voz-e-foto.md), [APK simples](melhoria-apk-simplificado.md) e [mídias MoveKit](../conteudo/plano-integracao-midias-movekit.md).

## 1. Lançamento oficial na Play Store

### Fatos já conferidos em 20/11 (APK 0.5.4+34)

| Item | Estado | Evidência |
|---|---|---|
| SDK alvo e de compilação | **36** (Flutter local); mínimo 24 | `FlutterExtension.kt`, `android/app/build.gradle.kts` |
| Páginas de 16 KB (exigência para alvo Android 15+) | **OK**: ZIP alinhado (`zipalign -c -P 16`) e todos os `.so` de 64 bits com `PT_LOAD` ≥ 16384 | Verificação local do `app-release.apk` |
| Identificador do app | **Bloqueio**: `com.example.trainforge`, que a Play não aceita | `build.gradle.kts` linhas 15 e 35 |
| Formato de envio | **Lacuna**: o script gera só APK; a Play exige **AAB** | `tools/preparar_release_android.py` |
| Exclusão de conta | No app: **existe** (Privacidade). Link web para pedir exclusão (exigência da Play): **não existe** | `privacy_page.dart` |
| Permissões | `INTERNET`, `CAMERA`; sem `AD_ID` | `AndroidManifest.xml` |
| Backup | `allowBackup=false` com regras de extração | `AndroidManifest.xml` |
| Tamanho | 139 MB (APK universal, 3 ABIs). O AAB divide por ABI, então o download real deve cair (medir) | Recibo da 0.5.4 |

### O que falta

- **No código (sem o autor):** gerar AAB, medir o tamanho por ABI e prever o limite de download da Play. Preparar a página web de exclusão de conta e privacidade (conteúdo). Rascunhar as respostas de Data safety e da declaração de apps de saúde, a ficha da loja (descrição curta e longa em pt-BR) e o roteiro de screenshots.
- **Dependem do autor:** conta Play Console (taxa única, verificação de identidade), definição do `applicationId` definitivo, que vem junto com o [novo OAuth](melhoria-identidade-google.md), hospedagem pública dos Termos, da Privacidade e da página de exclusão, teste fechado com testadores reais (para contas pessoais novas a Play exige um número mínimo de testadores por um período antes da produção; conferir o valor vigente no Console), aprovação de ícone, screenshots e textos, e envio para revisão.

## 2. Testes, CI/CD e estresse

Situação atual: 387 testes Flutter, suítes Go/vet, cerca de 140 testes Python das ferramentas, SQL descartável no CI e 8 workflows (API, imagem, catálogo, documentação, Flutter, restore, segredos, segurança Go). Lacunas conhecidas: o scanner EAN falha no teste nativo amplo, não há `integration_test` de jornada no emulador dentro do CI, o CI não constrói o release Android e não existe teste de carga ou estresse da API.

Plano por camadas:

| Camada | O que acrescentar | Quem |
|---|---|---|
| Inventário | Mapa "funcionalidade × tipo de teste × lacuna" a partir dos testes atuais | Claude |
| Jornada no emulador | `integration_test` para entrada (visitante), busca de alimento, refeição, offline/sincronização e exclusão | Claude |
| Visual | Testes golden das telas principais em tamanho de celular e tablet, claro e escuro | Claude |
| Contrato | Paridade Swagger × cliente Flutter (já existe parcialmente); ampliar para todas as rotas usadas | Claude |
| Carga e estresse | `vegeta` (Go, MIT) ou `k6` (ferramenta AGPL, usada só como executável) contra a API local + Postgres descartável: rampa, pico, resistência e limite de conexões | Claude (local). Contra Neon/Vercel só com OK do autor (plano gratuito, cotas) |
| Segurança | Gitleaks (já existe), `govulncheck` (já existe), `flutter pub outdated`/OSV, análise do APK (MobSF local, opcional) | Claude |
| CI Android | Workflow que gera AAB **sem segredos** (assinatura de teste), roda análise e testes e publica tamanho por ABI | Claude escreve; custo de minutos depende do repo privado (abaixo) |
| CD | Publicação na trilha interna da Play pela API (`fastlane supply` ou Gradle Play Publisher) com conta de serviço | Depende do autor (conta de serviço e segredo no GitHub) |
| Aceite humano | Roteiro de teste manual no celular para cada release | Autor executa |

## 3. Código no GitHub privado

Hoje o repositório é **público**. Tornar privado tem consequências que precisam ser resolvidas **antes**:

- O link fixo do APK e o QR code (GitHub Releases) deixam de funcionar para o público.
- Os links de Termos e Privacidade usados na tela de consentimento do Google e na ficha da Play deixam de abrir.
- Os pacotes regionais planejados (`catalog-packs-v1`) não poderiam ficar no repositório privado.
- O GitHub Actions passa a ter cota mensal de minutos no plano gratuito. Com 8 workflows e testes Android, a cota pode acabar.
- A Vercel continua fazendo deploy de repositório privado na conta pessoal.

**Direção do autor (20/11): dois repositórios.**

| Repositório | Visibilidade | Conteúdo |
|---|---|---|
| Código (o atual, `TrainForge`) | **Privado** | App, API, ferramentas, documentação interna, CI completo |
| Distribuição (ex.: `trainforge-app`) | **Público** | GitHub Pages: Termos, Privacidade, exclusão de conta, página de download com QR. Releases: APK e pacotes de alimentos (`catalog-packs-v1`). Sem código-fonte |

- Isso resolve os quatro problemas acima sem expor o código.
- A publicação passa a partir do repositório privado para o público: o `publicar_release_android.py` envia o release ao repositório de distribuição com um token de escopo mínimo.
- Exigência de atribuição ODbL do Open Food Facts: a oferta dos dados usados continua no repositório público, junto aos pacotes.
- Ordem: criar o público, migrar links e conferir downloads, e **só então** tornar o código privado.
- **Nome decidido pelo autor em 21/11: `trainforge-app`** (endereço `richardcastrogois.github.io/trainforge-app`). Pendente: momento da troca. Sugestões consideradas: `trainforge-app` (recomendado: neutro, serve para download e páginas legais), `trainforge-site` ou `trainforge-releases`. O endereço vira `richardcastrogois.github.io/<nome>` e fica gravado na Play, no Google e no QR, então convém escolher um nome definitivo. Um domínio próprio no futuro deixaria a troca transparente (custo anual, decisão do autor).

## 4. Anúncios

Pergunta do autor: os anúncios vão atrapalhar o uso?

Riscos específicos do TrainForge:

- O público prioriza **idosos e cuidadores**. Anúncio intersticial ou que se confunde com conteúdo gera toques acidentais e abandono.
- É um app de **saúde**: anúncio no meio do registro de refeição ou do treino quebra o fluxo e passa pouca confiança. A política da Play também restringe anúncios disruptivos.
- Exige atualizar a Política de Privacidade, o Data safety, a permissão `AD_ID`, o consentimento de anúncios (UMP/AdMob) e possivelmente os Termos. Também aumenta o APK e as chamadas de rede.
- O app funciona **offline**, e anúncios não carregam offline. A receita depende de uso online.

**Decisão do autor (20/11): o app terá anúncios**, porque não haverá mensalidade. A forma de implementar fica **por último**, salvo o que muda o visual ou a ficha da loja, que precisa ser previsto antes:

- **Decisão do autor (21/11)**: reservar o espaço de fato **no APK e no Figma** antes da implementação dos anúncios. No Figma, as chamadas MCP tinham atingido o limite do plano Starter em 19/11: conferir se a cota voltou antes de editar.
- **Espaço visual**: um banner muda a altura útil da tela. Para não refazer layouts depois, as telas secundárias (busca, listas, histórico) passam a prever **uma área de rodapé reservada**, vazia enquanto os anúncios estiverem desligados. Fazer junto com o [APK simples](melhoria-apk-simplificado.md), que já vai mexer nas telas.
- **Telas sem anúncio, nunca**: entrada, termos, privacidade, registro de refeição, sessão de treino e confirmação.
- **Ficha da loja**: a Play mostra "Contém anúncios". Se os anúncios entrarem só depois do lançamento, atualizar a ficha, o Data safety e a Privacidade na mesma versão.

Opções de formato, para quando chegar a hora:

1. **Banner discreto em telas secundárias**: menor impacto, receita menor.
2. **Anúncio recompensado opcional** (a pessoa escolhe assistir para liberar algo extra).
3. Combinação das duas.

Intersticiais (tela cheia entre ações) não são recomendados para este público.

**Estado (21/11): em segundo plano.** O autor precisa de sugestões de **onde**, **quanto** e **com que frequência** colocar anúncios, e de uma comparação de receita para decidir. Até lá, C14a/C14b (espaço reservado) também esperam. Sugestões para a decisão:

| Proposta | Onde | Quantidade/frequência | Impacto no uso |
|---|---|---|---|
| **A. Mínima** | Banner fixo no rodapé de busca de alimentos e diário | 1 banner por tela, troca a cada 60 s | Baixo |
| **B. Equilibrada** (sugerida) | A + recompensado opcional ("assistir para liberar relatório semanal detalhado / tema / pacote extra") | Banners como A; recompensado só quando a pessoa pede, no máximo 3 por dia | Baixo, e a pessoa escolhe |
| **C. Intensa** | B + intersticial ao **sair** de telas secundárias (nunca no meio de registro ou treino) | Intersticial no máximo 1 a cada 10 minutos e 3 por dia | Médio/alto para idosos: toques acidentais e abandono |

**Comparação de receita** (ilustrativa; os valores reais dependem do país, do público e da época e só aparecem no painel do AdMob depois de semanas):

- Fórmula: `receita = impressões ÷ 1000 × eCPM` (eCPM = quanto se ganha a cada mil exibições).
- Ordem de grandeza típica, **a confirmar**: banner tem o menor eCPM (centavos de dólar no Brasil), recompensado e intersticial pagam dezenas de vezes mais por exibição, mas aparecem muito menos.
- Exemplo com 1.000 pessoas ativas por dia: banner com 5 exibições por pessoa = 5.000 impressões/dia. Recompensado aceito por 20% das pessoas, 1 vez = 200 impressões/dia. Com eCPM recompensado algumas dezenas de vezes maior, as **200 do recompensado podem render tanto quanto ou mais que as 5.000 dos banners**, com muito menos incômodo.
- Por isso a proposta B costuma equilibrar melhor receita e experiência. Antes da decisão, o Claude pode levantar referências públicas atuais de eCPM por formato no Brasil, deixando claro que são estimativas.

**Quem escolhe onde aparece:** no AdMob, o desenvolvedor coloca cada bloco de anúncio no código, e ele só aparece ali (banner onde o widget é posicionado, recompensado só quando o app chama). O Google escolhe **qual anúncio** mostrar, não **onde**. No painel do AdMob dá para bloquear categorias sensíveis (apostas, namoro e outras), limitar a classificação do conteúdo e bloquear anunciantes específicos. Cuidado de política: não colocar anúncio colado em botões, para evitar cliques acidentais. A implementação fica atrás de um interruptor (`TF_ADS=off|on`), medindo tamanho, desempenho e telas afetadas. Conta AdMob, pagamentos e impostos ficam com o autor.

## 5. Treino: pesquisa pesada para ter conteúdo de verdade

Situação: 73 metadados de consulta e **zero** programa, instrução, dose ou mídia liberados para prática. V1-015/016/044 estão bloqueadas por conteúdo. Já existem fontes pesquisadas em [catálogo de fontes](../conteudo/catalogo-fontes.md) e [opções de APIs de exercícios](../conteudo/opcoes-apis-exercicios.md): wger, free-exercise-db, ExerciseDB, MuscleWiki, ExRx, Otago, IMPACCT e outras. A nova pesquisa **parte delas** em vez de recomeçar.

**Atualização de 20/11:** o autor pediu para reformular o método. O foco passa a ser **programas completos, comprovados e criados por pessoas identificadas**, nunca gerados por IA. O método novo está em [método de pesquisa de treinos](metodo-pesquisa-treinos.md) e substitui as etapas abaixo, que ficam só como histórico do plano anterior.

Plano anterior:

1. **Consolidar o que já existe**: matriz "fonte × licença × idioma × tem instrução × tem mídia × uso comercial".
2. **Base de exercícios com direitos claros**:
   - MoveKit, se comprado: 588 exercícios com instruções, erros comuns, músculos, equipamento e dificuldade, em inglês.
   - wger: dados CC BY-SA por item.
   - free-exercise-db: Unlicense, mas a cadeia de direitos das imagens precisa ser conferida.
3. **Programas e doses**: diretrizes públicas que servem de base para programas próprios revisados.
   - Guia de Atividade Física para a População Brasileira (Ministério da Saúde).
   - Diretrizes da OMS de 2020.
   - Programas para idosos já catalogados (Otago, multicomponente). Conferir licença antes de adaptar.
4. **Proposta de programas** por contexto (casa, praça/parque, academia, idoso, cuidador em pausas), com dose, progressão e critérios de parada **como rascunho**.
5. **Tradução editorial** pt-BR das instruções (a licença da MoveKit permite editar). A tradução é revisada, não automática sem revisão.
6. **Revisão humana** por profissional de educação física (CREF) **antes** de liberar a prática. Isso depende do autor: quem revisa e como fica registrado.

O Claude faz as etapas 1 a 5 como pesquisa e rascunho. Nada vira programa liberado sem a etapa 6.

## 6. Demonstrações dos exercícios (MoveKit)

Conferido nas páginas oficiais em 20/11/2026 ([licença](https://movekit.com/licensing), [URLs assinadas](https://movekit.com/integrations/signed-download-urls), [API](https://movekit.com/integrations/exercise-animation-api)):

- **Não há GIF**, WebM nem Lottie. Cada exercício vem com **MP4 H.264** (2 a 15 s, cerca de 3,5 MB), **poster PNG** (primeiro quadro exato), poster de impressão e `metadata.json`/`metadata.csv` com **20 campos**: `slug`, `aliases`, `name`, `primaryMuscles`, `secondaryMuscles`, `equipment`, `implementsNeeded`, `movementPattern`, `difficulty`, `durationSeconds`, `tags`, `benefits`, `useCases`, `instructions`, `commonMistakes`, `shortDescription`, `longDescription`, `posterFile`, `videoFile`, `printPosterFile`.
- **Pacotes**: Starter 157 (vídeos 562 MB), Home 352 (1,25 GB), Gym 429 (1,51 GB), Complete 588 (2,04 GB). Preços não conferidos hoje.
- **API pública não existe** (lista de espera). O download hoje é manual, por link de 5 minutos na página de compras.
- **Licença**:
  - Permite apps comerciais, edição (inclusive com IA) e uso em anúncios.
  - **Proíbe** links públicos para os arquivos brutos, deixar o usuário baixá-los, redistribuição como biblioteca e treinar IA com eles.
  - A orientação é armazenamento **privado** + **URL assinada de curta duração** para usuário **autenticado**.
- **Existe amostra grátis** com 2 exercícios no mesmo formato do pacote.

### Quanto pesa (estimativa a partir dos números publicados, a medir com a amostra)

| Pacote | Exercícios | Vídeos | Posters | Total útil |
|---|---|---|---|---|
| Starter | 157 | 562 MB | 78 MB | ~0,64 GB |
| Home | 352 | 1,25 GB | 172 MB | ~1,42 GB |
| Gym | 429 | 1,51 GB | 219 MB | ~1,73 GB |
| Complete | 588 | 2,04 GB | 303 MB | ~2,34 GB |

Os posters de impressão (até 1,71 GB) não são necessários no app. Média por exercício: **~3,5 MB de vídeo + ~0,5 MB de poster**.

Como fazer sem pesar o APK nem gerar custo (a mesma lógica dos alimentos):

- **Nada de vídeo dentro do APK.** O APK já tem 139 MB e a licença não autoriza expor os arquivos brutos.
- Os **vídeos ficam no armazenamento privado** e o app baixa **só os exercícios do programa da pessoa**, quando ela abre. Um programa de 8 exercícios custa cerca de 28 MB de vídeo na primeira vez e depois sai do cache, se a MoveKit aceitar cache. Sem cache, os mesmos 28 MB a cada sessão.
- **Reduzir resolução e bitrate** (a licença permite editar): os clipes vêm em alta resolução, e numa tela de celular 480p–720p basta. Hipótese a medir: 3 a 5 vezes menor. Com isso o Complete ficaria abaixo de 1 GB no servidor e um programa em poucos MB.
- **Posters primeiro**: a lista mostra só o poster, e o vídeo carrega ao tocar no exercício.
- **Custo de servidor**: o Cloudflare R2 tem cota gratuita de armazenamento e não cobra saída de dados. O Complete reduzido cabe com folga. Conferir a cota vigente antes de escolher; Vercel Blob é alternativa. A geração da URL assinada roda na API Go atual.

Com a amostra de 2 exercícios dá para medir: tamanho original, tamanho reduzido, qualidade visual no celular, tempo até começar a tocar em 4G/Wi-Fi e total projetado para cada pacote.

### Ordem recomendada e onde armazenar (21/11)

Primeiro o treino, depois o armazenamento. O peso real depende de **quantos exercícios** os treinos aprovados usam, não do pacote inteiro:

1. **Pesquisa de treino, etapa 1 (idosos)** com cobertura MoveKit por exercício (C16/C23). Resultado: lista de exercícios necessários, por exemplo 40.
2. **Amostra grátis** (2 exercícios), que pode ser baixada em paralelo: mede o tamanho real por vídeo, original e reduzido (C21/C22).
3. **Conta**: exercícios necessários × tamanho medido = peso real. Projeção para as etapas seguintes.
4. **Escolher o pacote**: se Starter ou Home cobrirem os exercícios, não é preciso o Complete.
5. **Escolher o armazenamento** com o peso real em mãos:

| Opção | Ponto forte | O que conferir |
|---|---|---|
| **Cloudflare R2** (recomendado) | Cota gratuita de armazenamento e **sem cobrança de saída de dados**; compatível com S3 (a API Go gera o link assinado) | Cota vigente, cadastro com cartão |
| Vercel Blob (privado) | Já usamos a Vercel | Limites do plano Hobby para armazenamento e transferência |
| Google Cloud Storage | Mesmo ecossistema do login Google | Cota gratuita só em algumas regiões; saída de dados cobrada |
| Supabase Storage | Simples | Cota gratuita pequena |

Criar a conta é ação do autor (A14). O Claude prepara a integração e o script de envio.

### Por que não no GitHub, como os alimentos

Os alimentos vêm de dados abertos (TACO, USDA, Open Food Facts/ODbL), que podem ser redistribuídos publicamente. Os vídeos MoveKit **não**: a licença proíbe links públicos para os arquivos brutos e proíbe deixar o usuário baixá-los. Um Release público no GitHub seria exatamente isso. Um Release num repositório privado exigiria colocar um token dentro do app, o que também expõe os arquivos. O caminho continua sendo armazenamento privado + URL assinada gerada pela nossa API.

### Como atualizar treino sem baixar pacotes de novo

O app tem **API própria** (Go na Vercel + Neon). Quem não tem API é a MoveKit, e não precisamos da API dela: importamos os arquivos uma vez para o nosso armazenamento. O padrão usado por apps com conteúdo e mídia (manifesto + armazenamento/CDN + cache) separa duas coisas:

| Tipo | Tamanho | Onde fica | Como atualiza |
|---|---|---|---|
| **Conteúdo do treino** (programas, ordem, séries, textos, fontes, profissional) | KB | Banco Neon, servido pela API | O app sincroniza só o que mudou, como já faz com a alimentação. Mudar um treino **não** exige APK novo nem pacote |
| **Mídia** (vídeo e poster de cada exercício) | MB | Armazenamento privado, com chave estável e hash | O app baixa um vídeo **uma vez**, guarda em cache e só baixa de novo se o hash daquele vídeo mudar (raro: correção da MoveKit) |

O treino aponta para o exercício pelo `slug` e o exercício aponta para a mídia por chave e hash. Trocar o treino muda só a lista de `slug`s: vídeos já em cache são reaproveitados e só os exercícios novos são baixados. Isso depende de a MoveKit aceitar cache no aparelho (A12). Sem cache, o vídeo é transmitido a cada vez, mas o treino continua atualizando sem pacote.

A mesma lógica pode servir depois para atualizar o catálogo de alimentos aos poucos, em vez de pacotes inteiros.

Consequências para o código, que entram no [plano MoveKit](../conteudo/plano-integracao-midias-movekit.md) quando os arquivos reais chegarem:

- O player é de **vídeo em loop, mudo**, com poster (não um componente de GIF).
- A API Go precisa gerar URL assinada a partir de um bucket privado (R2/S3 ou Vercel Blob) e guardar só a **chave**, nunca a URL.
- **Visitante sem login** possivelmente não pode ver os vídeos (a licença fala em usuários autenticados). Confirmar com a MoveKit.
- **Vídeos embutidos no APK ou em cache offline**: a licença não trata do assunto explicitamente, e o APK pode ser extraído. Perguntar à MoveKit antes. O cache offline fica pendente.
- Os metadados em inglês precisam de mapeamento para o catálogo atual e de tradução revisada.

## Resumo: quem inicia o quê

**O Claude pode iniciar sem o autor:**

- Auditoria técnica Play (iniciada)
- Geração de AAB
- Inventário de testes
- `integration_test`
- Testes golden
- Carga e estresse local
- Workflow de CI Android
- Rascunhos de ficha, Data safety e página de exclusão
- Proposta do repositório público de distribuição
- Pesquisa de treino pelo [novo método](metodo-pesquisa-treinos.md) (etapas 1 a 5)
- Pesquisa de voz e foto
- Preparar o app para a amostra MoveKit (player, importador e medição)
- Área reservada para banner e, por último, o interruptor de anúncios

**Depende do autor:**

- Conta Play Console
- `applicationId` e novo OAuth
- Decisão e criação dos repositórios
- Testadores do teste fechado
- Formato dos anúncios (já decidido que haverá) e conta AdMob
- Baixar a amostra grátis MoveKit quando o app estiver pronto para ela
- Compra MoveKit, download e conta de armazenamento
- Perguntas à MoveKit sobre offline e visitante
- Revisor de treino (CREF)
- Revisão jurídica
- Aprovação de textos e imagens da loja
- Autorização para carga contra o ambiente hospedado
- Decisões do APK simples
