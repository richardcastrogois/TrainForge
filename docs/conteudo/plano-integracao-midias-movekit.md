# Integração das mídias MoveKit — orientação para o Claude

Alinhamento do autor em **19/11/2026**. Repositório: `C:/dev/TrainForge/trainforge`. Escopo exclusivo: receber, analisar e integrar as demonstrações de exercícios do pacote comprado. Documento de execução futura; não registra compra, download ou implementação concluídos.

## Decisão principal

**Primeiro receber e inspecionar o pacote real; depois definir e implementar os ajustes.** O autor já está com o dinheiro e pronto para comprar. Não antecipar alterações de banco, contrato, dependências ou player com base em uma estrutura hipotética do fornecedor.

A análise prévia identificou os pontos do código que provavelmente serão afetados. Ela serve como mapa de investigação, não como especificação definitiva do pacote. O objetivo é evitar trabalho provisório que precise ser refeito assim que os arquivos chegarem.

Na conversa usamos “GIFs”. A [avaliação anterior](avaliacao-movekit-2026-10-29.md) registrou uma oferta de **MP4 H.264, posters e metadados JSON/CSV**. Conferir o que foi efetivamente adquirido. Não converter vídeos para GIF por causa do termo usado na conversa.

## Quando começar cada etapa

| Momento | Ação | Condição para avançar |
|---|---|---|
| Antes da compra | O autor confere a oferta e os termos vigentes, incluindo exibição comercial, hospedagem própria e cache/offline | Saber qual pacote/licença será adquirido |
| Compra feita, arquivos ainda indisponíveis | Registrar somente o que estiver confirmado; aguardar os arquivos | Pacote acessível localmente |
| Pacote recebido | Inspecionar originais, metadados e licença, sem mudar a aplicação | Inventário real e lacunas identificadas |
| Inventário concluído | Comparar o pacote com o código atual e escrever o plano concreto | Arquivos, contratos, migrations e validações definidos |
| Plano concreto definido | Implementar um exercício completo, da importação à reprodução | Fluxo validado com uma mídia real licenciada |
| Primeira integração validada | Ampliar a importação e conferir o conjunto | Relatório de cobertura, pendências e testes |
| Primeira entrega online estabilizada | Avaliar cache/offline quando permitido e necessário | Direitos e comportamento definidos, com medição de armazenamento |

Se o pacote ainda não estiver disponível, o ponto de parada é esse: registrar que a inspeção depende dos arquivos. Não substituir a inspeção por scraping de previews, nova pesquisa ampla ou implementação especulativa.

## Contexto que deve ser lido no início

Ler as instruções vigentes em [AGENTS.md](../../AGENTS.md), o [handoff](../execucao/v1/handoff.md), o [escopo](../execucao/v1/escopo.md), as histórias relacionadas no [backlog](../execucao/v1/backlog.json) e a [arquitetura](../arquitetura/README.md). A solicitação atual do autor define a prioridade desta frente de mídia.

Conferir `git status` e os arquivos atuais antes de editar; outro agente pode ter avançado desde esta análise. Não repetir etapas de alimentação ou alterar outras frentes para cumprir este documento. Preservar dados, backups e alterações de terceiros.

Este documento é a referência de sequência para esta integração. O briefing anterior no diretório pai era uma proposta de preparação antecipada; a decisão posterior aqui registrada prevalece: **inspeção do pacote antes de implementação**.

## Etapa 1 — Receber e inspecionar os arquivos

### Onde guardar

Usar como convenção proposta, após conferir espaço e a localização informada pelo autor:

```text
.local/movekit/
  originais/       ZIPs e arquivos entregues, preservados sem alteração
  licenca/        termos aplicáveis, certificado e comprovantes privados
  trabalho/       extração e processamento necessários
  inventario/     listagem técnica e relatórios locais
```

`.local/` já é ignorado pelo Git. Se os arquivos já estiverem em outro local privado, inspecionar de lá primeiro e evitar duplicação desnecessária. Não mover/apagar originais por conveniência e não versionar o pacote comercial, certificados, comprovantes ou links privados de download.

### O que conferir

1. Identificação do pacote e da licença efetivamente recebidos; permissões e restrições aplicáveis à integração pretendida. Preço e quantidade do levantamento de outubro são históricos, não dados atuais do pacote.
2. Estrutura dos ZIPs/pastas e tamanho total comprimido/extraído. Listar o conteúdo antes de extrair e rejeitar caminhos que escapem do diretório de trabalho.
3. Formato real do JSON/CSV: encoding, campos, tipos, IDs, idiomas, unidades, valores ausentes e registros duplicados.
4. Correspondência entre cada exercício, vídeo e poster: quais chaves ou nomes de arquivo estabelecem o vínculo e quais registros estão incompletos.
5. Formatos, tamanhos, hashes, codecs, resolução, duração e eventuais variantes. Fazer inventário automatizado de todos os arquivos e conferir visualmente uma amostra representativa antes da primeira integração.
6. Textos fornecidos e condições para usá-los/traduzi-los. Distinguir nome, descrição e instrução de uma prescrição de treino.

### Entrega desta etapa

Registrar um resumo factual nesta documentação, sem copiar conteúdo comercial em massa: arquivos/formato recebidos, contagens medidas, campos de integração, correspondência arquivo/ID, problemas e dúvidas materiais. Detalhes com nomes privados, comprovantes e links de acesso ficam no inventário local.

Não inventar IDs estáveis, schema, traduções ou permissões que os arquivos/termos não comprovem. Se houver lacuna, separar o trabalho independente do ponto que depende de esclarecimento.

## Etapa 2 — Localizar os ajustes no código atual

Os caminhos abaixo foram conferidos em 19/11/2026. Reavaliar antes de editar. Eles indicam responsabilidades e restrições reais, não obrigam a alterar todos os arquivos.

| Responsabilidade | Onde investigar | O que existe e o que decidir após a inspeção |
|---|---|---|
| Modelo editorial de conteúdo | `content/schemas/editorial-v1.schema.json` e `tools/conteudo_editorial.py` | Já reconhecem o tipo `media` e a operação `media_display`. O campo `content` é genérico; definir um contrato técnico de mídia com validação efetiva |
| Persistência do catálogo separado | `services/api/internal/catalogschema/` | O CHECK atual aceita apenas `movement`, `program` e `collection`. Decidir a representação da mídia e criar nova migration se necessário; não editar migrations já aplicadas |
| Publicação, versões e retirada | `services/api/internal/catalogauthority/snapshot.go` e `publish.go` | A validação e as consultas de snapshot também limitam os tipos. Fazer modelo, publicação e retirada evoluírem de forma coerente |
| Espelho e compatibilidade | `services/api/internal/catalogbridge/` e `services/api/cmd/catalog-transition/` | Conferir como o conteúdo novo participa do digest, do espelho e da verificação de revisão; não publicar uma estrutura que quebre essas garantias |
| Importação editorial existente | `services/api/internal/catalog/import.go` e `services/api/cmd/import-content/` | O importador atual aceita somente consulta revisada e `catalog_metadata`. Criar um caminho explícito para o pacote de mídia, mantendo a proteção do importador de consulta |
| Leitura do catálogo | `services/api/internal/catalog/read.go`, `postgres_read.go` e `handler.go` | A resposta atual é uma projeção de metadados; não contém dados de reprodução e fixa mídia como indisponível. Definir como apresentar mídias disponíveis sem liberar prática automaticamente |
| Composição do servidor | `services/api/cmd/api/main.go` e `services/api/internal/catalogruntime/runtime.go` | Definir quem fornece metadados, quem autoriza e quem entrega bytes. Não espalhar uma segunda fonte de verdade entre os dois bancos |
| Contrato e leitura Flutter | `lib/features/catalog/domain/catalog_entry.dart` e `data/catalog_repository.dart` | Ainda não modelam uma mídia reproduzível. Acrescentar tipos e métodos conforme o contrato real, preservando exercícios sem mídia |
| Tela inicial da integração | `lib/features/catalog/presentation/catalog_detail_page.dart` | Usar os detalhes de um exercício como primeira superfície de demonstração; não integrar simultaneamente toda a jornada de treino |
| Reprodução e dependências | `pubspec.yaml` e componente Flutter a definir na implementação | Ainda não há player de vídeo. Escolher uma dependência compatível com Android/iOS e criar um componente reutilizável |
| Contratos documentados | `contracts/generated/` e ferramentas de geração Swagger existentes | Atualizar pelos geradores após definir e implementar as rotas; não editar derivados à mão |

### Decisões técnicas que precisam sair desta etapa

- Como o ID do fornecedor se relaciona com um movimento TrainForge, mantendo variação, equipamento e versão. Nome parecido pode sugerir correspondência; não deve aprová-la automaticamente.
- Quais dados ficam no banco: identidade, versão, vínculo, hash, propriedades do arquivo, direito de uso e chave de armazenamento. Preferir arquivos fora das colunas binárias do PostgreSQL.
- Como ficam representados vídeo, poster, variantes e ausência de mídia, usando somente propriedades comprovadas no pacote.
- Como serão publicação, substituição e retirada; metadados públicos não tornam o arquivo comercial automaticamente público.
- Onde os arquivos serão servidos na primeira prova. Armazenamento privado local é uma opção para desenvolvimento; hospedagem final é uma decisão distinta.
- Como o acesso é autorizado e como o player busca o arquivo. O desenho precisa corresponder aos termos aplicáveis, sem credenciais do fornecedor embutidas no app.

**Atenção ao transporte:** a bridge atual do catálogo foi feita para JSON, limita o corpo a 2 MiB e usa timeout de dois segundos. Não encaminhar vídeos por esse mecanismo sem um desenho próprio. A entrega de mídia precisa de streaming, memória limitada, suporte a Range quando aplicável e timeouts compatíveis com reprodução.

### Entrega desta etapa

Atualizar este documento com a comparação entre o pacote real e o código: ajustes necessários, arquivos afetados, contratos escolhidos, eventual migration, testes e ordem de execução. Não criar antecipadamente uma camada para cada hipótese.

O Claude deve continuar pelos ajustes definidos dentro do escopo solicitado, sem pedir confirmações para cada escolha técnica reversível. Perguntar somente por informação/decisão material que realmente falte, preservando o progresso independente.

## Etapa 3 — Integrar um exercício de ponta a ponta

Escolher uma mídia real recebida cuja identidade, licença e vínculo com o movimento estejam conferidos. A seleção serve para validar a cadeia completa antes de processar o restante.

Implementar nesta ordem:

1. **Persistência e contrato:** criar a estrutura mínima necessária, preservar versões existentes e manter mídia/direitos/vínculo explícitos. Ensaiar migrations em banco descartável antes de qualquer alteração em base com dados reais.
2. **Importação:** adicionar modo de conferência sem gravação e depois importação idempotente do exercício selecionado. Validar arquivo, metadados e vínculo; registrar ausências em vez de preencher por inferência.
3. **Entrega:** fornecer metadados e acesso ao vídeo/poster por contrato explícito. Validar caminhos, autorização, retirada, limites e Range; manter arquivos privados fora do Git e fora de endpoints de exportação de outros domínios.
4. **Flutter:** apresentar poster, carregamento, reprodução, pausa, repetição quando apropriada, falha e nova tentativa. Pausar ao sair da rota/ir para background, descartar o controller e invalidar respostas/acessos conforme a troca de conta.
5. **Validação:** reproduzir a mídia pelo app usando o servidor e os arquivos da integração; registrar ambiente, comandos, resultado e limites. Não basta abrir o vídeo separadamente no computador.

A primeira reprodução pode usar fixtures próprias nos testes automatizados. Elas são auxiliares da implementação após a inspeção; o aceite da primeira integração exige uma mídia real licenciada, sem publicá-la no repositório de testes.

### Critérios para ampliar

- O exercício correto recebe o vídeo e poster corretos, sem associação apenas por nome aproximado.
- A mídia funciona no caminho completo importação → banco → API → Flutter.
- Exercício sem mídia continua funcionando e não mostra demonstração fictícia.
- Reimportar a mesma versão não duplica conteúdo.
- Mídia indisponível/retirada tem comportamento verificável; um erro não ativa silenciosamente outro arquivo.
- Acesso e reprodução respeitam o contrato escolhido, inclusive expiração quando houver acesso temporário.
- Sair da tela e colocar o app em segundo plano não deixa reprodução oculta nem recursos pendurados.
- Assistir ao vídeo não registra séries, repetições ou conclusão de treino automaticamente.

O documento atual não autoriza gerar/instalar APK nesta rodada de documentação. Quando a execução for solicitada, seguir a autorização vigente para build e dispositivo, distinguindo testes automatizados de validação nativa ainda pendente.

## Etapa 4 — Ampliar para o pacote

Com a primeira integração validada, importar o conjunto pelo mesmo caminho, sem inserir registros manualmente para cada vídeo.

Produzir relatório com: recebidos, importados, já existentes, duplicados, incompletos, rejeitados e pendentes de mapeamento. Conferir cobertura e correspondência arquivo/registro. Não forçar todos os exercícios novos nos movimentos existentes para alcançar uma porcentagem de importação.

Validar formatos e variantes efetivamente encontrados; conferir amostra visual representativa e todos os erros do inventário. Medir tamanho armazenado, tempo de importação, tempo de início da reprodução e comportamento de rede. Manter originais e hashes para rastrear atualizações futuras.

Não embutir toda a biblioteca no APK por padrão. Escolher distribuição com base no tamanho medido e no uso pretendido; qualquer decisão sobre pacote completo ou download seletivo precisa ser explícita.

## Etapa 5 — Cache/offline e integração com treino

Avaliar cache persistente/offline depois da primeira entrega, conforme licença e necessidade do produto. Se permitido e solicitado, definir limite de armazenamento, download seletivo, arquivos temporários, integridade, retomada, limpeza e tratamento de retirada. Não tratar criptografia como garantia de impossibilidade de extração.

Mídia, instrução e prática são liberações distintas. Não inventar dose, séries, descanso, programa ou adequação clínica para aproveitar os vídeos. Integrar a reprodução à execução de treino somente quando o conteúdo e a jornada correspondentes estiverem disponíveis, preservando os critérios existentes em `services/api/internal/activity/`.

## Verificação e registro por incremento

Executar checks proporcionais aos arquivos alterados: testes de importação/idempotência, direitos/retirada, publicação/compatibilidade do catálogo, entrega/Range e modelo/player Flutter. Para migrations, usar PostgreSQL descartável; para reprodução, registrar o teste nativo real quando realizado.

Usar os comandos canônicos do repositório, incluindo Go test/vet e Flutter analyze/test quando aplicáveis. Atualizar Swagger e documentação pelos geradores. Não anunciar integração SQL, reprodução física, iOS ou offline como validados apenas porque unitários passaram.

Ao concluir cada incremento, registrar neste documento o que mudou e as evidências, atualizar o ponto de retomada do handoff e as histórias afetadas no backlog conforme critérios efetivamente satisfeitos. Não criar um segundo backlog aqui nem declarar compra, importação completa ou prática liberada por inferência.

Esta frente não inclui pagamento pelo agente, criação de conta, contato com fornecedor, contratação de hospedagem, alterações alimentares ou publicação. A compra será realizada pelo autor. Este alinhamento não acrescenta autorização de commit/push; seguir a instrução vigente do autor quando a implementação for solicitada.

## Mensagem para iniciar o trabalho com o Claude

> Leia `docs/conteudo/plano-integracao-midias-movekit.md` e as instruções atuais do repositório. Vamos integrar as mídias MoveKit conforme o alinhamento: primeiro inspecionar o pacote real, depois definir os ajustes e implementar um exercício completo antes de ampliar a importação. Comece verificando onde estão os arquivos e a licença recebidos. Se ainda não estiverem disponíveis, registre essa dependência sem antecipar alterações estruturais. Com o pacote disponível, faça o inventário e a comparação com o código; prossiga pelos incrementos dentro do escopo solicitado, registrando arquivos, testes e pendências. Preserve outras frentes e não confunda reprodução da demonstração com liberação automática de treino.
