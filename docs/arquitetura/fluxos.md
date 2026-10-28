# Telas, chamadas e navegação

A [documentação dinâmica](README.md) tem mapas de telas, chamadas HTTP, banco e arquitetura proposta no próprio repositório, sem servidor de leitura. Referências de construtor/import são evidência estática; não demonstram clique bem-sucedido ou condição de navegação.

## Configuração047 integrada em27/10

Conta e Planos abrem o mesmo serviço privado, composto por identidade.555mensagens/idioma; configuração em quatro etapas preserva respostas em memória e pede confirmação antes do descarte. API0.7.0/29operações e schema12/27tabelas ativos localmente; APKdebug0.4.0+22 instalado. [Detalhes e aceite pendente](../execucao/v1/configuracao-treino-047.md). Checkpoints abaixo são históricos.

```mermaid
flowchart TD
    account["Conta / Configuração de treino"] --> load["GET próprio: versão ou ausência"]
    plans["Planos / Criar meu plano"] --> load
    load --> places["1. Locais e contexto"]
    places --> resources["2. Recursos: declarados / nenhum / desconhecidos"]
    resources --> time["3. Disponibilidade e fuso"]
    time --> review["4. Revisão final / voltar para corrigir"]
    review --> confirm["PUT completo e revisado"]
    confirm --> saved["Versão confirmada na conta"]
    confirm --> uncertain["Resposta incerta: repetir mesmo corpo/chave"]
    confirm --> conflict["Conflito: preservar e oferecer recarregar"]
    places --> leave["Sair alterado: continuar editando ou descartar"]
    time --> leave
    saved -. "015 ainda pendente" .-> selection["Seleção permitida, sem geração IA"]
```

## Fluxo atual lido no Flutter

Checkpoint24/10: frontend07–12 nos fluxos disponíveis, Androiddebug0.3.0+13. Biblioteca/detalhe, composição/cadastro/histórico/subtotais/consumo, privacidade eajuda usam primitives atuais; proteção de rascunho/envio/resposta incerta e busca particular independente.101testesFlutter/analyze0issues. [Critérios e gates](../execucao/v1/frontend-fidelidade-figma.md). Configuração persistida, treino/atividade e demais funções sem contrato/conteúdo continuam indisponíveis; referênciasFigma faltantes e execução nativa iOS pendentes. Pontos01–06, identidade/temas/rolagem e dados reais preservados.

```mermaid
flowchart LR
  launch["Splash TF nativo"] --> appearance["Aparência local: sistema / claro / escuro"]
  appearance --> gate["AuthGate: restaurar sessão com limite"]
  shell --> scroll["Rolagem por plataforma: Android sem esticar; iOS padrão"]
  gate --> entry["Entrada / retentativa sem apagar sessão por rede"]
  gate --> shell["ProductShell por identidade"]
  shell --> today["Hoje: datas, estados e resumo Go real"]
  shell --> tabs["Planos / Atividade / Diário / Evolução"]
  today --> day["Diário alimentar pela data escolhida"]
  shell --> profile["Perfil"]
  profile --> appearance
  profile --> privacy["Exportação / exclusão / sessão"]
  entry --> public["Biblioteca e composição alimentar públicas"]
  day --> nutrition["Histórico / porção / revisão reais"]
  nutrition --> draft["Guarda de rascunho / envio / resposta incerta"]
  nutrition --> ownSearch["Busca particular independente do resumo"]
  profile --> help["Ajuda e disponibilidade sem simulação"]
```

## Composição Flutter implementada em 25/10

TrainForgeApp recebe AppDependencies ou compõe as fábricas de produção uma vez na raiz. O escopo fica acima do Navigator, alcançando também as rotas abertas depois. As fábricas criam os serviços sob demanda; dados privados são vinculados à conta, sem singleton de estado do diário. [Verificação](../execucao/v1/frontend-composition-verification.json): rotas públicas/tema, reutilização do serviço e troca de identidade;103 testes aprovados/analyze sem issues. Segundo incremento:estado emNutritionController eAPP_ENV por ambiente,108testes/analyze0issues.021encerrada no seu recorte; [critérios](../execucao/v1/frontend-state-verification.json). Entrada/foco/validação dos formulários permanecem naUI, comrepository injetado.

```mermaid
flowchart LR
  root["TrainForgeApp"] --> scope["AppDependencyScope"]
  prod["productionDependencies: fábricas lazy"] --> scope
  injected["Dependências isoladas nos testes"] --> scope
  scope --> gate["AuthGate e controller de sessão"]
  scope --> public["Catálogo / alimentos / privacidade"]
  gate --> shell["ProductShell por identidade"]
  scope --> bound["NutritionRepository por conta"]
  bound --> daily["DailySummaryController: Hoje / Diário"]
  bound --> reads["NutritionController: consultas / busca / paginação"]
  reads --> diary["NutritionPage: apresentação e navegação"]
  bound --> forms["Formulários: campos e guardas visuais"]
  shell --> daily
  shell --> diary
  gate --> change["Troca de conta remove rotas privadas"]
  change --> bound
```

### Configuração por ambiente

APP_ENV aceita development, staging ou production; emdebug o default édevelopment e emprofile/release éproduction. API_BASE_URL continua definido por dart-define, com o defaultlocal127.0.0.1:8082 preservado para desenvolvimento. HTTP só é permitido parahosts locais exatos emdevelopment/debug; staging/production eprofile/release exigemHTTPS. URL não aceita credenciais,query,fragmento,pathextra ouhostvazio. Nenhum endpoint externo foi criado; ambiente configurado não implica hospedagem. IDsOAuth permanecem públicos separados de segredos.

## Idioma e preferência local — V1-048 parcial

A raiz carrega idioma e aparência em paralelo antes de restaurar a sessão. LocaleScope mantém a preferência local; MaterialApp usa os recursos ARB tipados e delegates oficiais. A preferência não modifica a conta ou o banco. A resolução respeita pt-BR/pt-PT/en/es, usa o idioma do aparelho quando selecionado e cai para pt-BR quando nenhum idioma é suportado.

```mermaid
flowchart LR
  launch["TrainForgeApp"] --> settings["Aparência e idioma em paralelo"]
  settings --> locale["LocaleController: system / pt-BR / pt-PT / en / es"]
  locale --> device["Preferência local Android / iOS"]
  locale --> ui["MaterialApp locale e delegates"]
  resources["ARB versionado"] --> typed["flutter gen-l10n"]
  typed --> ui
  settings --> gate["AuthGate preservado"]
  ui --> controls["Entrada / perfil / aparência / navegação: 79 mensagens"]
  original["Fontes e nomes alimentares originais"] --> unchanged["Sem tradução automática; camada revisada ainda pendente"]
```

[Recibo048](../execucao/v1/frontend-localization-verification.json) separa infraestrutura e mensagens migradas do restante da interface. Helpers de datas/decimal estão testados, mas os demais fluxos/plurais ainda precisam migrar. A API continua sem locale/alias e sem novo endpoint; nomes revisados exigirão contrato aditivo, versão, revisão, direitos e testes próprios. Não enviar parâmetros que a API atual rejeita. iOS não executado nativamente.

## Privacidade implementada em23/10

Política pública sem login. Conta conectada abre exportação própria por seção e exclusão confirmada. Os controles privados e o aceite local comGoogle foram validados em23/10; os recibos históricos distinguem login, exportação e exclusão autorizada.

```mermaid
flowchart LR
  entrada[Entrada] --> politica[Política pública]
  conta[Conta conectada] --> dados[Meus dados e privacidade]
  dados --> exportar[Exportar seção própria]
  exportar --> copiar[Copiar página por ação explícita]
  dados --> limites[Ler limites de backups]
  limites --> recente[Sessão recente e intenção temporária]
  recente --> frase[Digitar frase exata]
  frase --> excluir[Exclusão transacional e revogação]
  excluir --> limpar[Limpeza local condicional]
  antigo[Restore separado offline] --> registro[Aplicar exclusões atuais]
  registro --> corte[Revalidar corte antes de promover]
```
