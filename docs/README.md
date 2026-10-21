# Documentação do TrainForge

Atualizado em **21/10/2026**. Este índice define a leitura atual; datas dentro dos dossiês preservam o histórico.

| Preciso entender… | Abrir |
|---|---|
| O produto inteiro, incluindo públicos e ambientes | [Visão R01–R18](planejamento/visao-produto.md) |
| O que existe e o que precisa mudar | [Diagnóstico atual](arquitetura/diagnostico-atual.md) |
| Por que Go e como organizar os serviços | [Arquitetura proposta](arquitetura/arquitetura-alvo.md) |
| O caminho até o primeiro APK | [Plano macro da V1](execucao/v1/plano-macro.md) |
| O que entra na V1 e o que fica depois | [Escopo e critérios](execucao/v1/escopo.md) |
| O que cada agente deve executar | [Backlog](execucao/v1/backlog.md) e [handoff](execucao/v1/handoff.md) |
| Quem chama quem, passando e recebendo o quê | [Arquitetura dinâmica](arquitetura/README.md), [contratos](arquitetura/contratos-v1.md) e [fluxos](arquitetura/fluxos.md) |
| Como serão camadas e Swagger Go | [Camadas](arquitetura/camadas-go.md) e [Swagger por comentários](arquitetura/swagger-go.md) |
| Banco, unidades, versões e histórico | [Domínio e banco](arquitetura/dominio-e-banco.md) |
| Segurança, observabilidade e escala | [Plano de qualidade](arquitetura/seguranca-operacao.md) |
| Implantação e entrega à esposa | [Roteiro de distribuição](execucao/v1/implantacao-e-apk.md) |
| Conteúdo efetivamente encontrado | [Índice de conteúdo](conteudo/README.md) |
| O que foi validado nesta entrega | [Validação e registro](execucao/v1/validacao-planejamento.md) |

**Estado:** pesquisa N01–N46 encerrada nos recortes documentados, incluindo N15 modular. Aplicativo Flutter e API Fastify já existem; Go, novo banco lógico, catálogo integrado, deploy e APK V1 ainda são trabalho futuro. Pesquisa concluída não é liberação editorial, clínica ou de redistribuição.

**Próxima história:** `V1-001`, selecionar o lote candidato e a jornada do teste. `backlog.json` é a fonte única de tarefas; o Markdown é gerado. Nada foi marcado como implementado só por constar no planejamento.

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
