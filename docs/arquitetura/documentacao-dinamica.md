# Documentação dinâmica, sem painel local

Decisão de **21/10/2026**, após revisão do autor: a referência de arquitetura fica no próprio repositório. O painel local, seu servidor e os comandos de iniciar/parar foram removidos. Não é necessário executar ferramenta para **ler** a documentação.

Abra [README da arquitetura](README.md) no GitHub ou no editor. Os arquivos Markdown e os diagramas Mermaid fazem parte do clone. Quem não usa renderizador Mermaid ainda encontra texto, tabelas e o código dos diagramas. O GitHub renderiza Mermaid nos arquivos Markdown: [referência oficial](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams).

## O que é automático

O gerador lê o código Dart presente no clone, referências entre widgets, imports, literais HTTP, comentários e registros Go quando existirem, especificações geradas, backlog e proposta arquitetural. Produz mapas, tabelas de entrada/saída, esquema de referência e progresso. A geração é determinística: mesmos arquivos resultam no mesmo texto, sem caminho da máquina ou timestamp que gere commits infinitos.

Na CI, `.github/workflows/documentacao.yml`:

1. Em PR, regenera, testa e verifica se os derivados enviados correspondem às entradas. Uma divergência falha com indicação dos arquivos. Não executa código de PR com credencial de escrita.
2. Em push na branch principal ou execução manual nela, gera/testa e disponibiliza os documentos como artefato. Um job separado, com escrita somente nesse evento confiável, versiona exclusivamente os arquivos derivados.
3. O job de escrita não executa o gerador ou scripts recebidos de PR, não altera código do app, não faz push forçado e não contorna branch protection. Se as regras do remoto bloquearem o commit automático, o job falha explicitamente e o artefato continua disponível; é necessário adequar o fluxo do repositório antes de prometer atualização no README remoto.
4. A documentação no GitHub só muda após esses arquivos/workflow serem publicados no remoto e a execução terminar. Arquivos locais não salvos, mudanças ainda não enviadas ou um `git pull` não são observação automática do seu editor.

Publicação autorizada e execução real conferidas em23/10: os dois jobs passaram em [39952064880](https://github.com/richardcastrogois/TrainForge/actions/runs/39952064880), com derivados já atuais e sem commit artificial. [Recibo](../execucao/v1/publicacao-ci-verification.json). Criar o YAML isoladamente não seria essa evidência. A CI também executa a suíte padrão Python das ferramentas, além de Go e Mermaid. A geração e os testes podem ser reproduzidos localmente com Python3.11+ e biblioteca padrão. Nenhum servidor, Node ou Go é necessário para **ler** ou gerar os mapas atuais. Para conferir a sintaxe dos diagramas, a CI usa Mermaid11.12.0 e JSDOM26.1.0 em diretório temporário, com scripts de instalação desativados; essas bibliotecas não são dependências do Flutter/Go nem do leitor.

## Fontes de verdade

| Informação | Fonte | Tratamento |
|---|---|---|
| Flutter atual | `lib/**/*.dart` | Lido no próprio clone; links relativos para os arquivos |
| Backend Fastify separado | [snapshot de metadados](referencias/backend-fastify.json) | Commit, hashes e links de fonte explícitos; não é código atual recebido no clone nem execução online |
| Go atual | `services/api/**/*.go`, quando existir | Anotações e registros literais identificados separadamente; ausência fica visível |
| Contrato Go | `contracts/generated/swagger-v1.json`, quando existir | Gerado por comentários/tipos, não editado à mão |
| Arquitetura futura e jornadas | `plano.json` e documentos revisados | Intenção declarada, nunca convertida em fato pela geração |
| Tarefas | `docs/execucao/v1/backlog.json` | Status humano revisado; `done` requer evidência |
| Achados/direitos/apoios | Dossiês e registros revisados | Gerador não fecha risco nem libera conteúdo |

O snapshot externo evita dependência de `C:/dev/...` no clone e na CI. Não fingimos que ele acompanha alterações de outro repositório sozinho. Ao mudar o Fastify, o mantenedor precisa capturar uma referência nova e revisar o diff, ou trazer o serviço para este repositório conforme a migração planejada.

## Comandos para manutenção, não para consulta

```powershell
# Na raiz trainforge; Python existente. Não inicia nada em localhost.
python tools/gerar_documentacao.py --write
python tools/gerar_documentacao.py --check
python -m unittest discover -s tools -p test_documentacao.py

# Somente ao atualizar a referência do backend separado:
python tools/gerar_documentacao.py --capture-backend C:/caminho/do/backend --write
```

`--capture-backend` exige repositório limpo e guarda apenas metadados/código estrutural, revisão e hashes normalizados; não lê `.env`, credenciais, banco, tráfego ou corpos de pesquisa. Sem captura explícita, a geração usa somente o que está no clone.

## Limites de interpretação

Um import é dependência estrutural, não chamada executada. Referência a widget não prova condição/clique. Método/path compatíveis não provam DTO, login ou resposta. Anotação Swagger não garante que o handler foi registrado. Direitos, público, modalidade e apoio não podem ser deduzidos da existência de um arquivo. Os diagramas atuais e propostos são identificados separadamente.

Não há processo “mágico” acompanhando arquivos sem executar em algum lugar: a atualização automática ocorre na CI depois do push. Durante implementação local, o agente regenera os derivados na mesma entrega; o leitor só abre os arquivos prontos.
