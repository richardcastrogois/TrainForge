# Evidências da pesquisa — 22/09/2026

**Publicação inicial — 24/09/2026:** scripts, resumos, inventário e manifestos de pesquisa podem ser consultados no repositório. Planilhas, respostas integrais de fornecedores e subconjuntos indicados como “apenas local” permanecem preservados nesta máquina e excluídos do Git; sua redistribuição não foi aprovada neste incremento. Os manifestos descrevem o conjunto local original, não uma garantia de que cada arquivo está no clone. Para reproduzir os analisadores, primeiro obter legitimamente as entradas documentadas; não esperar que funcionem com todos os dados em um clone limpo.


Material de avaliação local, não dados incorporados ao aplicativo nem pacote pronto para redistribuição. Os JSONs de coleta contêm URL, instante UTC, status e, em caso de sucesso, payload/hash/duração. Nenhuma chave privada, informação de utilizador do TrainForge ou foto pessoal foi usada. `DEMO_KEY` é a chave pública de demonstração USDA.

## Arquivos principais

- [Inventário Figma preservado](base-2026-09-22.json): 105 telas/estados e dois mapas na cópia `126:2`; IDs pertencem à cópia, não à página de trabalho.
- [Resumo analisado](resumo-amostras.json): 25 exercícios wger, 25 do dataset alternativo e 15 alimentos USDA; flags, completude e IDs para inspeção pontual.
- wger (`wger-25.json`, apenas local) e idiomas (`wger-languages.json`, apenas local): licença/autoria no payload, incluindo traduções e ativos; português corresponde ao ID 7 na resposta consultada. A lista de idiomas recebida é paginada; não é o censo de todos os idiomas.
- Dataset alternativo (`free-exercise-db.json`, apenas local): 876 registros, dos quais 25 amostrados de forma determinística. Origem: [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db), Unlicense declarada pelo projeto. Não foram baixadas imagens.
- Revisão do arquivo do dataset (`free-exercise-revision.json`, apenas local): consulta ao último commit que afeta `dist/exercises.json`, SHA `79ca7b47d77cd5a6dd7a50440e9f0bf24da6a142`, data 29/08/2026. A coleta usou `main`; o hash do corpo preserva exatamente o que foi recebido, não houve comparação adicional com download fixado no commit.
- USDA rice (`usda-rice.json`, apenas local), milk (`usda-milk.json`, apenas local), egg (`usda-egg.json`, apenas local) e detalhe 748967 (`usda-egg-detail.json`, apenas local): domínio público/CC0 conforme [guia oficial](https://fdc.nal.usda.gov/api-guide/). A seleção é por relevância das buscas, não lista representativa de alimentos portugueses.
- [Open Food Facts v3.6](off-portugal-20.json) e [v2](off-portugal-v2-20.json): respostas HTTP 503 sem produtos; nenhuma conclusão de cobertura pode ser extraída.
- `*.sandbox-denied.json`: tentativas impedidas pela rede local antes da coleta autorizada. Não representam indisponibilidade dos fornecedores.

Créditos wger: autores e licenças originais mantidos integralmente nos registros coletados; API de origem `https://wger.de/api/v2/exerciseinfo/`. Os arquivos de evidência não autorizam reempacotar toda a base. Antes de publicar estas evidências num repositório, revisar a distribuição e os avisos de licença; normalmente o resumo e os scripts bastam.

## Reproduzir sem novas chamadas

Na raiz `C:\dev\TrainForge`:

```powershell
& 'C:/Users/richa/AppData/Roaming/uv/tools/graphifyy/Scripts/python.exe' trainforge/docs/planejamento/evidencias/analisar-amostras.py
```

O analisador lê arquivos existentes; não acessa a rede. O coletor `coletar-amostras.py` também reutiliza resultados, inclusive falhas, por padrão. Não apagar resultados para forçar tentativas repetidas. Para nova campanha, criar pasta datada e manter a anterior; respeitar quotas e não fazer carga contra serviços públicos.

Não usar esta amostra para afirmar disponibilidade, segurança clínica ou autorização universal de mídia. Conferir [conclusões e pendências](../etapa-01-pesquisa.md).
