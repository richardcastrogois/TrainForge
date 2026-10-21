# Painel do projeto: onde acompanhar

Abra [http://127.0.0.1:8787](http://127.0.0.1:8787) depois de iniciar o serviço abaixo. A aba pode ficar aberta; enquanto visível, consulta alterações a cada3 segundos e redesenha se o inventário mudou. Não precisa pedir um novo diagrama a cada commit.

```powershell
cd C:/dev/TrainForge/trainforge
./tools/abrir-painel.ps1
# Encerrar somente o processo registrado pelo lançador:
./tools/abrir-painel.ps1 -Parar
```

O lançador reutiliza Python disponível ou o runtime Python do Codex deste computador, sem instalar pacotes. Inicia oculto um serviço **somente em 127.0.0.1**, com logs/PID locais em `.project-runtime/`, ignorados pelo Git. Não inicia API, PostgreSQL ou emulador e não precisa de login. Se a porta estiver ocupada por outro serviço, usar `-Porta 8788`, sem encerrá-lo.

Alternativa em primeiro plano, parando com Ctrl+C:

```powershell
python tools/painel_projeto.py --serve
# Outro local do backend:
python tools/painel_projeto.py --serve --api-root C:/outro/backend --port 8788
```

Se `python` não estiver no PATH, usar o executável já existente deste host:
`C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.

## Como usar

1. **Atual · detectado:** arquitetura agrupada, referências entre telas, literais HTTP do Flutter e rotas Fastify compatíveis; banco lido do schema. Clique/Enter num bloco, ligação ou linha para ver caminhos/linhas e dados/tipos detectados.
2. **Planejado · Go:** destino proposto e chamadas com entrada/saída, jornadas e modelo lógico. Esses blocos não são serviços já implementados.
3. **Backlog:** expandir história mostra aceite, dependências, tarefas, subtarefas, testes e entregas. Buscar por ID, requisito, rota ou palavra. O painel é leitura; atualizar a fonte JSON no repositório.
4. **Achados:** registros de inspeção estática com prioridade e história correspondente. Não são resultados de scanner/CVEs nem números copiados de imagem.
5. No desenho, arrastar fundo/blocos; botões ampliam/reduzem/enquadram. Controles e nós têm navegação por teclado. Em tela pequena, os detalhes aparecem abaixo do mapa.

## O que atualiza sozinho e o que exige revisão

Código Dart, TS do backend, schema Prisma, `backlog.json`, `plano.json` e `achados.json` entram na observação. O serviço confere caminho/mtime/tamanho, gera uma revisão e recalcula o inventário quando há mudança. Não altera arquivos fonte ou status; o último snapshot versionado é gerado explicitamente:

```powershell
python tools/painel_projeto.py --snapshot --check
python -m unittest discover -s tools -p "test_painel_projeto.py"
```

`inventario-atual.json` e `backlog.md` são derivados. `plano.json`, `achados.json` e `backlog.json` são registros revisados. Dependências e arestas são validadas; `done` exige evidência. O servidor não interpreta intenções, direitos, diagnóstico ou testes; outro agente atualiza os registros na mesma história. A história003 exige ampliar a detecção para Go/OpenAPI quando esses arquivos existirem; até lá a cobertura atual é Flutter/Fastify/Prisma.

Os padrões estáticos podem deixar chamadas dinâmicas e condições fora do mapa. Correspondência método/path não prova auth, resposta, compatibilidade completa de DTO nem execução. Schemas inline podem aparecer só como `z.object`; consultar arquivo/linha para detalhe. Rotas de plugins (`/api/auth/*`, Swagger e health raiz) ficam fora do extrator de `src/routes`; não apresentar a contagem como toda a superfície HTTP.

Backend externo ausente deixa zero correspondências e aviso de cobertura. Não precisamos de serviço remoto para este painel; código de Go futuro não pode aparecer como “atual” por estar desenhado na proposta.

## Limites locais

Servidor com allowlist de arquivos/API, proteção de Host/Origin e CSP; não expõe navegação arbitrária no filesystem, .env, corpos de pesquisa ou banco. Metadados incluem caminhos de código, próprios para uso local. Não publicar o painel na internet com dados/caminhos do workspace. Abrir só `index.html` pelo Explorer não ativa servidor/atualização; usar o comando e URL acima.

Graphify continua disponível como mapa estrutural mais detalhado, atualizado separadamente: [guia](../graphify.md). Ele não substitui a visão de contratos, planejamento e estados do painel.
