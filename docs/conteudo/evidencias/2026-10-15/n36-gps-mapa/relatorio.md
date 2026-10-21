# N36 — GPS e mapa

**Pesquisa técnica/documental fechada**, com dez requisitos e oito casos discutidos, sem aplicativo ou teste de campo. [Fontes](fontes-e-limites.json), [especificação](requisitos-percurso-proprio.json) e [auditoria](auditoria-fechamento.json). Leitura web primária, sem novosGETs/corpos/hashes locais.

A especificação Geolocation consultada é o CandidateRecommendationSnapshotW3Cde26/03/2026. Não tratá-la como recomendação final. A APIobtém posição do dispositivo a partir deGPS/rede/outrasorigens e não garante posição verdadeira. Precisão/instante de aquisição e cache precisam acompanhar o ponto. O raioaccuracydaAPInativaAndroidusa68%, enquanto a especificaçãowebrefere95%; números iguais não representam automaticamente a mesma incerteza.

A documentação Android distingue precisão aproximada/precisa e acesso em primeiro/segundo plano. A escolha aproximada do usuário prevalece sobre o pedidoFINE. Foregroundservice e sua notificação não são o mesmo que pedirBACKGROUNDindiscriminadamente. Funcionamento com tela apagada/limitações de bateria ainda precisa de teste por versão.

Mapa, coordenadas, percurso próprio, rota sugerida e partilha são funções distintas. DadosOpenStreetMapusamODbLeatribuição; serviço público de tiles tem política própria, capacidade limitada e nenhumSLA. Cache/identificação/atribuição são exigidos; bulk/prefetch não permitido. Não foram solicitados tiles, rotas ou localização de alguém. Não foi contratado serviço de produção.

Casa e academia não exigemGPSpara treinar. Na praça/caminhada, percurso é opcional e não mede carga, gasto, técnica ou segurança do trajeto. Telefone do cuidador não localiza o assistido por inferência. Permissão do sistema não autoriza retenção/partilha geral; origem/fim de percurso podem revelar casa.

A proposta editorial separa início, pausa, retomada e fim; tempo decorrido, registrado e lacunas. Não há autopausa, interpolação, filtro/limiar ou compensação de treino validados. Emulador simulado não mede precisãoGNSSreal. Antes de oferecer: implementação autorizada, escolha de provedor/direitos/custos, privacidade/compreensão e testes de campo/permissões/bateria. N15 pausada/aberta; N21 não iniciada; N37 somente após este fechamento.
