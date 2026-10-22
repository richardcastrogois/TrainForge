# V1-014 — catálogo de consulta entregue

Em22/10/2026, leitura Go/Flutter validada com o lote real já importado:73metadados de movimentos,1fonte,0programas/coleções e0prática/instrução/mídia liberadas. Não houve nova coleta, reimportação ou alteração do lote. Os439ativos excluídos continuam excluídos.

## Contrato executado

`GET /api/v1/catalog/movements` e `/programs` retornam tipos distintos, nunca movimento apresentado como programa completo. Detalhes em `/{id}`, com `versionId` SHA-256 opcional. `GET /api/v1/catalog/filters` retorna facetas/contagens do conteúdo efetivamente visível. Acesso público somente a metadados revisados; sessão Google não é exigida para consulta.

Filtros: `q` (substring literal do título, até100bytes), `environment`, `population`, `modality`, `equipment` e `category` (valores exatos, sem inferir equivalência); `mode=consultation|practice`; `limit` de1a50, padrão20; `cursor` opaco vinculado aos filtros/tamanho. Ordenação estável por assetID. Valores desconhecidos não correspondem a casa/idosos nem a ausência de apoio. Categoria muscular não se transforma em modalidade. Parâmetros desconhecidos/duplicados/controle inválidos retornam400.

O modo practice exige grants e revisão adicionais e hoje retorna0itens. Mesmo quando esses grants existirem, estas rotas são projeções de metadados, sem iniciar prática ou entregar dose/instrução/mídia. Não há endpoint instruction/media implementado.

Projeção explícita preserva título/idioma originais, fonte/URLs, autores, contribuições do nome selecionado, licença/atribuição/condições/alterações/sem garantia, versãohash e versão publicada separadas, categoria/equipamento e requisitos efetivamente informados. Campos desconhecidos são null; dose/unidades/texto instrucional não são entregues porque não estão liberados. Swagger2.0 usa x-nullable nos campos correspondentes. Nenhum payload editorial bruto é serializado.

## Direitos e retirada

Consulta requer operação catalog_metadata tanto na coluna de operações quanto no grant do payload, estado reviewed, rightsVerified e fidelityChecked. Retirada impede exibição. A versão mais recente é escolhida antes da autorização; se retirada/bloqueada, a listagem/detalhe padrão não ressuscita uma antiga. Consulta explícita de uma versão histórica ainda depende das suas permissões/retirada.

ETag é hash da representação e aceita If-None-Match. A autorização/retirada é consultada no PostgreSQL antes de304; cache exige revalidação a cada uso. Flutter recarrega detalhe ao retomar e não reutiliza o cartão antigo quando404. Runtime não pode editar o catálogo. Nenhuma chamada ao fornecedor ou download de vídeo acontece ao abrir a biblioteca.

## Flutter e avaliação

Controller/repository injetados, domínio sem Dio/widgets, loading/error/empty/data, tentativas e paginação sem duplicar IDs. Respostas antigas não substituem a busca nova. Falha de recarga limpa os itens antigos. Biblioteca acessível pela entrada anônima e pela conta conectada; navegação não entra nos geradores/rotas antigas Fastify.

Cards apresentam nome original, fonte/idioma, criadores do nome e licença. Detalhe apresenta autoria/contribuições, fonte/licença com links HTTPS acionados pelo usuário, condições, versão, lacunas e requisitos. Ausência não é preenchida com tradução, dose ou mídia fictícia. Programa vazio não vira movimento renomeado. Texto ampliado2x em320x568 passou em teste widget; leitor de tela físico/iOS seguem pendentes.

## Evidências

- [Verificação de catálogo](catalog-read-verification.json): fixture em DBdescartável removida, paginação/cursor/tipos/filtros, versão imutável, retirada/ETag, runtime sem escrita; HTTP do lote real compara exatamente os73IDs autorizados, créditos completos e zero prática/programas. Contagem/hash reais inalterados.
- Go test/vet,24testesFlutter e analyze semissues. Inspeção visual do APK0.1.1+2 em Android35GooglePlay: biblioteca e detalhe com autoria/licença; capturas somente públicas em.local, sem e-mail/tokens.
- [Swagger gerado](../../../contracts/generated/swagger-v1.json), [reciboAPK](android-auth-checkpoint.json) e [retomada Android](avaliacao-android.md).

Limites: esta história não entrega adesão, prescrição, início/registro de atividade, mídia, alimentação nem aceite Google. V1-016 depende de conteúdo especificamente liberado; V1-022 continua dependendo de015/021. Nenhuma homologação clínica foi inferida da leitura de metadados.
