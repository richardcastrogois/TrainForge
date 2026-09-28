# Evidências da expansão de conteúdo

**Estado atual — 28/09:** N01–N07 concluídos para pesquisa nos recortes documentados. N06: três produtos OFF, sete ficheiros Commons, oito imagens inspecionadas, 22 chamadas preservadas/200/hashes e 23 verificações. N07: cinco guias institucionais, 12 lições, dois exemplos visuais próprios e 31 verificações; duas falhas TLS preservadas. Índice acumulado: 106 chamadas / 78 HTTP 200 / 72 hashes; catálogo: 50 fontes/famílias. Próximo: **N08 — receitas humanas**, não iniciado. Etapa 01 continua aberta; pesquisa não aprova catálogo integral, integração ou publicação. Retomar pelos resumos `docs/conteudo/evidencias/2026-09-28/n06-imagens/resumo-imagens.json` e `docs/conteudo/evidencias/2026-09-28/n07-rotulos/resumo-rotulos.json`; versão deste fechamento identificada no histórico Git.

## Fechamentos N06 e N07 — 28/09/2026

- [N06: resumo](2026-09-28/n06-imagens/resumo-imagens.json), [imagens/créditos](2026-09-28/n06-imagens/amostra-imagens.json), [revisão visual](2026-09-28/n06-imagens/revisao-visual.json), [23 verificações e 22 hashes](2026-09-28/n06-imagens/validacao-imagens.json).
- [N07: resumo](2026-09-28/n07-rotulos/resumo-rotulos.json), [12 lições e fontes](2026-09-28/n07-rotulos/conteudo-didatico.json), [guia visual próprio](2026-09-28/n07-rotulos/guia-rotulos.html), [31 verificações](2026-09-28/n07-rotulos/validacao-rotulos.json), [conferência desktop/celular](2026-09-28/n07-rotulos/validacao-visual.json).
- Sem rede: `python -X utf8 docs/conteudo/evidencias/analisar-imagens.py` (requer Pillow e raw local) e `python -X utf8 docs/conteudo/evidencias/analisar-rotulos.py` (biblioteca padrão e raw local). O segundo também regenera a referência HTML própria; preservar mudanças manuais antes de executar.
- Os manifestos `plano-*.json` guardam requisições exatas; o coletor preserva cache/falhas. O índice atual tem **106 chamadas, 78 HTTP 200 e 72 corpos com hash conferido**. Raw/fotografias/capturas permanecem locais e ignorados; não são redistribuídos no Git. Num clone novo, os resumos e amostras bastam para recuperar o resultado; análises de hash requerem os corpos locais, não executar coletor automaticamente.
- Visual N07 verificado por Playwright com **Comet headless e perfil temporário**, sem acessar dados do navegador pessoal. `validar-guia.cjs` usa `TRAINFORGE_PLAYWRIGHT_PATH`, `TRAINFORGE_BROWSER_PATH` e opcional `TRAINFORGE_GUIDE_URL`; requer runtime/navegador instalados e servidor local apontando apenas à pasta N07. Neste host, o navegador interno não respondeu e o browser empacotado não estava instalado; nenhum download foi feito. Duas vistas, detalhes expansíveis, tabela com deslocação e zero erros de página.

Os check-ins seguintes mantêm contagens históricas de cada incremento.

## Fechamentos N04 e N05 — 28/09/2026

- [N04: resumo](2026-09-28/n04-fechamento/resumo-fechamento.json), [35 verificações](2026-09-28/n04-fechamento/validacao-fechamento.json), [analisador local](analisar-fechamento-n04.py). 24 produtos, quatro marcas; contrato anterior reproduzido em 27 verificações.
- [N05: resumo](2026-09-28/n05-ingredientes/resumo-ingredientes.json), [amostras](2026-09-28/n05-ingredientes/amostra-ingredientes.json), [66 verificações](2026-09-28/n05-ingredientes/validacao-ingredientes.json), [analisador local](analisar-ingredientes.py). Cinco perfis e 14 grupos; ausência e declaração não equivalem a segurança.
- Ambos os analisadores usam apenas a biblioteca padrão Python e corpos locais com hash. Execute da raiz com `python -X utf8 docs/conteudo/evidencias/analisar-fechamento-n04.py` ou `python -X utf8 docs/conteudo/evidencias/analisar-ingredientes.py`.
- [Coletor limitado](coletar-nichos-off.py): manifesto por nicho, cache, nenhum retry. Não executar para recuperar contexto. Índice acumulado: 77 chamadas / 51 HTTP 200 / 45 hashes conferidos.

## N04 — contrato nutricional e amostra dirigida · 28/09/2026

[Resumo](2026-09-28/n04-contrato-off/resumo-contrato.json), [contrato normalizado](2026-09-28/n04-contrato-off/contrato-nutricional.json), [cinco novos produtos](2026-09-28/n04-contrato-off/amostra-dirigida.json), [estados observados](2026-09-28/n04-contrato-off/estados-observados.json) e [27 verificações](2026-09-28/n04-contrato-off/validacao-contrato.json). O [analisador](analisar-contrato-off.py) é um demonstrador local, não componente do app: executar `python docs/conteudo/evidencias/analisar-contrato-off.py` com os insumos locais preservados.

O [coletor](coletar-contrato-off.ps1) fez nove GETs: quatro 200, três 503 e dois 404 esperados em casos negativos sintéticos. Não repetiu os resultados anteriores. O código de produto real veio da amostra de 27/09; os casos negativos estão identificados separadamente e não contam como cobertura. Corpos em `2026-09-28/raw/` ignorados pelo Git, nove hashes conferidos. Índice acumulado: **60 chamadas, 36 HTTP 200, 28 corpos com hash conferido**. [Interpretação e campos exatos](../evidencias-para-integracao.md#n04--produtos-vendidos-em-portugal). A documentação anterior abaixo preserva a sequência de descoberta.

## N04 — primeira amostra portuguesa · 27/09/2026

[Resumo](2026-09-27/n04-produtos-portugal/resumo-produtos.json), [dez produtos](2026-09-27/n04-produtos-portugal/amostra-produtos.json) e [comparação v2/v3.6](2026-09-27/n04-produtos-portugal/comparacao-v2-v3.json). Quatro GETs, todos HTTP 200; quatro corpos/hashes preservados. Raw permanece local em `2026-09-27/raw/`, ignorado pelo Git. Índice acumulado: **51 chamadas, 32 HTTP 200, 19 corpos com hash conferido**.

[Coletor](coletar-produtos-portugal.ps1): cache de sucesso/falha, 25 s e 1 MiB por resposta, sem retries. Obteve documentação, licença, busca de até dez produtos e um detalhe cujo código veio da busca. Não repetir para recuperar contexto. [Analisador sem rede](analisar-produtos-portugal.py), só biblioteca padrão: `python docs/conteudo/evidencias/analisar-produtos-portugal.py`, a partir da raiz do repositório, requerendo os corpos locais. O nicho permanece aberto: identidade confirmada, nutrientes divergentes entre versões e representatividade não medida. [Dossiê](../evidencias-para-integracao.md#n04--produtos-vendidos-em-portugal).

## N03 — porções, quantidades e preparo · 27/09/2026

[Resumo](2026-09-27/n03-porcoes/resumo-porcoes.json), [casos reais](2026-09-27/n03-porcoes/casos-porcoes.json), [26 verificações](2026-09-27/n03-porcoes/validacao-porcoes.json) e [duplicidade CoFID](2026-09-27/n03-porcoes/duplicidades-cofid.json). Três chamadas novas, todas 200, com URL/status/data/hash nos arquivos `*.evidencia.json` dessa pasta. Corpos em `2026-09-27/raw/` são locais e ignorados. Índice acumulado: **47 chamadas, 28 HTTP 200, 15 corpos com hash conferido**.

O [analisador N03](analisar-porcoes.py) reutiliza Ciqual/CoFID/USDA já guardados, confere hashes e usa `pypdf` para validar as páginas do guia CoFID. O runtime Python fornecido pelo Codex nesta máquina já dispõe dessa biblioteca; o ambiente do Graphify não é pressuposto para esse script. Não há rede na análise:

```powershell
& 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -X utf8 docs/conteudo/evidencias/analisar-porcoes.py
& 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -X utf8 docs/conteudo/evidencias/inventariar-retornos.py
```

Executar a partir de `C:/dev/TrainForge/trainforge`. Em clone limpo, repor legitimamente as entradas identificadas nos metadados; os corpos brutos e datasets completos não são publicados. O [coletor limitado N03](coletar-porcoes.ps1) registra sucessos/falhas e reutiliza ambos; não executar para recuperar contexto já preservado. O [piloto inicial](2026-09-27/n03-porcoes/piloto-inicial.json) é histórico e foi ampliado pelo analisador final. [Método, chamadas e limites](../evidencias-para-integracao.md#n03--quantidades-porções-volume-e-preparo).

**N01 — identidade alimentar, 26/09/2026:** [resumo](2026-09-26/n01-alimentos/resumo-identidades.json) e [30 exemplos](2026-09-26/n01-alimentos/amostra-identidades.json). Dois XMLs Ciqual recebidos, 3.484 IDs/nomes/grupos cruzados com a planilha; francês/inglês presentes, português ausente e uma classificação desconhecida preservada. [Coletor](coletar-identidades.ps1), [analisador sem rede](analisar-identidades.py) e [retorno exato](../evidencias-para-integracao.md#n01--retorno-xml-de-identidade-alimentar). XMLs/normalizado integral em `2026-09-26/n01-alimentos/raw/` ficam locais. N02 não foi iniciado neste ataque.

**Entrada técnica:** [dossiê de retornos para implementação](../evidencias-para-integracao.md) e [índice de chamadas](retornos-observados.json), gerado localmente por [inventariar-retornos.py](inventariar-retornos.py). Separa o corpo externo dos campos criados pelos coletores/analisadores. A disponibilidade do corpo integral em disco e a possibilidade de conferir seu hash estão explícitas por registro.

**Publicação inicial — 24/09/2026:** scripts, resumos, inventário e manifestos de pesquisa podem ser consultados no repositório. Planilhas, respostas integrais de fornecedores e subconjuntos indicados como “apenas local” permanecem preservados nesta máquina e excluídos do Git; sua redistribuição não foi aprovada neste incremento. Os manifestos descrevem o conjunto local original, não uma garantia de que cada arquivo está no clone. Para reproduzir os analisadores, primeiro obter legitimamente as entradas documentadas; não esperar que funcionem com todos os dados em um clone limpo.


## Pilotos de 26/09/2026

Começar por [pilotos-resumo.json](2026-09-26/pilotos-resumo.json). O [analisador local](analisar-pilotos.py) não usa rede nem IA e verifica hashes antes de extrair as tabelas de corrida. Resultados: **27 sessões / 12 padrões** NHS, sete movimentos de força com 20 passos na fonte e conversão de massa de 12 alimentos CoFID. A conferência da corrida inclui os totais declarados e comparação de todos os intervalos com as duas páginas do PDF oficial, inspecionadas visualmente. Não há integração, revisão pt-PT concluída ou aprovação de publicação.

Artefatos numéricos com origem/limites: [corrida](2026-09-26/corrida-piloto.json), [força](2026-09-26/forca-piloto.json), [alimentação](2026-09-26/alimentacao-piloto.json). O JSON de força preserva parâmetros e número de passos, não substitui as instruções integrais conservadas no HTML local. Alongamentos sem duração, séries e descansos ausentes não foram inventados; traços nutricionais não viraram zero.

O [coletor limitado](coletar-pilotos.py) guarda sucesso e falha. A primeira tentativa ficou bloqueada pelo sandbox antes dos fornecedores; a tentativa separada `--attempt network`, com acesso de rede autorizado, obteve cinco respostas 200, OFF 503 e PDF NHLBI 404. [Resumo da tentativa com rede](2026-09-26/network/coleta-resumo.json). Não repetir esses pedidos para recuperar contexto. HTML/PDF/PNG originais ficam em `2026-09-26/network/raw/`, ignorados pelo Git; registros de URL, data e hash ficam fora de `raw/`. Os PNGs são renderizações locais das duas páginas para inspeção, não material visual do app.

Reproduzir **com as entradas locais já presentes**, sem nova coleta:

```powershell
& 'C:\Users\richa\AppData\Roaming\uv\tools\graphifyy\Scripts\python.exe' 'C:\dev\TrainForge\trainforge\docs\conteudo\evidencias\analisar-pilotos.py'
```

Em um clone limpo, obter as entradas permitidas indicadas pelos registros de coleta e a amostra CoFID, preservando os hashes; os corpos de terceiros não acompanham o clone. Os resultados estruturados também são **pesquisa**, não catálogo liberado. [Decisão e pendências da etapa](../../planejamento/etapa-01-pesquisa.md).

## Coleta de 23/09/2026

Consulta recomendada: [resumo-expansao.json](resumo-expansao.json), depois o subconjunto necessário. A [primeira coleta](../../planejamento/evidencias/README.md) continua intacta.

| Artefato | Conteúdo e origem |
|---|---|
| CoFID recebido (`cofid-2021.xlsx`, apenas local) / amostra (`cofid-amostra.json`, apenas local) | Dataset público de [Public Health England](https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid), edição 2021. Informação do setor público sob Open Government Licence v3.0, observadas exceções. Amostra mantém códigos, nomes, valores e referências originais. |
| Ciqual recebido (`ciqual-2025.xlsx`, apenas local) / amostra (`ciqual-amostra.json`, apenas local) | Du Chaffaut, Laure; Oseredczuk, Marine; Gauvreau-Béziat, Julie, 2025, Table de composition nutritionnelle des aliments Ciqual 2025, Anses, Recherche Data Gouv V1, [DOI](https://doi.org/10.57745/RDMHWY). Licence Ouverte Etalab 2.0, registrada nos metadados oficiais (`ciqual-2025-metadata.json`, apenas local). |
| wger adicional 300 (`wger-offset-300.json`, apenas local) e 600 (`wger-offset-600.json`, apenas local) | Metadados públicos da API, autores/licenças preservados dentro dos objetos. [Resumo ampliado](wger-amostra-ampliada.json). Dados sujeitos à licença por objeto; software AGPL não é a licença universal do conteúdo. |
| `compendium-*.evidencia.json` | Quatro entradas por categoria, código/MET/descrição original e URL. Fonte: [2024 Compendium of Physical Activities](https://pacompendium.com/), equipe de Barbara E. Ainsworth. O site autoriza uso comercial gratuito com citação e preservação dos valores/atividades. HTML integral e mídia não foram guardados. |
| `*.evidencia.json` | URL pública, data UTC, status/erro e SHA-256 do corpo recebido quando aplicável. Para Compêndio, o hash é do HTML recebido, não de um arquivo HTML local. |
| [manifesto.json](manifesto.json) | Hash e tamanho dos arquivos locais; permite verificar integridade. Não prova qualidade clínica ou titularidade. |

Os subconjuntos são seleções mecânicas para investigação, com valores originais. Não são tradução aprovada, base de produção ou recomendação pessoal de saúde. Licença autoriza usos dentro de suas condições; a curadoria desta pasta não certifica cada conteúdo.

## Reproduzir sem novas chamadas

```powershell
& 'C:\Users\richa\AppData\Roaming\uv\tools\graphifyy\Scripts\python.exe' 'C:\dev\TrainForge\trainforge\docs\conteudo\evidencias\analisar-expansao.py'
```

O analisador usa somente arquivos existentes e biblioteca padrão. Lê planilhas como XML dentro de ZIP; não executa macros. Guarda contagens, regras de seleção, amostras e manifesto. O resultado depende das versões locais preservadas.

O [coletor](coletar-expansao.py) só deve ser executado quando houver motivo para conferir as fontes. Ele reutiliza sucessos e falhas existentes, limita cada resposta a 10 MiB, não usa credenciais privadas e não tenta contornar restrições. Recoletar uma nova edição exige planejar novos nomes/data, preservando a coleta anterior. A transferência nativa Windows do Ciqual foi uma verificação isolada com TLS padrão; seu [registro](ciqual-2025-windows.evidencia.json) preserva o resultado.

## Falhas e limites

Na rodada de 23/09, Fineli retornou 403 e permanece não amostrado. Ciqual falhou no certificado do Python e funcionou pelo cliente nativo Windows; ambas as evidências permanecem. Não foram baixadas imagens, vídeos ou o XML Ciqual de composição de cerca de 69 MB. OFF não foi novamente consultado naquela rodada; em 26/09 a consulta limitada também retornou 503, conforme registro acima.

Esta pasta mantém a pesquisa local e seus resumos públicos separados. A seleção de arquivos para o primeiro commit exclui dados brutos; a publicação do código não libera automaticamente os conteúdos das fontes.
