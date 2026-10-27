# Operação de nomes alimentares revisados — V1-048

Ferramenta local em services/api/cmd/food-names, conferida em **26/10/2026**. Não cria traduções nem verifica automaticamente a identidade do revisor ou a validade de uma licença. O runtime HTTP não recebe permissão de publicar ou retirar nomes; não há endpoint editorial público.

## Cobertura atual

[Recibo de operações e cobertura](../execucao/v1/food-names-operations-verification.json): os quatro catálogos estão na revisão 0, com **0 nomes revisados ativos e 6.369 fallbacks originais por idioma**. As fontes visíveis atuais são Ciqual 2025 (3.484 versões) e CoFID 2021 (2.885). Isso é cobertura sobre a base local atual, sem afirmar cobertura alimentar global ou qualidade linguística.

A interface tem 493 mensagens por idioma. Tradução de interface não é tradução do nome, preparo ou composição da fonte. Inglês original de uma fonte também não é contado como nome editorial revisado. A ausência de pacote aprovado mantém o original. Nenhum nome real foi publicado pelo agente.

## Pacote de publicação

Um diretório por alimento, versão e idioma, fora do Git quando contiver documentos privados. Os arquivos são lidos como bytes, com nomes fixos; a ferramenta não busca URLs nem executa conteúdo dos documentos.

| Arquivo | Conteúdo e limite |
|---|---|
| record.json | Contrato trainforge.food-names/1; até 64 KiB brutos e 32 KiB canônicos |
| review.txt | Documento de revisão humana, até 1 MiB; hash SHA-256 exato em review.evidenceSha256 |
| rights.txt | Evidência de direitos de exibição e busca dos nomes/aliases, até 1 MiB; hash em review.rightsEvidenceSha256 |

O record contém foodId/foodVersion exatos, nameOriginal/nameLocale copiados sem alteração da fonte, locale entre pt-BR/pt-PT/en/es, name e até 16 aliases. review contém reviewerRef, reviewedAt, humanReviewed, ambos os hashes, licenseLabel/licenseUrl, attribution, scope=food_names_and_aliases e permissões displayAllowed/searchAllowed. [Modelo e limites](../../services/api/internal/nutrition/names.go).

Campos desconhecidos ou duplicados, Unicode inválido/controles nos nomes revisados, nomes/aliases ambíguos, evidência ausente/alterada, tamanho excessivo e datas de revisão futuras são recusados. O idioma é exato: pt-BR não aprova pt-PT por inferência. Originais, ID, versão, hash, base, nutrientes e consumos não são reescritos.

Antes de publicar, um operador autorizado deve verificar a identidade do revisor e os documentos, o alimento/preparo/versão corretos, o idioma, todos os aliases e o direito de exibir e pesquisar esses textos. Hash coincidente prova somente os bytes. Um campo humanReviewed=true, um nome de revisor digitado ou a saída de IA não substituem essa verificação. Reter o pacote original e o recibo em armazenamento controlado; não publicar documentos privados no Git. A ferramenta não fornece repositório durável de evidências nem autenticação de revisores.

## Conferir sem banco e publicar

Na raiz do repositório, o comando abaixo faz somente preflight de arquivos. Não lê credenciais nem abre conexão; não confirma que o alimento existe no banco. Substituir o caminho pelo pacote real, nunca por uma fixture de teste.

~~~powershell
./tools/go-api.ps1 -GoArgs @('run','./cmd/food-names','--operation','check-publish','--package','C:/caminho/pacote-revisado')
~~~

O recibo informa packageSha256, versão editorial e escopo structure-and-matching-evidence-only. Qualquer byte alterado invalida essa confirmação. A impressão digital do pacote é distinta da versão canônica do nome.

A escrita exige TF_FOOD_NAMES_DATABASE_URL configurada no processo com a credencial local de trainforge_migrator, alvo literal 127.0.0.1:15432/trainforge_v1_dev, e confirmação do pacote e da referência do revisor verificada pelo operador. Não colocar senha na linha de comando, no Git ou no chat. O comando não inicia serviços, aplica migrations nem configura credenciais. Alvos remotos, outros bancos/papéis e overrides de sessão são recusados. O alvo descartável estrito trainforge_v1_names_test_<12 hex> existe somente para testes isolados.

~~~powershell
./tools/go-api.ps1 -GoArgs @('run','./cmd/food-names','--operation','publish','--package','C:/caminho/pacote-revisado','--confirm','SHA256_DO_PREFLIGHT','--verified-reviewer-ref','REFERENCIA_VERIFICADA')
~~~

A confirmação é um reconhecimento explícito do operador, vinculado ao pacote; não é uma credencial de autorização. O limite de escrita é a conta PostgreSQL privilegiada, mantida fora do app. A API, Flutter e o runtime não recebem essa conta. Não executar publish sem conteúdo realmente revisado e autorização aplicável.

A transação confere a versão pública original e a visibilidade, serializa por identidade, grava versão imutável e atualiza a revisão do idioma atomicamente. Repetição idêntica retorna inserted=false, sem duplicar nem incrementar revisão. inserted=true significa registro editorial inserido, não promessa de exibição atual: a fonte pode ser retirada depois. Republicar a mesma versão retirada não a revive; correção exige nova revisão rastreável.

## Retirada

Novo pacote com record.json no contrato trainforge.food-name-withdrawal/1 e decision.txt de até 1 MiB. O registro identifica foodId, foodVersion, locale e nameVersion exatos, reason, reviewerRef, reviewedAt e evidenceSha256 correspondente a decision.txt. A decisão canônica é limitada a 1.000 bytes e fica imutável no campo reason da tabela de retiradas; o documento permanece no pacote retido. [Modelo](../../services/api/internal/nutrition/names_withdraw.go).

Usar check-withdraw antes de withdraw, com as mesmas flags --package, --confirm e --verified-reviewer-ref da publicação. Somente a versão indicada é retirada; outras identidades/idiomas permanecem. Reenvio idêntico não altera a revisão; outra razão não sobrescreve a decisão original. A retirada é permitida mesmo se a fonte já estiver indisponível. A leitura volta ao original, sem ressuscitar tradução antiga. O histórico editorial não é apagado.

## Cobertura somente de leitura

Com TF_FOOD_NAMES_DATABASE_URL usando trainforge_runtime no mesmo alvo local:

~~~powershell
./tools/go-api.ps1 -GoArgs @('run','./cmd/food-names','--operation','coverage')
~~~

Uma transação repeatable-read/read-only agrega versões públicas visíveis mais recentes por idioma, revisão do catálogo, fonte e versão publicada. Separa storedActiveNames, withdrawnLatestNames e originalFallbacks; não conta versões editoriais históricas como alimentos adicionais. Não lê nomes particulares, usuários ou registros de consumo. Não confere qualidade linguística: relata linhas editoriais armazenadas e elegíveis, conforme o campo basis do recibo. A projeção de leitura do app ainda valida cada payload/hash ao exibi-lo.

## Evidência e pendências

Sete cenários Go da ferramenta cobrem preflight sem credenciais, bytes alterados, limites, JSON ambíguo, confirmação, alvo/papel e retirada. SQL descartável executa o binário real de publicação/retirada, retries, permissões do runtime, revisão monotônica e cobertura; depois remove somente o banco de teste. A cobertura da base real foi consultada com o papel runtime e os dados comparados antes/depois; cluster inicialmente parado foi novamente parado. [Execução reproduzível](../../tools/verificar_nomes_alimentares.py).

Não houve novo login, consumo, instalação de APK, migration ou publicação real neste incremento. Go test ./... e go vet ./... passaram; integrações não habilitadas na suíte comum são skips, não aprovação. O ensaio SQL explícito tem seu próprio recibo. Swagger continua 0.6.1 / 25 operações: esta ferramenta não adiciona rota pública.

V1-048 continua doing pelos aceites nativos e pelo uso editorial real quando houver pacote humano aprovado. Android: APK 0.3.3+16 preparado, sem dispositivo ADB conectado. iOS: execução nativa não disponível no Windows. Não contratar revisor, serviço ou hospedagem por inferência; não inventar traduções para preencher a cobertura.
