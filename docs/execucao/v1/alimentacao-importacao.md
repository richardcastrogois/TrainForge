# V1-019 — lote alimentar real importado

Concluído o lote autorizado de22/10/2026 no banco isoladoV1: **6369registros versionados**, sendo3484Ciqual2025 e2885CoFID2021. Não representa6369alimentos semanticamente únicos entre países/fontes. Não há dieta, porção caseira, cadastro próprio ou consumo fictício. Busca/consumoHTTP e Flutter ainda não integrados; o APK0.1.1+2 permanece igual.

## Direitos, versão e cobertura

A [decisão por fonte/operação](../../../content/manifests/food-review-decisions.json) vincula hashes dos snapshots, versão, evidência e condições. Revisão documental/técnica porCodex; não é homologação clínica. Não aprova por herança as outras20famílias de alimentação.

- **Ciqual2025:** metadados oficiais locais comSHA256 conferido declaram Etalab2.0; arquivo666260 não restrito e MD5 confere com a planilha. Mantidos autores, Anses, DOI, edição1.0 e publicação19/11/2025. A [licença oficialEtalab2.0](https://github.com/etalab/licence-ouverte/blob/master/LO.md) permite reutilização/adaptação com fonte/data e sem sugerir endosso. A abertura atual do depósito pela ferramenta falhou; não houve nova coleta nem alegação de que se verificou a versão mais recente.
- **CoFID2021:** [página oficial](https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid) relaciona arquivo principal e oldfoods separados e indica OGL3 salvo exceções. O arquivo local é o principal, comhash fixado; oldfoods não foi incorporado. A [licençaOGL3](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) exige atribuição e mantém exclusões, sem garantia/endosso. Abertura direta403não repetida; texto indexado primário conferido. Não copiar livros, texto do guia, fotos, logotipos ou dados pessoais por extensão da licença do dataset.

Nomes/idiomas originais, preparo contido no nome, métodos e valores foram preservados. Nenhuma tradução ou valor novo produzido. [Inventário/preflight das22famílias](alimentacao-preflight.md) continua completo: outrasfontes não preparadas e referências visuais/metodológicas mantêm seus gates próprios. Esta entrega importa integralmente os dois snapshots preparados e autorizados, sem escolher uma amostra pequena como base definitiva.

## Identidade, denominadores e ausências

| Resultado conferido | Quantidade |
|---|---:|
| Ciqual: candidatos/revisados/importados |3484|
| CoFID: identidades no arquivo preparado |2887|
| CoFID: identidades do código conflitante13-669 excluídas, sem escolher primeira |2|
| CoFID: importados |2885|
| Base100g |6335|
| Base100ml por grupo alcoólico explicitamente listado no guia |31|
| GrupoBTM ausente do apêndice conferido: metadado/composição mantidos, base desconhecida e cálculo bloqueado |3|
| Células de nutrientes preservadas no lote |768461|
| Células auxiliares (fatores/denominadorFA) separadas da composição de alimento |300639|
| Células dos códigos conflitantes excluídas com motivo |560|

As768461+300639+560células conciliam as1069660células do preparo. FatorJones e fatoresCoFID não viram nutrientes. Denominadores100gFA, inclusive dentro deProximates, ficam separados. Quando cabeçalho/tabela100gFood conflita com a base100ml do grupo alcoólico, o valor/declaracão permanecem, mas a escala daquela célula é bloqueada.

Grupos usados para100g/100ml são allowlist exata do [guiaCoFID](https://assets.publishing.service.gov.uk/media/60538e66d3bf7f03249bac58/McCance_and_Widdowsons_Composition_of_Foods_integrated_dataset_2021.pdf), páginas7–11 e apêndiceB23–26. Não inferir bebida pelo nome nem usar prefixo desconhecido para escolher unidade. A contagem histórica2760era limitada; a leitura integral do arquivo principal mantém2887identidades. Os registros originais e recibos históricos não foram sobrescritos.

Zero, ausente, traço, presença sem quantidade confiável, limite “menor que” e marcadornãointerpretado continuam distintos. Valores/limites são decimais exatos emstrings; limite não vira quantidade medida.14marcadoresnãointerpretados permanecem na composição e1nos auxiliares. Métodos alternativos de energia/proteína/fibra não são somados nem fundidos.

A permissão técnica de escala requer número exato, unidade e denominador compatíveis e direitos específicos. **Não equivale a prescrição ou medição individual.** Não há cálculo de consumo executado nesta história.

## Implementação e comandos

`tools/revisar_alimentos_v1.py` valida a decisão/evidências e produz artifactJSONL local por identidadefonte+código, com versões imutáveis. Chavefonte do fornecedor permanece separada da chave técnica. Colunas, linhas e hashes preservam proveniência por célula.

Go em `services/api/internal/nutrition` usa `os.OpenRoot`, limites de tamanho, contrato estrito, comparação exata de decimais e vínculo aos cabeçalhos/grupos revisados. Rejeita lote candidato, fonte semgrant, corpo adulterado, coluna/unidade trocada, atribuição incompleta, código falso, duplicidade, caminho externo, fator/FA como nutriente e afirmação clínica.

```powershell
# O ambiente local precisa existir; não instala nem baixa ferramentas.
python tools/revisar_alimentos_v1.py --write
python tools/importar_alimentos_local.py --dry-run  # sem conexãoDB
python tools/migrate_local.py                     # somenteclusterV1 desteclone
python tools/db_local.py grant-runtime
python tools/importar_alimentos_local.py
```

Não repetir o export/import sem alteração relevante. A CLI de escrita aceita somente127.0.0.1:15432/trainforge_v1_dev com credencialmigrator; não permite destino remoto/legado. Runtime lê editorial e não pode inserir/editar/apagaralimentos, fontes ou lotes. Outros registros privados permanecem separados e sem fixtures na base entregue.

Migration00005 aditiva acrescentou idioma/versãopublicada/operações e trilha de lotes/retiradaalimentar. FK de fonte já existente na00002 foi reutilizada. Idempotência usa hash doartifact, lock transacional e links às versões; reimportação compara os dados já gravados e rejeita versão adulterada. Falha parcial desfaz alimento, fonte e lote juntos. Uma retirada futura é lógica, não apagamento emcascata.

## Evidência real

- [Projeção revisada](food-review-verification.json), [manifesto aprovado](../../../content/manifests/food-approved.json) e [decisão porfonte](../../../content/manifests/food-review-decisions.json).
- [PostgreSQLdescartável](food-import-fixtures-verification.json): idempotência, falha parcial/rollback, versãoadulterada, runtime semescrita; base removida, DBentregue inalterado.
- [Importação real e restore](food-import-verification.json):6369inseridos, reimportação0novos/6369inalterados; contagem/hash de todas as tabelas iguais apósrestaurar o backup novo em outra base, removida depois. Catálogo/usuários/dados anteriores inalterados.
- Backup anterior preservado como checkpoint, sem alegação de restore desse arquivo; **o backup posterior foi efetivamente restaurado e conferido**. Ambos ficam ignorados em.local/backups com caminhos/hashes no recibo.
- Go test/vet e testesPython relevantes passaram. Os testesPostgreSQL executam somente em base com prefixo de fixture e papéis separados; nenhum usuário de demonstração foi criado no DBentregue.

Apenas os dados e o importador foram entregues aqui. Nenhuma rotaHTTP alimentar foi inventada noSwagger: continuam11operações reais de saúde/auth/catálogo. Não houve novoAPK, loginGoogle consentido, deploy, push, contratação ou pesquisa ampla. Android/iOS, idosos/cuidadores e casa/praça/academia permanecem no produto; esta importação não altera os439ativos de exercícios excluídos.
