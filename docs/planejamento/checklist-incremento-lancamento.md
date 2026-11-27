# Checklist do incremento de lançamento

Criado em **20/11/2026**. Contexto e motivos estão no [plano do incremento](plano-incremento-lancamento.md). Marcar `[x]` só com evidência registrada no item (comando, arquivo, recibo ou commit). `C` = o Claude inicia sozinho; `A` = depende do autor.

## Checklist

### Play Store
- [x] **C1** Auditoria técnica de prontidão Play no código (20/11)
- [ ] **C2** Gerar AAB assinado e medir o tamanho por ABI
- [ ] **C3** Rascunhar a ficha da loja, o Data safety e a declaração de app de saúde
- [ ] **C4** Página web de exclusão de conta + Termos/Privacidade prontos para hospedar
- [ ] **A1** Criar a conta Play Console
- [ ] **A2** Escolher o `applicationId` definitivo e executar a [melhoria do OAuth](melhoria-identidade-google.md)
- [ ] **A3** Aprovar ícone, screenshots e textos da loja
- [ ] **A4** Recrutar testadores e rodar o teste fechado pelo período exigido
- [ ] **A5** Enviar para revisão e publicar em produção

### Testes, CI/CD e estresse
- [ ] **C5** Inventário de testes × funcionalidades × lacunas
- [ ] **C6** Corrigir o teste nativo do scanner EAN
- [ ] **C7** `integration_test` das jornadas principais no emulador
- [ ] **C8** Testes golden das telas principais
- [ ] **C9** Carga e estresse da API em ambiente local descartável
- [ ] **C10** Workflow de CI que gera AAB sem segredos e roda análise e testes
- [ ] **C11** Varredura de dependências do app (OSV, `pub outdated`) e análise do APK
- [ ] **A6** Autorizar (ou não) carga contra Vercel/Neon
- [ ] **A7** Criar a conta de serviço da Play e o segredo no GitHub para publicação automática (CD)

### Repositório privado
- [x] **A8a** Direção: dois repositórios, código privado e distribuição pública (autor, 20/11)
- [ ] **C12** Propor a estrutura do repositório público de distribuição (Pages + Releases) e a migração dos links
- [x] **A8b** Nome do repositório público: `trainforge-app` (autor, 21/11)
- [ ] **A8** Criar o repositório público `trainforge-app` e, depois de C13, tornar privado o de código
- [ ] **C13** Atualizar links, QR, `CATALOG_PACKS_URL` e o script de publicação, e conferir que tudo abre

### Anúncios
- [x] **A9a** Decisão: o app terá anúncios, sem mensalidade (autor, 20/11)
- [ ] **A9b** (segundo plano) Decidir onde, quanto e com que frequência, a partir das propostas A/B/C e da comparação de receita do [plano](plano-incremento-lancamento.md#4-anúncios)
- [ ] **C14a** Reservar de fato a área do banner no APK (rodapé das telas secundárias)
- [ ] **C14b** Reservar a mesma área no Figma (conferir antes a cota MCP do plano Starter)
- [ ] **A9** Escolher o formato (banner / recompensado / ambos), por último
- [ ] **C14** Interruptor `TF_ADS`, telas permitidas, consentimento, Privacidade e Data safety (por último)
- [ ] **A10** Criar a conta AdMob, configurar pagamentos e impostos

### Treino
- [x] **C15a** Novo [método de pesquisa de treinos](metodo-pesquisa-treinos.md): base própria por camadas, origem por campo, profissional responsável, sem IA (20/11)
- [x] **C15** Protocolo de busca e estrutura [`docs/conteudo/pesquisa-treinos/`](../conteudo/pesquisa-treinos/README.md) (21/11)
- [ ] **C16** Etapa 1 (idosos): buscar, triar e extrair exercícios, segurança, dose, progressão e programas
  - [x] Buscas PubMed registradas (6 perguntas, 904 resultados) e fase 1 dos 103 primeiros, com 23 candidatos (21/11)
  - [x] MS 2021 lido (regras de frequência); OMS 2020 e diretrizes mundiais 2022 dispensáveis para a cobertura
  - [ ] Fase 2 (texto completo) da prioridade 1, começando por Otago e Vivifrail
  - [ ] Fichas por camada em `fichas/`
  - [x] [Biblioteca v1](../conteudo/pesquisa-treinos/biblioteca.json): 96 exercícios e 16 treinos válidos pela regra absoluta (NHS, Otago, NIA), 21/11
  - [x] Biblioteca consolidada: 149 exercícios e 42 treinos (21/11); após o debate, 1 autônomo, 29 com profissional, 11 fora
  - [ ] Extração por exercício pendente: UFPR (103), AGUEDA, Walker fase força, Krist, ENJOY
- [x] **C23** Cobertura MoveKit pela lista pública (21/11): academia boa; casa, praça e pausa fracas; nenhum vídeo baixado
- [x] **C26** Debate Claude × Codex sobre a biblioteca ([registro](../conteudo/pesquisa-treinos/debate-claude-codex-20261121.md)), 21/11: veredito "não pronto"; ajustes estruturais aplicados
- [ ] **C17** Extrair agendas, doses, critério de entrada, contraindicações e acompanhamento exigido por programa
- [x] **A16** Decidido pelo autor (21/11): modo único, composição coerente permitida, frequência livre de 1 a 7 dias (sugestão 3, recomendação 3–5)
- [ ] **C27** Termos de Uso v1.1 com a cláusula 2.1 de treinos ([minuta](../conteudo/pesquisa-treinos/debate-claude-codex-20261121.md#minuta-de-cláusula-para-os-termos-de-uso-versão-11-junto-com-a-liberação-dos-treinos)); publicar junto com a liberação dos treinos, com novo aceite
- [x] **C29** Inventário de sessões por lugar e nível (meta 108) e debate rodada 4, 21/11: 117 sessões, praça com 6 por nível, nenhuma extraída por completo
- [x] **C30** Extração das sessões (21/11): após a rodada 5 do debate, 90 de 133 prontas
- [x] **C33** Lacunas da rodada 5 (21/11): combinação de modalidades por fontes profissionais, 16 sessões novas (caminhada NIA, pausas em pé, casa sentado/intermediário, ATI B2), rodada 6 do Codex "suficiente com ajustes pontuais"; 106 prontas, meta 9 em 6 de 12 células
- [x] **C34** Lacunas da rodada 6 (21/11): dose de máquinas pela NSCA 2019, 15 sessões novas (academia NSCA, Otago equilíbrio, exercise snacking, sentado I), opção sem peso, modalidades complementares; rodada 7 do Codex "suficiente com ajustes pontuais"; 120 prontas, meta 9 nas 12 células
- [ ] **C36** Variedade restante (não bloqueia mídia): instrução por postura do Baduanjin, mais sessões sem peso por célula (hoje casa 4/7/5/3, praça 3/2/3, pausa 4/7), mais ATI (5/4/5), conferir candidatas (LiFE, Tai Ji Quan, dança, Square Stepping, Lian Gong, Pilates)
- [x] **C35** Combinação da semana (21/11): campo opcional `weeklyMix` (só força, + caminhada, + corpo e mente, completo, equilíbrio e mobilidade sem peso) na API Go, migração 00018 (versões antigas continuam válidas), Swagger e tela Flutter no passo de disponibilidade e na revisão; testes Go, Flutter e Python verdes. Figma: tela "26 · Combinar a semana (C35)" criada no Figma Desktop por plugin local (`docs/design/c35-plugin/`), porque o MCP atingiu o limite do plano Starter
- [ ] **C38** (autor) Mídia dos treinos: testar as amostras (app de teste TF Amostras com MoveKit e RepDB gerado em 21/11, fora do Git em `.local/amostras-midia/`) e comprar dentro de R$ 720 conforme a revisão de 21/11 em `docs/conteudo/pesquisa-treinos/midia-orcamento-20261121.md` (MoveKit Gym R$ 454 até 30/11 + RepDB grátis + gravação própria de ATI/Baduanjin + reserva GymVisual)
- [x] **C39** CI (21/11): `legal_consents` (migração 17) entrou no inventário de privacidade (exportação `legalConsents`, exclusão em cascata); integração SQL e restore descartável voltaram a passar em `86986c8`, validando também a migração 00018
- [x] **C37** Ajustes de app (21/11): tema claro por padrão em instalação nova (escuro e sistema continuam opcionais); barra de navegação do Android transparente na abertura animada (sem a faixa clara sobre o verde); menu inferior com segurar e arrastar para trocar de aba, com destaque seguindo o dedo
- [ ] **C31** Na configuração, ao escolher "casa": pergunta simples e opcional ("Você tem elástico, step ou caneleira? Se não tiver, tudo bem: é só para personalizar seu treino em casa"). A resposta libera os programas de casa com material; sem resposta, só treinos com material doméstico (decisão do autor, 21/11). Usa o campo de recursos que a configuração já tem
- [ ] **C32** Incluir essa tela e a opção no app (Flutter) e no Figma (pendência registrada pelo autor, 21/11)
- [ ] **C28** Ajustar composições: dividir PRG-12 em A/B e mostrar a recomendação de profissional da fonte na tela do treino
- [ ] **C25** Integrar a biblioteca ao app: níveis N1–N4 na configuração, escolha do treino por lugar/nível/dias e tela de fontes
- [ ] Etapas seguintes, uma por vez: cuidadores nas pausas → em casa → praça/parque → academia
- [x] **A11** Revisão própria dispensada pelo autor (21/11): vale a [regra absoluta](metodo-pesquisa-treinos.md#regra-absoluta-de-validade-decisão-do-autor-21112026) — sem IA, autor profissional identificado, benefício declarado, fonte e autor registrados

### Demonstrações MoveKit
- [x] **C21a** Estimativa de peso por pacote e estratégia sem vídeo no APK (20/11, [plano](plano-incremento-lancamento.md#quanto-pesa-estimativa-a-partir-dos-números-publicados-a-medir-com-a-amostra))
- [ ] **C21** Preparar o app para a amostra: player de vídeo em loop com poster, importador de `metadata.json` e script de medição (tamanho, redução, tempo até tocar)
- [ ] **A12** Perguntar à MoveKit sobre cache offline/APK e sobre visitante sem login
- [ ] **A13a** Baixar a amostra grátis (2 exercícios) assim que C21 for avisado como pronto
- [ ] **C22** Medir a amostra no APK e projetar o total por pacote (original × reduzido)
- [ ] **C24** Desenhar conteúdo de treino pela API (sincronização incremental) + mídia por chave/hash com cache
- [ ] **A13** Escolher o pacote, comprar e baixar
- [ ] **A14** Criar o armazenamento privado (R2/S3/Vercel Blob)
- [ ] **C18** Executar o [plano MoveKit](../conteudo/plano-integracao-midias-movekit.md) a partir dos arquivos reais

### Planos anteriores
- [ ] **C19** [Pesquisa de voz e foto](pesquisa-registro-voz-e-foto.md) — decisão fechada em 22/11, só IA discriminativa: voz pelo motor de fala do sistema (offline primeiro, online coberto pelos termos) + busca própria no catálogo com 5 opções; foto por modelo aluno próprio (~4–8 MB, >300 alimentos, destilado do SigLIP 2 no PC, bases públicas) + aprendizado local dos pratos da pessoa; em 22–23/11 foto treinada e retreinada com professor ajustado (370 alimentos, int8 4,4 MB; 1ª sugestão no prato 87,1% e algum acerto nas 3 primeiras 95,9% no Nutrition5k; pratos brasileiros fora do treino 29,6% / 53,7% por falta de fotos), motor LiteRT do Google Play Services (+6,1 MB no APK único) e botão "Reconhecer por foto" na tela de consumo; voz implementada em 23/11 (0.5.6: reconhecimento de fala do celular + tradutor para os 370 alimentos, 111/111 nas frases de teste); faltam teste no aparelho do autor e fotos reais brasileiras
- [ ] **A15** Decidir o que fica no [APK simples](melhoria-apk-simplificado.md)
- [ ] **C20** [Pacotes regionais](melhoria-pacotes-regionais.md)

### Teste no celular do autor (0.5.6, 23/11)
- [ ] **C40** [Teste ao vivo por Wi-Fi](../aprendizado/teste-ao-vivo-wifi.md): autor pareia o celular; agente assina o debug com a chave do release e inicia o `flutter run` com hot reload
- [ ] **C41** Voz: aproveitar a quantidade falada com unidade clara (g, ml, litro) e abrir o formulário preenchido para conferir (aprovado pelo autor em 23/11)
- [ ] **C42** Treinos prontos: explicar cada nível com o texto da pesquisa e ajudar a escolher lugar e nível ("Não sei qual escolher", 2–3 perguntas como ponto de partida, aprovado em 23/11); mostrar o critério de entrada da fonte quando houver
- [ ] **C43** [Hidratação](melhoria-hidratacao.md): registro de água com um toque reaproveitando o consumo de "Água" do catálogo; decisões do autor listadas no plano
- [ ] **C44** Redesenho didático para pessoas mais velhas e leigas (telas iniciais e principais): menos listas, uma ação principal por tela, linguagem simples; feito ao vivo depois do C40; estrutura aprovada em 27/11: [navegação em 5 posições e Hoje em dois cenários](melhoria-navegacao-e-inicio.md)
- [ ] **A17** (autor, até 30/11) Testar a amostra de mídia e decidir a compra MoveKit Home ou Gym ([revisão de 23/11](../conteudo/pesquisa-treinos/midia-orcamento-20261121.md#revisão-de-2311-decisão-para-comprar-até-3011))

---

## Como fazer cada item

### C1. Auditoria técnica de prontidão Play — concluída em 20/11/2026
Verificações feitas no `build/app/outputs/flutter-apk/app-release.apk` (0.5.4+34) e na configuração Android:
- SDK alvo e de compilação: 36 em `C:\Users\richa\flutter\packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt`; mínimo efetivo 24. **OK.**
- Páginas de 16 KB: `zipalign -c -P 16 -v 4` (build-tools 35.0.1) com "Verification succesful", e leitura dos cabeçalhos ELF com todos os `PT_LOAD` das libs arm64/x86_64 ≥ 16384. **OK.**
- `applicationId`/`namespace` = `com.example.trainforge`. **Bloqueio**, resolvido por A2.
- O script de release gera só APK. **Lacuna**, resolvida por C2.
- Exclusão de conta dentro do app existe; falta o link web. **Lacuna**, resolvida por C4.
- Permissões `INTERNET` e `CAMERA`, sem `AD_ID`; `allowBackup=false`. Declarar câmera no Data safety (C3).
- Limite: não foi conferida a exigência de SDK alvo vigente no Console nem regras novas de política. Conferir no Console em A1/A5.

### C2. AAB e tamanho por ABI
1. Ler `tools/preparar_release_android.py` e acrescentar a opção `--bundle`, que roda `flutter build appbundle --release` com a mesma configuração e conferências (registrador de plugins, catálogo, certificado).
2. Medir com `bundletool build-apks --connected-device`/`get-size total` (bundletool local, sem conta).
3. Registrar o tamanho por ABI no recibo. Se passar do limite de download da Play, avaliar o catálogo por Play Asset Delivery ou o [APK simples](melhoria-apk-simplificado.md).
4. Rodar os testes Python do script. Commit separado.

### C3. Ficha, Data safety e declaração de saúde
1. Escrever `docs/distribuicao/play-store/ficha.md`: nome, descrição curta (80 caracteres) e longa (até 4.000) em pt-BR, categoria e contato.
2. Tabela de Data safety a partir do código real: conta Google (e-mail, nome), dados de saúde (refeições, consumo), fotos (câmera para código de barras), criptografia em trânsito, exclusão disponível e o que não é compartilhado.
3. Declaração de app de saúde: o app não é dispositivo médico e não faz diagnóstico (conferir com os Termos).
4. Roteiro de 4 a 8 screenshots, com dados de conta de teste e nunca dados reais.

### C4. Página de exclusão de conta
1. Escrever uma página estática (`site/excluir-conta.html` ou Markdown para Pages): como excluir pelo app e como pedir por e-mail, quais dados são apagados e em quanto tempo, conforme o que a API já faz.
2. Conferir contra o código de `privacy/` e da API de exclusão.
3. A hospedagem depende de A8.

### C5. Inventário de testes
1. Listar `test/`, `integration_test/`, `services/api/**/_test.go` e `tools/test_*.py`.
2. Para cada funcionalidade de `lib/features/`, marcar unidade, widget, integração, contrato, nativo e manual.
3. Saída: `docs/execucao/v1/inventario-testes.md` com as lacunas priorizadas, que alimenta C6 a C11.

### C6. Scanner EAN
1. Reproduzir a falha do teste nativo amplo no emulador (leitura da imagem EAN sintética).
2. Investigar a causa (imagem, resolução, formato aceito pelo ML Kit/barhopper) antes de mexer.
3. Corrigir e validar no emulador e no celular real.

### C7. `integration_test`
1. Criar `integration_test/` com jornadas de visitante, busca, refeição, offline com retorno da rede e exclusão.
2. Rodar no AVD isolado (não no aparelho do autor) com `flutter test integration_test`.
3. Não rodar em paralelo com `avaliar_android.py prepare` (regra do projeto).

### C8. Testes golden
1. Escolher 6 a 10 telas. Gerar goldens em 360×800 e 800×1280, claro e escuro, com fonte embutida.
2. Garantir determinismo (sem relógio e sem animação).

### C9. Carga e estresse local
1. Subir API + Postgres descartável (`tools/ambiente.py start` ou CI SQL). **Nunca** o banco com dados reais.
2. Criar cenários com `vegeta`: busca de alimentos, registro de refeição, sincronização e login simulado. Rampas de 10, 50, 100 e 200 req/s, 5 minutos cada, mais um teste de resistência de 30 minutos.
3. Medir p50/p95/p99, erros, conexões do pool pgx e uso de CPU e memória.
4. Registrar em `docs/execucao/v1/carga-<data>.json` e propor limites. Contra Vercel/Neon, só depois de A6.

### C10. CI Android
1. Workflow `android-release.yml`: Java 21, Flutter fixo, `flutter analyze`, testes, `flutter build appbundle` com chave de teste gerada no job, e tamanho como artefato.
2. Disparar em `workflow_dispatch` e em tags, para economizar minutos (importante se o repositório ficar privado).

### C11. Dependências e APK
1. `flutter pub outdated` e consulta OSV das versões travadas. `govulncheck` já existe.
2. Opcional: MobSF local no APK (sem enviar a serviço externo).

### C12–C13. Repositório público de distribuição
1. Propor a estrutura: `docs/` do Pages (termos, privacidade, exclusão, página de download com QR) e Releases (APK e `catalog-packs-v1`).
2. Depois de A8: atualizar `AppConfig`, `CATALOG_PACKS_URL`, `tools/publicar_release_android.py`, os documentos de distribuição e o QR.
3. Conferir cada link com download completo e SHA antes de tornar o código privado.

### C14a. Área reservada para banner
1. Nas telas secundárias (busca, listas, histórico), criar um `Scaffold` com um slot de rodapé de altura fixa, vazio enquanto `TF_ADS=off`.
2. Conferir em 360×800 que o conteúdo principal e o teclado não ficam encobertos.
3. Altura padrão do banner adaptativo (cerca de 50–60 dp em celular); conferir também em tablet.
4. Pode ser feito antes do APK simples; se o APK simples vier antes, aproveitar a mesma revisão de telas.

### C14b. Área do banner no Figma
1. Conferir se a cota MCP do Figma voltou (limite atingido em 19/11).
2. Nos frames das telas secundárias, acrescentar o rodapé reservado com a mesma altura do APK e anotação "Anúncio (reservado)".
3. Se a cota não permitir, registrar a pendência e fazer a alteração manualmente com o autor.

### C14. Anúncios (por último)
1. Interruptor `TF_ADS` em `lib/core/config`, desligado por padrão.
2. Lista explícita das telas permitidas. Bloquear registro, sessão de treino, termos, privacidade e entrada.
3. Consentimento (UMP), `AD_ID`, atualização da Privacidade e do Data safety.
4. Medir tamanho e desempenho. Testes que provem a ausência de anúncio nas telas bloqueadas.

### C15–C17 e C23. Treino (método de 20/11)
1. Seguir o [método](metodo-pesquisa-treinos.md): pergunta PICO → busca registrada (PubMed/Europe PMC/SciELO/órgãos públicos) → triagem em duas fases → fichas por camada (exercício, segurança, dose, progressão, programa) com a origem de cada campo.
2. Reaproveitar o que `docs/conteudo/catalogo-fontes.md` já registrou (Otago, IMPACCT, wger e outras), sem recomeçar.
3. Juntar fontes diferentes quando fizer sentido, sempre com a origem por campo. Rejeitar o que não disser de onde veio.
4. Para cada exercício, registrar a cobertura MoveKit (`provavel`/`nao_encontrado`) pela lista pública de nomes.
5. Treinos com status `aguarda_revisao` e pacote de revisão com as fontes lado a lado. Nada liberado sem A11.

### C24. Conteúdo pela API e mídia em cache
1. Modelar programa, sessão e exercício no Postgres com versão; o exercício referencia a mídia por `slug` + chave + hash.
2. Rota de sincronização incremental (só o que mudou desde a última versão), reaproveitando o padrão da alimentação offline.
3. Cliente: cache de mídia por hash, limite de espaço e limpeza do que não é mais usado.
4. Só implementar depois de C22 e da resposta da MoveKit sobre cache (A12).

### C21. Preparar o app para a amostra MoveKit
1. Modelo Dart e importador para os 20 campos publicados de `metadata.json`, testados com um fixture próprio que segue o exemplo público. Validar contra a amostra real em C22.
2. Componente de demonstração: vídeo mudo em loop, poster como primeiro quadro e texto alternativo com o nome. Respeitar "reduzir movimento" (mostrar só o poster com botão de tocar).
3. Fonte de mídia por interface: em desenvolvimento, arquivo local; depois, URL assinada da API. Sem URL fixa no app.
4. Script `tools/medir_midia_movekit.py`: tamanho, duração e resolução (ffprobe), versões reduzidas (480p/720p) e projeção por pacote.
5. Avisar o autor para baixar a amostra (A13a).

### C22. Medir a amostra
1. Colocar a amostra em `.local/movekit/amostra/` (fora do Git, conforme a licença).
2. Rodar a medição e testar no emulador e no celular: tempo até tocar, qualidade em 480p e 720p, uso de memória.
3. Registrar o recibo e a projeção de cada pacote (servidor, por programa, por sessão).

### C18. MoveKit
Seguir as etapas do [plano MoveKit](../conteudo/plano-integracao-midias-movekit.md), com os fatos de 20/11 do [plano do incremento](plano-incremento-lancamento.md#6-demonstrações-dos-exercícios-movekit): MP4 + poster (sem GIF), 20 campos de metadados, bucket privado e URL assinada.

### Itens do autor (A1–A15)
- **A1**: criar a conta de desenvolvedor no Play Console (pessoal ou organização), pagar a taxa e verificar a identidade.
- **A2**: escolher o identificador (ex.: `br.com.trainforge.app`) e seguir os 6 passos da [melhoria de identidade](melhoria-identidade-google.md).
- **A4**: convidar testadores por e-mail na trilha de teste fechado. Conferir no Console o número e o período mínimos vigentes.
- **A6**: dizer se a carga contra Vercel/Neon é aceitável, com qual teto e em qual horário.
- **A9**: escolher entre as 4 opções de anúncios do plano.
- **A12**: enviar à MoveKit as perguntas sobre (a) vídeos dentro do APK ou em cache offline no aparelho e (b) exibição para quem usa sem login.
- **A13/A14**: compra e criação de contas são ações suas. O Claude não compra, não cria conta e não insere pagamento.
