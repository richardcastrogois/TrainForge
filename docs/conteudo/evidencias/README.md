# Evidências da expansão de conteúdo

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
