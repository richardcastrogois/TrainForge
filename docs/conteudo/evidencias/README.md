# Evidências da expansão de conteúdo

**Publicação inicial — 24/09/2026:** scripts, resumos, inventário e manifestos de pesquisa podem ser consultados no repositório. Planilhas, respostas integrais de fornecedores e subconjuntos indicados como “apenas local” permanecem preservados nesta máquina e excluídos do Git; sua redistribuição não foi aprovada neste incremento. Os manifestos descrevem o conjunto local original, não uma garantia de que cada arquivo está no clone. Para reproduzir os analisadores, primeiro obter legitimamente as entradas documentadas; não esperar que funcionem com todos os dados em um clone limpo.


Coleta de 23/09/2026. Consulta recomendada: [resumo-expansao.json](resumo-expansao.json), depois o subconjunto necessário. A [primeira coleta](../../planejamento/evidencias/README.md) continua intacta.

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

Fineli retornou 403 e permanece não amostrado. Ciqual falhou no certificado do Python e funcionou pelo cliente nativo Windows; ambas as evidências permanecem. Não foram baixadas imagens, vídeos ou o XML Ciqual de composição de cerca de 69 MB. OFF não foi novamente consultado; as duas respostas 503 estão na primeira coleta.

Esta pasta mantém a pesquisa local e seus resumos públicos separados. A seleção de arquivos para o primeiro commit exclui dados brutos; a publicação do código não libera automaticamente os conteúdos das fontes.
