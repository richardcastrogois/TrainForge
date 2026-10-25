# Documentação do TrainForge

Atualizado em **25/10/2026**. Este índice define a leitura atual; datas dentro dos dossiês preservam o histórico.

| Preciso entender… | Abrir |
|---|---|
| O que fazer, área por área, e quando encerrar | [Trilha de implementação e decisões](execucao/v1/trilha-implementacao.md) |
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
| Como outros produtos guardam fotos de refeições | [Comparação de quatro produtos e direção aprovada para o TrainForge](execucao/v1/pesquisa-fotos-historico.md) |
| O que cada agente deve executar | [Backlog](execucao/v1/backlog.md) e [handoff](execucao/v1/handoff.md) |
| Quem chama quem, passando e recebendo o quê | [Arquitetura dinâmica](arquitetura/README.md), [contratos](arquitetura/contratos-v1.md) e [fluxos](arquitetura/fluxos.md) |
| Como serão camadas e Swagger Go | [Camadas](arquitetura/camadas-go.md) e [Swagger por comentários](arquitetura/swagger-go.md) |
| Banco, unidades, versões e histórico | [Domínio e banco](arquitetura/dominio-e-banco.md) |
| Segurança, observabilidade e escala | [Plano de qualidade](arquitetura/seguranca-operacao.md) |
| Implantação e entrega à esposa | [Roteiro de distribuição](execucao/v1/implantacao-e-apk.md) |
| Conteúdo efetivamente encontrado | [Índice de conteúdo](conteudo/README.md) |
| O que foi validado nesta entrega | [Validação e registro](execucao/v1/validacao-planejamento.md) |

**Prioridade vigente 25/10:** seguir a [trilha por área](execucao/v1/trilha-implementacao.md). Q1 e agrupamento por refeição/alimento confirmados; histórico visual, análise nutricional e dicas revisadas juntos na primeira versão. Q2 confirmou recuperação das fotos pela conta, com cache no celular. Próximo bloco Q3 sobre configuração e treinos. Implementar com critérios verificáveis. GIFs não são o único bloqueio. Direção visual aprovada preservada; sem hospedagem/contratação agora. A auditoria mantém o baseline; planejamento não conta como conclusão.

**Aplicativo disponível:** APK Android debug **0.3.0+13**, API Go **0.5.1 / 25 operações**, PostgreSQL local. Autenticação/privacidade e alimentação manual possuem evidências reais. Há 73 metadados de movimento e 6.369 referências alimentares; nenhuma prática foi liberada por aplicar o visual.

**Frontend:** pontos 01–06 têm checkpoint Android aprovado; 07–12 refinam os fluxos disponíveis, sem encerramento integral. Configuração, treino, contexto de pausa, foto, idiomas e validação nativa iOS permanecem abertos. Cuidador pratica para si; delegação de outra pessoa não é requisito desta versão. [Fonte visual e checkpoints](execucao/v1/frontend-fidelidade-figma.md) · [Artefato](execucao/v1/android-frontend-checkpoint.json) · [Handoff](execucao/v1/handoff.md).

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
