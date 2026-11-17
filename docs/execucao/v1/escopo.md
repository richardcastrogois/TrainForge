# Produto acordado e prioridades da V1

Consolidado em **17/11/2026**. O TrainForge é um produto móvel Android/iOS para treino, alimentação e acompanhamento, com prioridade a idosos e cuidadores como praticantes, em casa, praça/parque, academia e outros contextos pesquisados. [Visão R01–R18](../../planejamento/visao-produto.md) conserva os requisitos; [backlog](backlog.json) contém histórias e critérios. A faculdade é uma apresentação do trabalho, não o limite comercial do produto.

<a id="decisoes"></a>
## Decisões do autor e consequências

| Bloco | Decisão registrada | Consequência |
|---|---|---|
| Q1 —24/10 | Preservar todos os públicos/ambientes e dois caminhos de treino: programa compatível e composição controlada. Alimento por foto e composição antecipados paraV1. | Não reduzir o produto a musculação nem prometer prescrição por IA; disponibilidade depende de regras/conteúdo revisados. |
| Q2 —25/10 | Refeições e alimentos são visões dos mesmos registros; histórico visual/análise/dicas avaliados juntos. | Evitar bancos/totais divergentes e não substituir quantidade informada por uma foto. |
| Q3 —25/10 | Configuração completa antes de selecionar; programa pronto ou composição, trocas compatíveis, dias/horários e retomar ou encerrar parcial. Cuidador pratica para si em suas pausas. | Falta de recurso/instrução não vira adaptação inventada. Saída/timer/processo encerrado não concluem treino. |
| Q4 —25/10 | Alimentação e andamento offline com fila durável privada; fotos recuperáveis pela conta/cache; excluir refeição exclui foto. | Isolamento de titular, confirmação/reenvio/conflito e exclusão sem recriar dados são critérios próprios. Retentativa em memória não encerra026. |
| Q5 —25/10 | Etapas curtas de configuração com revisão final; nome traduzido quando revisado, original/fonte nos detalhes. | Preservar respostas ao voltar; quatro idiomas naUI não equivalem a cobertura editorial integral. |
| Q6 —25/10 | Dados particulares excluíveis pelo titular ou pelo master do autor, com permissão real no servidor; avaliar todos os cenários. | Master revogável/auditável é uma história pendente, sem bypass por e-mail/GitHub. Não presumir participantes ou autorização para apagar dados reais. |
| 16/11 | Incorporar comportamentos úteis com implementação própria, mantendoFlutter/Go/PostgreSQL; sem web, alimentação como foco desta rodada ou cópiaAGPL/mídia com novas obrigações. | Avançar execução sem reescrever a base, criar treinos fictícios ou comprar mídia por inferência. |

As perguntas e respostas originais estão em `docs/execucao/v1/decisoes-piloto.md` no [acervo histórico](../../historico/README.md). A organização acima reúne a decisão final, sem tratar cada proposta anterior como vigente.

## Regras que atravessam o produto

- Programa, movimento, instrução, dose e mídia são ativos diferentes, ligados a versão, fonte, autoria e direitos por operação. Pesquisa, tradução de apresentação e cache não liberam publicação ou prática.
- Configuração respeita contexto, ambiente e recursos efetivamente informados; desconhecido permanece desconhecido. Adequação clínica e exigência profissional não são inferidas pelo nome de uma condição.
- Conta nova começa sem histórico, medidas, calorias ou resultados de demonstração. Planejado e realizado ficam separados; ausência não vira zero, vídeo falso ou sucesso simulado.
- Foto sugere candidatos editáveis; a pessoa informa quantidade e confirma. Original, preparo, unidade, composição e histórico não mudam ao traduzir um nome.
- Servidor verifica identidade/titularidade/revisão. Logs, backup, restauração, exclusão, fila e anexos privados têm critérios de proteção próprios.
- Emulador primeiro e Android físico depois; iOS, lojas, sensores/GPS, OCR/barcode e delegação conservam seus recortes no backlog. Todos os cenários permanecem visíveis com status honesto.

<a id="prioridades"></a>
## O que vem antes do quê

O JSON do backlog é a fonte única de status/dependências: **19 done,6 doing,24 todo** no checkpoint funcional. A limpeza documental não encerra histórias. A próxima funcional é **V1-015**, condicionada a um primeiro programa próprio com instruções, dose e revisão verificáveis, seguido de seleção/adesão e agenda. Execução017/023 já tem motor/API/UI, sem conteúdo liberado para completar o ciclo.

Trabalho independente de conteúdo pode continuar pelos gates de qualidade, privacidade e operação. Fotos042, composição044, refeições045, histórico/análise046, offline026, master049, acessibilidade027 e entrega035 têm critérios próprios; não são substituídos por uma tela, uma tabela ou documentação.

## Pronto para piloto e pronto para venda

Um APK incremental pode ser avaliado antes de todaV1, com roteiro que mostre disponível/incompleto/bloqueado/ainda não implementado. A [matriz de cenários](matriz-cenarios.md) não permite fingir capacidades ausentes. Para distribuir aos colegas, precisamos de API acessível por HTTPS, configuração correta de autenticação, artefato assinado e validação do fluxo habilitado.

Para V1 completa, conferir todos os critérios do backlog: ao menos uma fatia de prática humana revisada; autorização/reenvio e exclusão; dados e fontes rastreáveis; testes/restore e segurança; offline/fotos quando exigidos; idiomas/acessibilidade; artefato e aceite humano. Um teste técnico descartável não é um registro humano nem uma aprovação clínica.

## Compras e novas pesquisas

Priorizar opções gratuitas com direitos claros. Avaliações de preço, teto antigoR$ 400 e interesse posteriorMoveKitR$ 779 são históricos; nenhum deles autorizou compra, assinatura, cadastro, contato ou hospedagem. Os preços datados não são ofertas atuais. Reabrir pesquisa quando houver uma lacuna concreta e nova pista, preservando o [catálogo de fontes](../../conteudo/catalogo-fontes.md).
