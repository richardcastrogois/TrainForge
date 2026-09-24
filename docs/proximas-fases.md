# Continuidade acordada

**Estado de 24/09/2026:** [visão integral](planejamento/README.md) e [balanço da etapa 01](planejamento/etapa-01-pesquisa.md) atualizados. Etapa 0 histórica concluída; alinhamento documental realizado; etapa 01 aberta. Próximas intervenções do [Figma](design/ajustes-visao-integrada.md) estão especificadas, sem execução. O autor autorizou publicar a base existente em `richardcastrogois/TrainForge`; implementação, banco, skill global e deploy continuam pendentes.

**Atualização de 17/09/2026:** o pedido atual de planejamento está organizado em [plano de produto e execução](planejamento/README.md). Esse conjunto complementa a sequência histórica abaixo, detalha pesquisa preliminar antes de fechar o Figma e separa aprovação visual, arquitetura/contratos, banco e implementação. As propostas ainda precisam de revisão; não significam que GitHub, skill global, fontes, deploy ou migrações foram concluídos.

## Sequência original — histórico de fases

Os nomes “fase 1/2/3” abaixo pertencem à organização inicial. A execução atual usa **etapas 0–9** no [plano de execução](planejamento/plano-de-execucao.md); não confundir fase 1 com etapa 01.

## Fase 1 — análise inicial

Analisar as três pastas com foco no Flutter, gerar grafos estruturais, documentar fatos/limites e criar versão inicial no Figma. Sua revisão é o ponto de passagem para as próximas etapas. Não houve commit, push, migração de banco, deploy, troca de dependências ou alteração de lógica do app.

## Fase 2 — depois da revisão do autor

### GitHub

Definir se o repositório incluirá só Flutter ou também o backend atual, nome, visibilidade e tratamento do histórico da API. Inventariar arquivos novos, caches, artefatos, configurações de máquina e segredos antes do staging. Preservar os projetos de referência. Publicar só depois de escopo e conteúdo concretos revisados.

### Fontes públicas — pesquisa entregue; homologação pendente

A pesquisa de 23/09 está organizada em [conteúdo](conteudo/README.md). Consultar o catálogo por ID/tema e reutilizar evidências; os parágrafos abaixo descrevem os critérios do trabalho, não tarefas de pesquisa que precisam ser inteiramente refeitas.

Organizar buscas por programas humanos/modalidades, instruções/mídia, alimentação guiada/composição/receitas/rótulos, captura por imagem/dispositivos e acompanhamento. A matriz atual está na etapa 01. Corrida pode precisar de dados/mapas independentes, mas o registo manual inicial pode não exigir API externa.

Para cada candidato, registrar URL oficial, responsável, atualização, preço/cotas, licença de dados e mídia, uso comercial, redistribuição/cache/offline, atribuição, idiomas, unidades, cobertura, autenticação, estabilidade e plano de substituição. “Público”, “free” e “gratuito para estudar” não são a mesma autorização comercial.

Preferir uma integração por necessidade comprovada; não agregar provedores antes de comparar qualidade, duplicação e custo de manutenção. Um documento licenciado pode ser melhor que uma API sem autoria; um catálogo de exercícios não substitui um programa revisado.

### Skill de criação do app

Usar `criador-de-skills` para produzir a skill em `C:\Users\richa\.codex\skills` após a pesquisa. Ela deve registrar stack aprovada, contratos de domínio, fluxo incremental, uso dos grafos, validação, limites de dados/saúde e comandos reais. Nenhuma skill global foi criada/modificada nesta fase 1.

## Fase 3 — antes da implementação de funcionalidades

- Aprovar o que entra/não entra no primeiro lançamento e sequência de expansões.
- Definir arquitetura, organização das pastas, backend, banco, autenticação, estado/offline e fontes.
- Refinar Figma com telas, estados vazios/erro/sem rede e acesso por plataforma.
- Rever bibliotecas/lockfiles/compatibilidade; alterar somente com critérios e validação.
- Elaborar scripts de execução do plano e cenários de teste antes de codificar os incrementos.
- Atualizar documentação e Graphify; revisar conteúdo e commitar.

## Cenários que a fase 3 deve detalhar

Login/expiração/refresh/logout; isolamento entre dois utilizadores; repetição de treino na semana seguinte; início e conclusão concorrentes; perda de conexão no meio do treino; sessão retomada após reinício; troca de plano sem sumir histórico; data inválida e fuso português; falha de fonte externa; fonte sem licença/autoria; exclusão/exportação de dados; release Android assinado; acessibilidade e texto ampliado. São temas para casos de teste futuros, não testes já criados.

## Decisões atuais para revisão

A visão já inclui programas prontos e montagem livre; alimentação, modalidades, didática e capturas integram o produto. Não voltar a perguntar se a intenção se limita à musculação ou se plano próprio basta.

Revisar agora o alinhamento de [R01–R18](planejamento/README.md), a matriz de evidências/lacunas e a sequência de viabilidade. Depois decidir cobertura de lançamento, conteúdo autorizado, métodos de orientação e capacidades condicionais. A disponibilidade atual de orçamento/parceiros não deve ser presumida.

GitHub foi autorizado nesta conversa; preparar/publicar o conjunto revisto não autoriza deploy, alterações de banco ou geração clínica.
