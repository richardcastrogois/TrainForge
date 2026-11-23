# Avisos de terceiros

O TrainForge é proprietário (ver [LICENSE](LICENSE)), mas usa dados, fontes e bibliotecas de terceiros que continuam sob as licenças abaixo. No aplicativo, os créditos completos aparecem em **Configurações → Fontes e licenças** e na lista de licenças de pacotes.

## Bases de dados de alimentos

| Fonte | Licença | Condições principais |
|---|---|---|
| Open Food Facts | Open Database License (ODbL) 1.0 / Database Contents License (DbCL) 1.0 | Atribuição; a base derivada continua aberta sob ODbL. As exportações por fonte são oferecidas junto de cada pacote do catálogo |
| TACO 4ª edição (NEPA/Unicamp) | Reprodução permitida com citação da fonte | Citação, origem e edição preservadas; sem endosso da Unicamp |
| USDA FoodData Central | CC0 1.0 / domínio público | Fonte e versão preservadas; sem endosso do USDA |
| Ciqual 2025 (Anses) | Licence Ouverte / Etalab 2.0 | Fonte, licença, versão e alterações informadas |
| CoFID 2021 (Public Health England) | Open Government Licence v3.0 | Atribuição e aviso de licença |

## Conteúdo de exercícios

| Fonte | Licença | Condições principais |
|---|---|---|
| wger | CC BY-SA 4.0 (dados de exercícios, conforme cada registro) | Atribuição aos autores e compartilhamento pela mesma licença do conteúdo derivado |

Os 73 metadados de exercícios usados para consulta guardam autor, licença e origem em `content/manifests/`.

## Modelo de reconhecimento de alimentos por foto

O modelo `assets/models/food_photo_int8.tflite` é próprio do TrainForge, partindo dos pesos `tf_efficientnet_lite0.in1k` (timm, Apache 2.0). Foi treinado com marcações do SigLIP 2 (Apache 2.0) sobre fotos de Nutrition5k (CC BY 4.0), Open Images V7 (somente fotos CC BY 2.0, rótulos CC BY 4.0) e Wikimedia Commons (somente CC0, domínio público e CC BY). Autor, licença e origem de cada foto ficam nos manifestos de treino. As fotos não são distribuídas com o app.

## Fontes tipográficas

| Fonte | Licença |
|---|---|
| Inter | SIL Open Font License 1.1 (`assets/fonts/OFL.txt`) |

## Bibliotecas

O aplicativo Flutter e a API Go usam pacotes de código aberto (por exemplo Flutter, Dio, sqflite, SQLCipher, ML Kit/mobile_scanner, pgx, Goose) sob licenças como BSD, MIT e Apache 2.0. Os textos completos dessas licenças são incluídos automaticamente no aplicativo (tela de licenças do Flutter) e podem ser consultados em `pubspec.lock` e `services/api/go.mod`.
