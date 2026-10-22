# Conteúdo: estado e ponto de entrada

**21/10/2026:** N01–N46 encerradas nos recortes documentados:40 pesquisas e6 reusos; sem N ativa.331 famílias catalogadas, com estados candidato/condicional/referência/incompatível. Não equivalem a331 fornecedores licenciados nem a46 programas integrais executáveis.

Índice documental:840 tentativasGET,694HTTP200 e780 hashes de corpos retidos conferidos. São registros de pesquisa, não chamadas do app. Pesquisa concluída não é homologação editorial, clínica ou comercial.

## Encontrar sem repetir buscas

| Preciso de… | Abrir |
|---|---|
| Estado de todas as N | [Consolidação](evidencias/2026-10-15/consolidacao-n01-n46.json) e [complementos](evidencias/2026-10-03/revisao-publicos-ambientes/fila-complementos-anteriores.json) |
| Nova pista: APIs de exercício, mídias e compra única | [Verificação oficial de21/10](avaliacao-apis-exercicios-2026-10-21.md) |
| Lista de fontes/famílias | [Catálogo](catalogo-fontes.md), [JSON](fontes.json), `consultar-fontes.py` |
| Cuidadores — seleção final | [Relatório N15](evidencias/2026-10-21/n15c-composicao/relatorio.md), [biblioteca11](evidencias/2026-10-21/n15c-composicao/biblioteca-cuidadores.json), `consultar-cuidadores.py --biblioteca` |
| Limites dos candidatos antigos | [Catálogo cuidadores](catalogo-cuidadores.md) e [fila](fila-cuidadores.json); currentSelection aponta o recorte final |
| Por que uma fonte não basta para publicar | [Direitos](direitos-e-acordos.md), [curadoria](qualidade-e-curadoria.md), [critériosAPK](criterios-exercicios-apk.md) |
| Dados reais preparados localmente, schema e fila por ativo | [Preparação de21/10](preparacao-local-2026-10-21.md) |
| Operações já revisadas para consulta e textos portugueses retidos | [Revisão de consulta](revisao-consulta-2026-10-21.md) |
| Materiais para integração | [Dossiê de integração](evidencias-para-integracao.md) e [cobertura](cobertura-e-prioridades.md) |
| BeFit/REA/emulador | [Handoff datado](handoff-befit-2026-10-14.md) e [guia de ambiente](guia-rea-emulador-befit-2026-10-14.md); não repetir nem presumir estado do aparelho |
| Próxima etapa | [Escopo V1](../execucao/v1/escopo.md), histórias001/004/005/019 |

N15:1 alongamento estático restritoCG01/PR42,8 variantesnível1ReViEEWCG04/PR68 com apoio profissional e2 práticas escritasCaregiversFIRSTCG06/PR261. São11 componentes, sem circuito novo ou eficácia herdada. ES2019-DOM-01/PR28 mantém5 movimentos para idosos em casa separadamente. Materiais Benson/START/Pilates e variantes não selecionadas conservam lacunas de material/direitos/versão. Não preencher por IA.

## Conferir resultados localmente

```powershell
python docs/conteudo/evidencias/2026-10-21/n15c-composicao/conferir-fechamento.py
python docs/conteudo/evidencias/2026-10-15/conferir-continuacao-n39-n46.py
python -m unittest discover -s docs/conteudo/evidencias -p test_catalogo_cuidadores.py
```

São verificações documentais, não teste clínico nem do aplicativo. Corpos/renders de terceiros permanecem locais e ignorados no Git; recibos/hashes permitem saber o que foi efetivamente recebido e o que falhou. Não repetir URLs/barreiras sem pista nova, nem atribuir fonte externa ao BeFit sem prova.

[Snapshots do antigo índice](../arquivo/2026-10-21/docs/conteudo/README.md) preservam a evolução, sem substituir o estado vigente.
