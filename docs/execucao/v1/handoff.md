# Handoff vigente — TrainForge

Atualizado em **17/11/2026**. Checkout: `C:/dev/TrainForge/trainforge`. Leia esta página para retomar; a [história](../../historico/README.md) conserva a evolução, sem governar o ambiente atual.

## Estado confirmado

- Flutter Android/iOS; API Go **0.10.0/38 operações**, catálogo **0.2.0**, núcleo **schema 13/30 tabelas**, catálogo **schema 2/4 tabelas**. pgx/SQL  e Goose, sem ORM no backend atual.
- Google/sessão/privacidade011–013 encerrados no recorte local. Configuração047 teve revisão 2/14:00 recuperada e aceite registrado; não criar outra revisão para navegar. Alimentação manual e refeições têm capacidades entregues, com aceite integral045 ainda pendente.
- Execução017/023: motor, eventos/idempotência persistidos, quatro rotas privadas e uma superfície na aba Atividade. Alvos e realizado distintos, pausa/retomada e encerramento explícitos; escrita incerta só em memória do processo, sem fila offline durável.
- **73 metadados de consulta/439 ativos excluídos/zero programas, instruções, doses ou mídias de prática liberados** no lote entregue. Não gerar ocorrência ou treino fictício para habilitar a tela.
- APK debug **0.4.7+29 gerado/conferido**, não instalado/publicado pelo incremento. Último checkpoint instalado documentado:0.4.6+28; reobservar aparelho antes de agir.
- Antes da limpeza, API8082/catálogo18083/PG15432 estavam parados. A reorganização não os iniciou nem alterou contas, consumo, treino, assinatura ou credenciais.

## Próxima ação

**V1-015:** definir/publicar o primeiro programa próprio com instruções, doses e revisão verificáveis; depois seleção/adesão e agenda, ligando ocorrência real à execução. Testar Android com os cenários habilitados. Mídia, distribuiçãoHTTPS/release e offline têm gates próprios.

O [backlog](backlog.json) conserva **19 done/6 doing/24 todo** e critérios completos. A limpeza não mudou status nem completionEvidence. [Escopo e decisões](escopo.md), [implementação por domínio](implementacao.md) e [validação/entrega](validacao-e-entrega.md) substituem relatos repetidos.

## Evidências principais

[Atividade SQL](activity-session-sql-verification.json) e [integração](activity-session-integration-verification.json):337 Flutter/analyze0, Go/vet,138 Python;3 testesSQL+23 subtestes em descartável, base entregue inalterada. Não é aceite de prática real. Outros recibos são datados e ficam nos mesmos caminhos porque são provas de recortes diferentes e entradas de ferramentas.

A reorganização compactou pesquisa/documentos originais com caminhos e hashes, uniu arquitetura/diagramas e moveu as100notas pessoais do README para [aprendizado](../../aprendizado/README.md). SENAS e todos osSVG/JSON originais de design são preservados. Estado e validações desta limpeza ficam no [recibo de reorganização](../../historico/reorganizacao-2026-11-17.json); não sobrescrever recibos antigos.

## Operação e cuidados

`python tools/ambiente.py status`, `start`, logs, `plan-stop` e `stop` usam os recursos registrados. Não usar init/activate/importação/restore como inicialização cotidiana. `.local` contém dados, corpos de pesquisa, credenciais, backups e capturas; não apagar nem versionar.

Não repetirGoogle, alterar/classificar refeições antigas ou executar scripts históricos de pesquisa para recuperar contexto. Consulta de evidências antigas: `python tools/evidencias.py listar --filtro ...`, `mostrar <caminho>` ou `extrair <caminho>`; extração fica privada em`.local`. Prova documental não concede direitos de publicação/prática.

Git: commit/push deste trabalho foram autorizados; nunca repetir a reescrita histórica/force-push. Conferir todo o intervalo a publicar e não imprimir segredos. Novas pesquisas, compras, contatos ou hospedagem exigem escopo concreto; interesse em preço não é pagamento autorizado.


## CI pós-publicação —17/11

A primeira publicação detectou três causas: Swagger do catálogo varria também o novo módulo privado de atividade; cache Go frio enviava downloads em stderr misturados ao JSON; o Go 1.27.3 tinha a falha oficial GO-2026-6859. Correções: seleção positiva de fontes públicas, streams separados com parser estrito e SDK/build mínimo Go 1.27.4. Os sete checks remotos do commit `08d5774` passaram, incluindo SQL, catálogo, imagem, restore, documentação e segurança. [Evidências por execução](../../historico/reorganizacao-2026-11-17.json). O scanner apontou zero vulnerabilidades alcançadas pelo código; três avisos permanecem em módulos cujas funções afetadas não são chamadas. Isso não é auditoria integral nem aceite nativo do produto.
