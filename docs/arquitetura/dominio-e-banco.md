# Domínio e banco — modelo lógico proposto

Este é o insumo de `V1-009`, **não uma migration aplicada**. PostgreSQL continua recomendado. O esquema Prisma atual está no backend externo e é inventariado no painel.

| Entidade proposta | Responsabilidade e relação |
|---|---|
| Identity / User / AuthSession | Provedor+issuer+sub identifica login; usuário é titular; sessão guarda hash/rotação/revogação por dispositivo |
| Source / Attribution / RightsRecord | Origem primária, autores/contribuições, evidência e permissões por ativo/versão; licença desconhecida é estado explícito |
| Movement / MovementVersion | Conceito e variante concreta com população, ambiente e equipamentos; não confundir gesto com programa |
| InstructionVersion / MediaAsset | Expressão instrucional e mídia separadas, idioma, autoria, revisão, direito de exibir/redistribuir e alternativa acessível |
| Program / ProgramVersion | Unidade editorial estável e versão imutável; pode ser programa integral ou coleção modular explicitamente identificada |
| ProgramSession / PrescriptionItem | Ordem e dose da versão, referência exata ao componente/instrução, progressão permitida e apoio exigido |
| Enrollment / ScheduleOccurrence | Adesão de um titular a uma versão, opções permitidas e ocorrência em data/fuso; não duplicar a prescrição por usuário |
| ActivitySession / ActivityEvent | Execução realmente iniciada e eventos confirmados: pausa, medida, conclusão parcial/completa; autor do registro separado do titular |
| IdempotencyRecord | Usuário+operação+chave, hash do request e resultado; reenvio igual recupera resposta, payload divergente é conflito |
| Food / FoodVersion / NutrientValue | Alimento/preparo e versão da fonte, base por100g/100ml, nutrientes com ausência distinta de zero |
| FoodEntry | Quantidade e unidade confirmadas, data/fuso, alimento/versão e fatores usados no cálculo; edição rastreável |
| CareRelationship (posterior) | Vínculo e autorização explícitos para pessoa assistida; não pressuposto pelo perfil “cuidador” |

## Dose e unidades

Representar campos opcionais/tipados: sets, repetitions, holdSeconds, durationSeconds, distanceMeters, side, restSeconds, tempo, intensidade conforme a fonte e regra de progressão quando existir. A lista é proposta de modelagem, não autorização para preencher os campos de todo componente. `null` significa ausente/não demonstrado; zero representa valor real quando válido. Dose prescrita, tempo do timer e realizado pelo usuário são coisas diferentes.

Não transformar oito variantes ReViEEW em circuito novo ou transferir a eficácia de um programa a uma peça. N15 guarda onze componentes para cuidadores; ES2019-DOM-01 guarda cinco movimentos para idosos em casa, em pacote separado. Instrução, apoio, público e direitos continuam vinculados a cada versão.

## Integridade e tempo

IDs estáveis opacos; foreign keys para versões; timestamps UTC e fuso IANA para interpretar datas da agenda. Data local não deve ser deduzida do relógio do servidor. Uma ocorrência não é “toda segunda-feira para sempre”. Estados e transições devem ter contrato explícito, incluindo planejado, iniciado, pausado, parcial, concluído, não feito e descanso.

Exemplos de invariantes a fechar/testar: chave idempotente única por titular/operação; no máximo uma execução aberta por ocorrência; ordem de item única por sessão editorial; identidade única por provedor/issuer/sub; token hash único e rotação consumida uma única vez. Não exigir uma única sessão de autenticação para toda a conta. Decidir política de múltiplas adesões sem copiar o índice antigo de “um plano ativo” automaticamente.

Toda query privada usa o titular autorizado. Histórico preserva versão editorial mesmo após retirada de publicação. Retirada pode impedir novas execuções; a política de exibição histórica respeitará direitos e retenção. Dados de saúde e registros de outra pessoa não são conteúdo público do catálogo.

## Migrations e recuperação

API Go será a única responsável pelo schema novo. Primeiro banco isolado; migrations pequenas forward, revisão SQL, testes concorrentes e backup restaurável. Se houver dados reais no legado, inventariar contagens/estrutura com autorização, mapear campos (incluindo `completeAt` → `completedAt`) e ensaiar importação sem sobrescrever o original. Não inventar que existem usuários/dados para migrar.

`V1-010` deve registrar versão PostgreSQL suportada, limites de pool, extensões justificadas e papéis runtime/migration separados. Backup só conta como validado depois de restaurado e conferido em base separada. Não usar `docker compose down -v` ou reset de volume para “corrigir” migration.
