# Telas, chamadas e navegação

A [documentação dinâmica](README.md) tem mapas de telas, chamadas HTTP, banco e arquitetura proposta no próprio repositório, sem servidor de leitura. Referências de construtor/import são evidência estática; não demonstram clique bem-sucedido ou condição de navegação.

## Fluxo atual lido no Flutter

Checkpoint23/10: pontosfrontend01–06 concluídos noAndroiddebug0.2.0+11 conforme direção doautor (aberturaTF/dark derivado). Aparência local é lida antes deAuthGate; restauração limitada apresenta entrada/retentativa ouProductShell poridentidade. Hoje/Diário usam resumoGo real; calendário abre histórico por data. Cinco abas preservam estado/foco/voltar; perfil abre aparência/privacidade/sessão. AppShell legado continua fora da composição. Execução/adesão e demais funções semcontrato/conteúdo permanecem indisponíveis.

```mermaid
flowchart LR
  launch["Splash TF nativo"] --> appearance["Aparência local: sistema / claro / escuro"]
  appearance --> gate["AuthGate: restaurar sessão com limite"]
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
