# Catálogo alimentar offline

O catálogo de produção contém o conjunto aproveitável completo das fontes
declaradas no manifesto. Dados parciais não são substituídos por uma amostra.
Registros sem base ou composição suficiente continuam desconhecidos e não são
convertidos em nutrientes iguais a zero.

## Preparação

```powershell
python tools/food_catalog_download.py --all
python tools/food_catalog_build.py --build
python tools/food_catalog_build.py --verify
python -m unittest discover -s tools -p test_food_catalog.py
```

Os preparadores usam Python e a biblioteca `cryptography` para Ed25519. Os
importadores, CSV, XLSX, SQLite, gzip e verificadores de hashes usam a biblioteca
padrão. A preparação não exige pandas, Arrow ou acesso à conta do aplicativo.
O comando de build também executa o empacotamento; `food_catalog_package.py`
pode ser chamado separadamente para concluir um snapshot já assinado.

Downloads, recibos, chave privada, estágios e exportações ficam em
`.local/food-catalog/`. A chave privada não faz parte do APK ou do Git. Os dados
legados vêm do snapshot aprovado em `content/local/food-approved-v1.jsonl` e
conservam os IDs e hashes de versão já utilizados pelo backend.

`--verify` não usa a rede. Exige catálogo completo, rejeita fixtures e confere
assinatura Ed25519, tamanho, hash do gzip, cabeçalho e hash/tamanho do SQLite
descompactado por streaming. Não exige uma cópia bruta do banco em outro diretório.

As URLs de dumps upstream podem ser mutáveis. Para reconstruir exatamente uma
versão, conservar os snapshots cujo SHA consta no lock ou obter o pacote próprio
com o mesmo hash; baixar o dump de outro dia não reproduz aquela versão. O lock
não significa que esses arquivos já foram hospedados ou publicados.

## Artefatos

- `assets/food_catalog/manifest.json`: envelope `{keyId,payload,signature}`; o
  payload é JSON canônico UTF-8 em base64 e a assinatura usa Ed25519.
- `assets/food_catalog/trust.json`: somente chaves públicas confiadas no APK.
  Uma atualização não pode introduzir a própria chave de confiança.
- `assets/food_catalog/catalog.sqlite.gz`: base completa comprimida. O payload
  declara `file`, `bytes`, `sha256` do gzip e `databaseFile`, `databaseBytes`,
  `databaseSha256` do SQLite resultante.
- `catalog.lock.json` e `build-report.json`: versão, fontes, cobertura, tamanhos e
  evidências da geração. Só são conclusivos quando `complete` for verdadeiro.
- Exportações por fonte: JSONL gzip legível por máquina. Cada arquivo, fonte,
  licença, quantidade de linhas, bytes e SHA integra o payload assinado.
- `.local/food-catalog/distribution/catalog-update.zip`: exatamente manifesto e
  gzip, com entradas ZIP_STORED. O ZIP e o SQLite bruto não entram no APK.

Arquivos grandes são artefatos de distribuição, não blobs para o Git. A build de
um checkout limpo precisa dos artefatos travados por hash ou dos snapshots
originais autorizados para regenerá-los. Nenhum token ou arquivo privado do
usuário integra esses pacotes.

## Contrato SQLite `trainforge.food-catalog/1`

`foods` preserva identidade/versão, nome original, idioma, origem, base, preparo,
marca e texto normalizado de busca. `sources` contém os créditos completos uma
vez por fonte. `barcodes` mantém o texto original e uma equivalência GTIN de 14
dígitos apenas para códigos cujo comprimento e dígito verificador forem válidos.

O layout físico `row-key-external-fts/1` mantém essas colunas públicas: `foods`
tem `row_key INTEGER PRIMARY KEY` e identidade/versão únicas; `barcode_links`
guarda chaves inteiras e `barcodes` é uma view compatível. A FTS4 usa conteúdo
externo de `foods` com as mesmas três colunas e `docid=row_key`. O layout é
declarado no manifesto assinado e em `metadata.storage_layout`; não muda a
versão do conteúdo. `food_catalog_compact.py` migra um SQLite já assinado sem
reler fornecedores e prova equivalência de todos os campos e códigos de barras.
Sua retomada reutiliza alimentos confirmados e salva códigos em lotes de 5.000.

Campos JSON grandes podem usar `zlib:` seguido de base64, sem mudar o valor
decodificado. O metadado `json_encoding` identifica essa representação.

`nutrient_columns` é o dicionário de colunas originais. Uma célula em
`original_nutrients_json` usa:

```text
[column_id, state, value, upperBound, rawText, basisQuantity, basisUnit, scalingAllowed]
```

`canonical_nutrients_json` usa referências compactas:

```text
[column_id, primaryForTotals, valueConvertido, upperBoundConvertido]
```

Nome/método/nutrientId vêm do dicionário; estado e base vêm da célula original;
unidades canônicas vêm de `metadata.nutrient_units`. O valor convertido já está
calculado em decimal, sem nova aproximação no cliente. Só um valor elegível por
nutriente participa do total; métodos alternativos não são somados.

As exportações JSONL contêm objetos nomeados, sem depender dessa compactação
interna. Novos alimentos recebem `food:<sha256(sourceId + NUL + sourceFoodId)>` e
uma versão de conteúdo. A identidade do catálogo é derivada dos IDs/versões
ordenados; o SHA do arquivo também deve ser considerado em atualizações de
créditos ou representação.

## Direitos e qualidade

TACO conserva a citação NEPA/Unicamp. USDA declara domínio público/CC0. Ciqual e
CoFID mantêm as licenças e condições do lote revisado. A parte derivada do Open
Food Facts permanece sob ODbL/DbCL, com avisos e oferta das exportações; os dados
privados e o código do aplicativo não fazem parte dela.

O TSV do Open Food Facts contém campos opcionais ausentes e o parser preserva
essas linhas. A base g/ml só é escalável quando o rótulo métrico é inequívoco;
densidade, peso drenado e peso de colher nunca são inventados. A contribuição
comunitária só entra após consentimento CC0 explícito e revisão do mantenedor.

`food_catalog_resume.py` recupera uma execução interrompida usando prefixos
persistidos e conferência contra as fontes completas. Não altera os downloads
originais nem transforma um banco temporário em catálogo pronto sem verificação.

## Oferta por versão e ativação

Antes de reutilizar o diretório de exportações para uma nova geração, preservar
os exports assinados da release com `python tools/food_catalog_publish.py
--confirm SHA_DO_ARTEFATO`. O helper confere todos os bytes e move somente os
exports aprovados para `.local/food-catalog/exports/SHA_DO_ARTEFATO/`, gravando
o manifesto por último. Não migra SQL nem hospeda na internet. É retomável e
não substitui uma release existente com bytes divergentes.

O importador Go usa `--exports` apontando para essa subpasta: primeiro
`--operation verify` (sem DB), depois stage e activate com SHA explícito,
papel migrator e destino local protegidos. A release exata precisa estar ativa
antes de disponibilizar APK/update. O servidor confere assinatura com seu
trust próprio, identidade ativa, bytes e hashes; oferece manifesto, ZIP e
exports com Range, incluindo versões anteriores pelo artifactSHA256.
Não apagar esses exports ao publicar uma nova versão.

Os caminhos do servidor ficam em TF_FOOD_CATALOG_DIRECTORY,
TF_FOOD_CATALOG_EXPORTS_DIRECTORY e TF_FOOD_CATALOG_ARCHIVE_PATH. A configuração
local não significa publicação externa; HTTPS/OAuth/assinatura de release
continuam no gate de distribuição do APK.
