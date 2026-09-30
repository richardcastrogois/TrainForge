# TrainForge / SeNAS

Apresentação de 7 slides. Tempo sugerido: 10 minutos.

## Preencher antes de apresentar

- Cliente, integrantes, orientador e código da equipe na capa.
- Inserir a logo oficial do LTD no local indicado. A logo não foi fornecida nem localizada nas fontes institucionais consultadas.
- Confirmar a dor com o cliente e consolidar o SDD recebido, que está sem preenchimento.
- Confirmar o fluxo de uso de IA efetivamente adotado pela equipe.

## Identidade visual

Fundo branco e texto grafite, com magenta e laranja em detalhes. Logo da UniMetrocamp Wyden extraída da capa do documento institucional PPC Enfermagem 2026, sem alteração, sobre fundo branco. Tipografia de apresentação: Arial, escolhida por legibilidade; não é declarada como fonte institucional oficial.

## Roteiro

### 1. Apresentação

Tempo: 45 segundos.

Apresente o evento, o projeto, o cliente, a equipe e o orientador. O projeto pretende ajudar iniciantes e pessoas experientes a organizar treino, movimento e alimentação. Antes da apresentação oficial, preencher os campos da capa e substituir a indicação do LTD pela logo fornecida pela faculdade. O material recebido não identifica esses dados e não contém a logo do LTD.

Fontes: C:/Users/richa/Downloads/SeNAS - Seminários de Negócios e Arquitetura de Soluções.pdf; C:/Users/richa/Downloads/SDD.md (modelo sem preenchimento); C:/dev/TrainForge/trainforge/docs/planejamento/pitch-e-decisoes.md; https://wyden.com.br/polos-e-unidades/centro-universitario-unimetrocamp-wyden-vila-industrial-campinas-campinas-sp; https://cdn.portal.estacio.br/PPC_Enfermagem_2026_c54f0ad326.pdf (logo extraída da capa, sem alteração); https://peiunimetrocamp.com.br/extensao/

### 2. Problema

Tempo: 1 minuto e 30 segundos.

Explique a dor descrita no pitch: quem começa encontra muita informação solta, enquanto quem já pratica precisa conciliar planos, alimentação e histórico. O problema é organizar uma rotina compatível com o contexto da pessoa. Esta é a hipótese de produto documentada; confirmar com o cliente identificado na capa, pois o SDD recebido ainda não apresenta entrevistas nem dados do cliente.

Fontes: C:/dev/TrainForge/trainforge/docs/planejamento/pitch-e-decisoes.md; C:/dev/TrainForge/trainforge/docs/planejamento/README.md; C:/Users/richa/Downloads/SDD.md (modelo sem preenchimento)

### 3. Escopo

Tempo: 1 minuto e 30 segundos.

Mostre os quatro blocos da visão integrada. O modo guiado oferece orientação e o modo livre permite personalização. O projeto considera academia, casa e ar livre, além de modalidades diferentes. Android e público de Portugal constam como direção inicial. O recorte final do MVP ainda não foi fechado: esta apresentação não aprova nova priorização. Fotografia, sensores, sincronização e nutrição guiada permanecem objetivos de desenvolvimento. Conteúdo humano com origem verificável é a base pretendida; não há prescrição de treino por IA aprovada.

Fontes: C:/dev/TrainForge/trainforge/docs/planejamento/README.md; C:/dev/TrainForge/trainforge/docs/planejamento/pitch-e-decisoes.md; C:/dev/TrainForge/trainforge/docs/planejamento/arquitetura-e-contratos.md

### 4. Requisitos funcionais

Tempo: 1 minuto e 45 segundos.

Apresente requisitos como ações que a pessoa deve conseguir executar. Os IDs R01–R18 são os identificadores reais da visão central; não renomear como RF01–RF05 sem consolidar o SDD. Cada linha resume vários requisitos e não afirma implementação completa. R06 cobre contextos de saúde e retorno, com limites de orientação; R18 reúne confiança e sustentação. Imagens e dispositivos exigem confirmação, tratamento de origem e pesquisa de viabilidade.

Fontes: C:/dev/TrainForge/trainforge/docs/planejamento/README.md; C:/Users/richa/Downloads/SDD.md (modelo sem preenchimento)

### 5. Arquitetura

Tempo: 1 minuto e 30 segundos.

Percorra o diagrama do aplicativo para o servidor e o banco. A base Flutter separa features em data, domain e presentation; repositórios usam classes API e Dio. O servidor Fastify/TypeScript está no projeto bootcamp-treinos-api e usa Prisma/PostgreSQL. Google Sign-In e autenticação Bearer fazem parte do fluxo mobile. A documentação registra problemas pendentes de sessão, histórico e recorrência, portanto a arquitetura não implica produto validado em produção. A linha inferior apresenta hipóteses de evolução, não serviços já integrados. A geração de planos por IA ainda existe na base herdada, mas não é a direção aprovada do conteúdo futuro.

Fontes: C:/dev/TrainForge/trainforge/documentacao-tecnica.md; C:/dev/TrainForge/trainforge/docs/planejamento/arquitetura-e-contratos.md; C:/dev/bootcamp-treinos-api/prisma/schema.prisma

### 6. Entidades

Tempo: 1 minuto e 15 segundos.

Explique que um usuário pode ter vários planos; cada plano reúne dias; cada dia tem exercícios e sessões. A sessão representa uma execução com início e conclusão. Os nomes técnicos no diagrama correspondem ao schema existente; os campos são uma seleção didática, não a lista completa. Session, Account e MobileRefreshToken são entidades de autenticação e não substituem WorkoutSession. Alimentação, fontes e execução multimodal aparecem na evolução conceitual; não afirmar que o banco já possui essas tabelas.

Fontes: C:/dev/bootcamp-treinos-api/prisma/schema.prisma; C:/dev/TrainForge/trainforge/documentacao-tecnica.md; C:/dev/TrainForge/trainforge/docs/planejamento/arquitetura-e-contratos.md

### 7. Uso da IA

Tempo: 1 minuto e 45 segundos.

Explique o fluxo observado nesta colaboração: instruções em linguagem natural, consulta da documentação e do código, propostas e execução por ferramentas locais, validação e registro das evidências. A equipe deve confirmar os passos que efetivamente utiliza antes de apresentar. Codex conversacional não significa que a aplicação prescreve treinos por IA. O produto pretendido usa programas humanos com origem verificável. A base técnica herdada ainda contém geração de planos por IA, cuja revisão está pendente. Cite benefícios de apoio à análise/documentação e limites como respostas incorretas, inferências não demonstradas e necessidade de revisão. O roteiro SeNAS atribui as decisões à equipe, nunca ao cliente ou à IA.

Fontes: C:/Users/richa/Downloads/SeNAS - Seminários de Negócios e Arquitetura de Soluções.pdf; C:/dev/TrainForge/trainforge/docs/planejamento/README.md; C:/dev/TrainForge/trainforge/documentacao-tecnica.md; C:/dev/TrainForge/trainforge/AGENTS.md; Conversa atual com Codex
