# Documentação do TrainForge

Atualizado em **24/10/2026**. Este índice define a leitura atual; datas dentro dos dossiês preservam o histórico.

| Preciso entender… | Abrir |
|---|---|
| O produto inteiro, incluindo públicos e ambientes | [Visão R01–R18](planejamento/visao-produto.md) |
| O que existe de verdade antes de comprar GIFs | [Auditoria de banco, segurança, Go, Flutter, idiomas e escala](execucao/v1/auditoria-produto-2026-10-24.md) |
| O que existe e o que precisa mudar | [Diagnóstico atual](arquitetura/diagnostico-atual.md) |
| Por que Go e como organizar os serviços | [Arquitetura proposta](arquitetura/arquitetura-alvo.md) |
| Retomar o APK disponível e testar | [Avaliação Android e checkpoint atual](execucao/v1/avaliacao-android.md) |
| Consultar alimentos reais no app | [Consulta pública e limites](execucao/v1/alimentacao-consulta.md) |
| Privacidade e ciclo da conta | [V1-013: implementação e aceite pendente](execucao/v1/privacidade-013.md) |
| Base alimentar real no banco | [V1-019: importação6369registros e limites](execucao/v1/alimentacao-importacao.md) |
| Catálogo real entregue | [V1-014: consulta e limites](execucao/v1/catalogo-consulta.md) |
| O caminho até o primeiro APK | [Plano macro da V1](execucao/v1/plano-macro.md) |
| O que entra na V1 e o que fica depois | [Escopo e critérios](execucao/v1/escopo.md) |
| O que o autor quer avaliar no APK durante o desenvolvimento | [Decisões do piloto](execucao/v1/decisoes-piloto.md) |
| O que cada agente deve executar | [Backlog](execucao/v1/backlog.md) e [handoff](execucao/v1/handoff.md) |
| Quem chama quem, passando e recebendo o quê | [Arquitetura dinâmica](arquitetura/README.md), [contratos](arquitetura/contratos-v1.md) e [fluxos](arquitetura/fluxos.md) |
| Como serão camadas e Swagger Go | [Camadas](arquitetura/camadas-go.md) e [Swagger por comentários](arquitetura/swagger-go.md) |
| Banco, unidades, versões e histórico | [Domínio e banco](arquitetura/dominio-e-banco.md) |
| Segurança, observabilidade e escala | [Plano de qualidade](arquitetura/seguranca-operacao.md) |
| Implantação e entrega à esposa | [Roteiro de distribuição](execucao/v1/implantacao-e-apk.md) |
| Conteúdo efetivamente encontrado | [Índice de conteúdo](conteudo/README.md) |
| O que foi validado nesta entrega | [Validação e registro](execucao/v1/validacao-planejamento.md) |

**Prioridade vigente24/10:** auditoria antes de contratar mídia; GIFs não são o único bloqueio. Banco local e alimentação manual reais; treino completo, cuidador, foto, idiomas e qualidade ainda têm lacunas. [Diagnóstico e prioridades](execucao/v1/auditoria-produto-2026-10-24.md).

**Checkpoint do aplicativo24/10:** pontosfrontend07–12 nos fluxos disponíveis, APKdebug0.3.0+13,101testesFlutter/analyze0issues. [Implementação e pendências](execucao/v1/frontend-etapa-07-12.md). Configuração/treino/atividade e capacidades sem contrato, referênciasFigma faltantes e iOS nativo continuam abertos.

**Checkpoint anterior24/10:** Grafite e lima/rolagem por plataforma aplicados noAPK0.2.1+12. [Ajuste e limites](execucao/v1/frontend-dark-scroll.md).90testesFlutter/analyze0issues; iOS27 nativo nãoexecutado.

**Estado:** etapas01/02 e V1-011/012/013/014/019 concluídas no recorte documentado. V1-020 funcional e consumo humano real confirmados. Prioridade atual: frontend fiel aoFigma, com novo checkpoint dospontos07–12 e dependências explícitas. APKdebug0.3.0+13; aparência/inicialização/Hoje/loaders/transições e identidade nativa implementados; direção visual de aberturaTF/dark confirmada peloautor e seis pontos concluídos no checkpointAndroid. [Etapa e limites](execucao/v1/frontend-etapa-01-06.md), [recibo atual](execucao/v1/android-frontend-checkpoint.json), [handoff](execucao/v1/handoff.md).

73metadados/6369referências alimentares reais, sem prática aprovada ou novas instruções/mídias inventadas. API/banco/emulador locais; nenhuma hospedagem necessária para avaliar. Distribuiçãorelease/iOS e demais histórias continuam nos próprios gates.

## Como a pasta foi organizada

- `arquitetura/`: entrada navegável sem servidor, fatos atuais, propostas, Swagger por comentários, referências portáteis e mapas gerados.
- `execucao/v1/`: recorte, sequência, backlog, entrega e retomada para agentes.
- `.github/workflows/documentacao.yml`: geração/verificação dos documentos e atualização dos derivados na branch principal, após publicação da configuração e respeitando regras do remoto.
- `conteudo/`: autoria, fontes, direitos e evidências da pesquisa, com caminhos preservados.
- `planejamento/`: visão R01–R18 e referências de produto; a execução atual está na V1.
- `design/`: protótipos e inventários datados; simulações do Figma não são dados do app.
- `referencias/`: Graphify do backend e do frontend antigo, com cobertura própria.
- `arquivo/2026-10-21/`: versões antigas dos documentos de entrada. Consultar somente para histórico.

A organização removeu dos pontos de entrada as filas e instruções ultrapassadas. Não apagou provas de autoria, recibos, verificadores nem arquivos necessários para reproduzir a pesquisa. PDFs e renders de terceiros continuam locais e ignorados no Git; o repositório guarda registros e hashes, não uma licença de redistribuição desses materiais.

**23/10:** V1-013 tem implementação independente validada: política pública, exportação própria, exclusão confirmada, manutenção e filtro de restore. Go0.4.0/18operações, Flutter48testes/APK0.1.3+4. GoogleAndroiddebug/aceite privado reais passaram; OAuthrelease cadastrado/conferido; HTTPS/testeAPKrelease pendentes; nenhuma outraV1 iniciada. Incrementos publicados noGitHub em3170c50/4b922ab; ambasCIs verdes, nenhum deploy.

**Prioridade atual:** autor não quer hospedagem agora. Teste local pronto;011/012/013 concluídas com [critérios/evidência](execucao/v1/auth-local-fechamento.md). DistribuiçãoHTTPS/release/iOS permanece futura, sem bloquear consultas noemulador.
