# Validação da documentação arquitetural — 21/10/2026

Entrega revisada a pedido do autor: painel/servidor removidos; documentação Markdown/Mermaid no repositório; Swagger preparado para geração por comentários e DTOs Go.

| Conferência | Resultado efetivo |
|---|---|
| Geração/check | Derivados reproduzíveis; valida IDs/dependências, critérios, entradas R01–R18 e links locais |
| Testes documentais |13 testes: portabilidade, relocação, mtime sem deriva, mudança real, paths dinâmicos não inferidos, evidências Go separadas, Swagger ausente/sem ferramenta/sem fonte, dependência cíclica, links e diagramas |
| Mermaid |20 diagramas aceitos pelo parser Mermaid 11.12.0 com JSDOM 26.1.0; verificação de sintaxe, não matriz visual de navegadores |
| Clone/cópia limpa | Exportação limpa do índice Git passou pelo --check e pelos13testes, sem checkout externo, servidor de leitura ou dados ignorados; resultado em verificacao-links.json |
| Swagger atual | PENDENTE V1-008: serviço Go ausente; nenhuma ferramenta instalada para simular backend/contrato real |
| Fluxo Swagger futuro |Wrapper exige Swaggo v1.16.6, gera os3 derivados em temporário e compara no check; integração real com Go/recarga pertence à V1-008 |
| Painel removido |Processo encerrado pelo lançador próprio;7 arquivos específicos removidos; logs/runtime apagados |
| Código do aplicativo e dados |Sem alteração funcional em lib/android/ios, backend externo ou banco; pesquisa/dossiês preservados |
| CI GitHub |YAML parseado; eventos, permissões separadas e ações com referências fixadas/verificadas; não executado no remoto porque não houve push |

O inventário atual tem 42 Dart,14 chamadas Flutter e14 correspondências na referência Fastify (29 rotas/33TS/9 modelos), commit 523f6d9609be capturado em 21/10/2026. Não lê automaticamente outro checkout ou rede. Go tem0 arquivos de aplicação neste clone. Esses números são de análise estática; não são testes de autenticação, runtime, capacidade, segurança ou clínica.

## Reproduzir sem iniciar serviço

```powershell
python tools/gerar_documentacao.py --write --check
python -m unittest discover -s tools -p test_documentacao.py
python tools/gerar_swagger.py --check
```

As dependências temporárias usadas para análise Mermaid são dispensáveis para leitura e geração dos mapas. A ferramenta é `tools/validar_mermaid.mjs`; a CI prepara seu ambiente isolado. O repositório não precisa de Node para ser consultado.

## Limites

- Não foi implantada API Go, aplicada migration, gerado APK ou medido desempenho.
- Swagger sem fonte Go não é apresentado como válido. O gerador não implementa segurança descrita nas anotações.
- Arquitetura planejada e status/direitos exigem revisão humana, não inferência automática.
- A atualização no GitHub começa após publicação autorizada e depende das políticas/permissões do remoto. Não se contorna branch protection; falha de push do bot permanece explícita com artefato disponível.
- A conferência de links locais não consulta URLs externas nem prova disponibilidade futura dos links de fonte.

Resultados históricos dos verificadores de pesquisa permanecem nos seus dossiês e no commit anterior; não foram substituídos por testes do gerador. O painel antigo é recuperável pelo histórico Git, sem manter servidor ou código desse recurso na árvore atual.

Após a verificação, os pacotes temporários de Mermaid/JSDOM/YAML e a cópia limpa foram removidos. Nenhum serviço permanece escutando na porta8787.
