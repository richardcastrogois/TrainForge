# Fotos de refeições, histórico e troca de aparelho — comparação

Pesquisa documental em **25/10/2026**, a pedido do autor para decidir a persistência de imagens. Fontes: ajuda e políticas dos próprios produtos. Não foram instalados apps, criadas contas, feitos pagamentos ou ensaios de troca de aparelho; os comportamentos abaixo são documentados pelos fornecedores, não auditados por execução.

## Resultado da comparação

**Reconhecer comida, guardar foto no diário e recuperar foto em outro aparelho são capacidades distintas.** A existência de um scanner não comprova as outras duas.

| Produto | Uso da foto e histórico documentados | Troca de aparelho / persistência | Limite da evidência |
|---|---|---|---|
| AteMate (antes YouAte/Ate) | Fotos formam uma linha do tempo; há visão por calendário e refeições | Ajuda diz que a conta preserva a timeline após troca de telefone ou exclusão acidental do app; política informa armazenamento do diário em nuvem | Não foi executado um restore real; retenção segue a política da conta, não promessa de guardar para sempre |
| GreaseFit | Estimativa por foto preenche editor revisável; fotos integram os dados da conta | FAQ declara conta, registros e fotos no servidor, permitindo acompanhar o usuário entre aparelhos | O mesmo FAQ diz que registro offline ainda não está disponível; não copiar essa limitação para o TrainForge |
| Cronometer | Photo-Logging identifica alimentos, permite trocar/adicionar/remover e ajustar quantidades. Photo Notes é recurso separado que salva uma foto numa nota do diário | Política declara armazenamento em nuvem. A ajuda permite reabrir a foto da nota salva | Não encontrei, nas páginas consultadas, garantia de que a imagem original de cada Photo-Logging seja arquivada automaticamente e recuperada em outro aparelho |
| MyFitnessPal | Meal Scanner oferece candidatos, ajuste de porção e busca do que não foi reconhecido antes de registrar | A documentação consultada do scanner não comprova uma galeria restaurável das fotos das refeições | Não extrapolar a política de fotos de progresso corporal para fotos de refeições; são recursos diferentes |

## Fontes primárias e observações

### AteMate

- [Why Create an Account](https://help.atemate.com/en/articles/6577445-why-create-an-account): conta e sincronização para preservar a timeline em troca de telefone/reinstalação. Artigo datado de21/08/2026.
- [Timeline](https://help.atemate.com/en/articles/3738014-what-s-on-my-timeline-and-how-to-build-it): fotos constroem o diário visual; documenta também agrupamento opcional de refeições por intervalo.
- [Calendar View](https://help.atemate.com/en/articles/7194517-calendar-view): visualizações de sequência, calendário e resumo do dia.
- [Privacidade](https://www.atemate.com/privacy), atualizada em02/10/2026: diário inclui fotos; Google/Firebase presta armazenamento e infraestrutura. Há regras de conta ativa/exclusão/inatividade. Nomes de fornecedores explicam esse produto e não são seleção de provedor para o TrainForge.

Princípio transferível: uma conta pode recuperar um diário visual, mas a foto precisa fazer parte da persistência sincronizada, com política de ciclo de vida. Não adotar agrupamento automático por tempo sem uma regra de produto aprovada.

### GreaseFit

- [FAQ oficial](https://greasefit.com/faq), seções conta, estimativa por foto, armazenamento e offline: declara fotos e registros no servidor e uso da conta entre dispositivos. A estimativa deve ser revisada antes de salvar; registro offline ainda consta como pendente.

Princípio transferível: manter a referência da imagem ligada ao registro autoritativo. Sincronização por conta e capacidade offline precisam de tratamento próprio; ter um servidor não resolve ausência de conexão.

### Cronometer

- [Photo-Logging](https://support.cronometer.com/hc/en-us/articles/39013533811092-Mobile-Photo-Logging): retorna alimentos para revisão e permite alterar itens/quantidades antes da inclusão no diário.
- [Photo Notes](https://support.cronometer.com/hc/en-us/articles/360018956451-Mobile-Add-a-Note): foto salva numa nota pode ser reaberta, substituída ou excluída.
- [Privacidade](https://cronometer.com/privacy/): documenta uso de nuvem e tratamento de fotos por analytics/fornecedores. Isso não equivale a comprovar o caminho de recuperação da foto original de todo scan.

Princípio transferível: separar a análise temporária de uma imagem da decisão de mantê-la como anexo do histórico. A mesma foto pode servir às duas finalidades, mas cada ciclo deve ser explícito.

### MyFitnessPal

- [Meal Scanner](https://support.myfitnesspal.com/hc/en-us/articles/360045761612-How-to-use-the-Meal-Scanner), atualizado em16/09/2026: alimentos sugeridos, quantidade/porção editável, inclusão manual de itens ausentes e confirmação.
- [Atualização do Meal Scan](https://blog.myfitnesspal.com/meal-scan/), de09/10/2025: descreve opções de uso de câmera/upload. A afirmação de não salvar/uploadar dados aparece no trecho de uso da câmera em tempo real; não generalizar essa frase para todos os fluxos atuais.
- [Fotos de progresso](https://support.myfitnesspal.com/hc/en-us/articles/360032625271-Progress-Photos-FAQs): documenta sincronização para outro tipo de imagem. Não foi usada como prova de backup de fotos de refeições.

Princípio transferível: revisar os alimentos e quantidades antes de registrar. Guardar uma imagem para recordação/diário é um requisito adicional ao scanner.

## Recomendação para o TrainForge — proposta, ainda não decidida

Para o objetivo do autor (histórico visual útil e continuidade ao trocar de celular), recomendo **persistência privada das fotos vinculada à conta, com cópia/cache local**, além da persistência dos consumos. Esta é uma recomendação de comportamento e arquitetura; não autoriza hospedar, contratar, selecionar provedor ou enviar fotos pessoais a terceiros.

| Camada | Responsabilidade proposta |
|---|---|
| PostgreSQL | Refeição, itens confirmados, quantidade/unidade, base/versão, cálculo, revisões, titularidade e referência/estado da imagem |
| Armazenamento privado de arquivos | Imagem e miniatura sincronizadas; acesso autorizado e política de retenção/exclusão |
| Aparelho | Captura, rascunho/fila protegidos quando aprovados, miniaturas e cache recuperável; não ser a única cópia definitiva de uma foto prometida como recuperável |

Exemplo de comportamento desejado: foto e refeição já sincronizadas → troca de aparelho → login na mesma conta → registros retornam → miniaturas são obtidas conforme necessário. Rascunho que nunca saiu do aparelho não deve ser anunciado como recuperável; mostrar envio pendente, sincronizado ou falhou e permitir retentativa sem duplicar consumo.

Apagar cache não deve apagar refeição. Excluir uma foto deve ter semântica explícita sobre o registro; faltar imagem não apaga o alimento/quantidade/cálculo. Exclusão da conta precisa cobrir anexos e filas, com o mesmo tratamento honesto de backups já adotado pelo projeto.

O original em resolução máxima não precisa ser preservado indefinidamente para oferecer histórico visual. Compressão/miniatura, limites e retenção precisam ser definidos e medidos; não fixar custo ou prazo sem evidência. Não usar endereço local de arquivo ou URL temporária como identidade permanente da refeição.

Pode-se preparar e ensaiar a arquitetura com armazenamento local isolado do backend. Isso não é sincronização de produção já entregue nem dispensa disponibilidade futura do serviço para recuperação pela conta. Hospedagem continua adiada por decisão do autor.

Alternativa válida, se o autor preferir: registros pela conta e imagens locais com backup/exportação manual. É preciso mostrar claramente a possibilidade de perder imagens não copiadas; essa alternativa não oferece a mesma experiência de recuperação automática.

## Decisões Q2 já recebidas e pendências

- **Aprovado:** agrupar os alimentos por refeição e oferecer também a visualização por alimento. As duas visões usam os mesmos registros, sem duplicar consumo ou nutrientes; uma refeição pode conter vários itens/quantidades.
- **Fotos:** autor pediu esta pesquisa antes de decidir. A recomendação acima continua proposta; não foi marcada como escolha confirmada.
- **Confirmado após clarificação:** “Entregar histórico visual, análise nutricional e dicas revisadas juntos na primeira versão”. V1-046 registra o conjunto, sem adiar análise/dicas silenciosamente; regras/fontes/revisão e implementação ainda precisam ser feitas.

## Critérios a levar para banco/backend/frontend

1. Identidade de refeição e relação com itens/arquivo, sem inventar agrupamento dos consumos antigos; entradas antigas sem contexto continuam identificáveis.
2. Duas visualizações consistentes e editáveis sobre o mesmo registro; correção de quantidade afeta os resumos apropriados uma vez.
3. Candidato de reconhecimento separado de consumo confirmado; quantidade informada pelo usuário e correspondência com base real.
4. Titularidade de anexos, limites, compressão, metadados de localização, fila/retentativa, exclusão e backup definidos antes da implementação privada.
5. Ensaio de recuperação em outro cliente com dados autorizados e base isolada; somente depois afirmar que recupera fotos.
6. Histórico, análise nutricional e dicas revisadas no mesmo aceite; mostrar período/cobertura/desconhecidos e não inferir deficiência de diário incompleto. As visões por refeição e alimento compartilham os mesmos dados (V1-045/046).

Não foram copiadas interfaces, imagens ou marcas. Esta pesquisa compara capacidades de produtos, não escolhe API de reconhecimento nem libera uso das suas bases ou modelos no TrainForge. O [registro de fornecedores de exercícios](../../conteudo/opcoes-apis-exercicios.md) não foi reaberto.

[Decisões do piloto](decisoes-piloto.md) · [Trilha](trilha-implementacao.md) · [Backlog](backlog.md)
