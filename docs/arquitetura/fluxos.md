# Telas, chamadas e navegação

A [documentação dinâmica](README.md) tem mapas de telas, chamadas HTTP, banco e arquitetura proposta no próprio repositório, sem servidor de leitura. Referências de construtor/import são evidência estática; não demonstram clique bem-sucedido ou condição de navegação.

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

TrainForgeApp recebe AppDependencies ou compõe as fábricas de produção uma vez na raiz. O escopo fica acima do Navigator, alcançando também as rotas abertas depois. As fábricas criam os serviços sob demanda; dados privados são vinculados à conta, sem singleton de estado do diário. [Verificação](../execucao/v1/frontend-composition-verification.json): rotas públicas/tema, reutilização do serviço e troca de identidade;103 testes aprovados/analyze sem issues. Estado/formulários alimentares e configuração por ambiente continuam em revisão na021.

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
  bound --> diary["NutritionPage e formulários"]
  shell --> daily
  shell --> diary
  gate --> change["Troca de conta remove rotas privadas"]
  change --> bound
```

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
