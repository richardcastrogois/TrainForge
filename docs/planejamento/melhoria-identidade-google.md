# Melhoria: desvincular o login do projeto "Bootcamp"

Registrada em **19/11/2026** a pedido do autor, para fazer junto com os [pacotes regionais](melhoria-pacotes-regionais.md).

## Situação hoje

- O código do app e da API **não** cita "bootcamp" (conferido com `git grep`). O vínculo está fora do código:
  - Projeto Google Cloud **`bootcamp-treinos-ia`** ("Treinos de Bootcamp IA"), que guarda os clientes OAuth (Web e Android release `TrainForge avaliação release`) e o client ID usado no APK (`.local/android-release/release-config.json`) e na Vercel (`TF_GOOGLE_SERVER_CLIENT_ID`).
  - Domínios autorizados herdados do backend antigo: `bootcamp-treinos-api-snza.onrender.com` e `rcg-tech.com.br`.
  - Identificador Android ainda é `com.example.trainforge` (padrão de exemplo; a Play Store não aceita `com.example`).
- Registros históricos que citam o projeto (`docs/execucao/v1/oauth-release-verification.json`, `docs/historico/README.md`, recibo Graphify de 21/10) ficam como histórico.

## O que fazer

1. Criar um projeto Google Cloud **`trainforge`** (ou renomear a exibição do atual; o ID `bootcamp-treinos-ia` não muda) e, nele, a tela de consentimento externa com nome TrainForge e links de Termos/Privacidade.
2. Definir o identificador definitivo do app (ex.: `br.com.trainforge.app`) **antes** da Play Store: muda `applicationId`/namespace Android e bundle iOS, e o app passa a ser outro para o celular (quem tem o 0.5.x instala de novo).
3. Criar clientes OAuth novos: Web (audiência da API) e Android com o SHA-1 de release `24:EF:27:3C:…:17:6D` e o novo pacote.
4. Atualizar `TF_GOOGLE_SERVER_CLIENT_ID` na Vercel e `GOOGLE_SERVER_CLIENT_ID` em `.local/android-release/release-config.json`; gerar e publicar novo APK.
5. Remover os domínios autorizados antigos (`onrender.com`, `rcg-tech.com.br`) depois que o login novo funcionar.
6. Publicar a tela de consentimento (sem logo, só escopos básicos, sem verificação) e testar login no celular.

**Cuidado:** contas já criadas são identificadas pelo emissor e `sub` do Google, que não mudam com o projeto OAuth; conferir em teste antes de remover o projeto antigo. Estimativa: 1 a 2 horas, incluindo APK novo.
