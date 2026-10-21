# Cuidadores: catalogo documental por item

**Estado vigente - 21/10/2026:** N15 concluiu a pesquisa no recorte modular autorizado: onze componentes para cuidadores, separados dos cinco movimentos domesticos para idosos ja conferidos. N01-N46: 40 pesquisas concluidas nos recortes e seis reusos documentados; nenhuma N ativa ou pausada. Nao sao cinco programas originais de cuidadores completos nem conteudo/pratica/publicacao aprovados. Benson/START/Pilates e variantes nao selecionadas preservam suas lacunas. Fonte, autoria, dose, publico, apoio e direitos por componente; sem ciclo novo ou eficacia herdada. Indice: 840 tentativas GET, 694 HTTP200, 780 hashes conferidos, 331 familias. Sem app/Figma/banco, novos contatos, commit ou push. [Entrega, selecao e limites](evidencias/2026-10-21/n15c-composicao/relatorio.md). Registros datados anteriores abaixo sao historicos e nao substituem esta selecao.

**Pedido atual13/10:** fechar todas as G de fato, focando instrucao executavel e condicoes de uso. [Auditoria atual](evidencias/2026-10-13/n15c-lacunas-dirigidas/auditoria-conteudo.json), [relatorio](evidencias/2026-10-13/n15c-lacunas-dirigidas/relatorio.md) e [fila](fila-cuidadores.json): cinco fichas factuais fechadas, somenteCG01 atende ambos os gates de pesquisa no recorte restrito/profissional,zero publicados. CG02-05 ainda oito perguntas. ContextoCG03 resolvido; guiasNHS16/10p e cinco configuracoes parciaisCG04 nao liberam variantes/doses. N15-Cglobal parcial/N21retida. Implementacao ou contratacao nao sao gates de pesquisa; tampouco substituem comandos/fontes/direitos ausentes.

**Pacotes factuais preservados:** [CG01](evidencias/2026-10-12/cg01-estatico/pacote-factual.json), [CG02](evidencias/2026-10-12/cg02-benson/pacote-factual.json), [CG03](evidencias/2026-10-12/cg03-start/pacote-factual.json), [CG04](evidencias/2026-10-12/cg04-revieew/pacote-factual.json), [CG05](evidencias/2026-10-12/cg05-pilates/pacote-factual.json). `researchItemClosed` fecha apenas a ficha; a consulta devolve agora `executionContentAudit.item.executableResearchClosedInDeclaredPath`. Nenhuma dessas flags e aprovacao de publicacao.

Consolidacao de 12/10/2026, autorizada pelo autor apos esclarecer que fontes podem complementar a documentacao e que opcoes independentes nao precisam formar um treino unico.

**Entregue:** cinco fichas independentes,90campos comlocalizadores estruturados, quatorze leituras e28recibos primarios selecionados verificados. Sao19componentes indexados e tresfases dePilates, nao19exercicios aprovados. **Cinco fichas fechadas nosrecortes factuais; zero itens liberados para publicacao, nenhum novo treino ouAPK alterado.** N15-C permanece aberta; contagem de fichas nao substitui requisitos globais.

## O que teremos

| Item | Conteudo que ja temos | Publico da evidencia | O que impede publicar agora |
| --- | --- | --- | --- |
| CG-01 / PR42 | Pesquisa fechada: sessao aguda original e precaucoes auxiliares separadas; caminho profissional | Profissionais de reabilitacao cuidadores de criancas, 18-40 anos, criterios do estudo | Revisao humana de localizacao, controles da modalidade e atribuicoes antes de publicar; sem inicio autonomo |
| CG-02 / PR61 | Ficha do metodo fechada: seis etapas,15min2dia1mes, encerramento, ensino/reforco e resultado de sobrecarga | Cuidador familiar de pessoa em hemodialise,18-60anos, criterios doestudo | Antes deuso/publicacao: material didatico fiel/legal revisado e ensino/apoio reais; CDoriginal nao recebido e substituto nao aprovado |
| CG-03 / PR115 | Pesquisa factual fechada: oito roteiros originais em ordem, dose/preparo/encerramento/precaucoes e contexto START | Cuidador familiar de pessoa com demencia, criterios do ensaio | Resultado do programa inteiro, nao cada tecnica; materiais legais/fieis revisados, manuais/audio, lider treinado e supervisao reais antes deuso |
| CG-04 / PR68 | Ficha do programa profissional fechada: nove movimentos/27variantes, dose/progressao/rotacao/dor/resultados e fontes | Trabalhador formal do cuidado a idosos, criterios do ensaio | Guia autonomo completo nao recebido; orientacao clara/fiel incluindo aquecimento/retorno revisada, fisioterapeuta ao vivo econdicoes reais antes deuso; cointervencao preservada |
| CG-05 / PR136 | Ficha profissional fechada: dose1serie10reps,preparo,materiais,tresetapas/listas,warm/retorno e resultados/fontes separados | Cuidador principal de crianca com deficiencia,18-55anos/criterios;CERweb diz somente uma crianca | Guia autonomo/calendario deexecucao nao aprovados;divergencia narrativa/tabela preservada;orientacao integral,profissional eativos revisados antes deuso |

Os cinco itens nao atendem automaticamente a mesma pessoa. Casa, centro, academia ou outro espaco sao considerados pela compatibilidade real de materiais, movimentos, preparo e acompanhamento, nao pelo nome do local. A possibilidade material de executar em casa nao equivale a um novo ensaio de eficacia domiciliar.

## Componentes indexados

- CG-01: um autoalongamento estatico. PNF nao selecionado e seus tempos nao transferidos.
- CG-02: uma rotina Benson de seis etapas. Nao seis exercicios musculares novos.
- CG-03: respiracao-sinal, respiracao focada, ancoragem, imaginacao de campo/riacho, meditacao, imaginacao oceanica, alongamento de bracos/ombros e imaginacao de montanha. As cenas imaginadas nao sao caminhada fisica prescrita.
- CG-04: squat, glute bridge, reverse lunge, arm raise, pull-apart, biceps curl, dead bug, bird dog e lateral plank. As tres variantes de cada movimento permanecem vinculadas ao protocolo; nao guias narrados reconstruidos das fotos.
- CG-05: tres fases do programa, explicitamente classificadas como fases e nao exercicios executaveis. Nomes/listas completos estao na leitura da tese; nao completar os passos por IA.

## Como recuperar para o APK

Fonte estruturada: [catalogo-cuidadores.json](catalogo-cuidadores.json). Cada item tem 18 campos em `fields`, com referencias `alias#/json/pointer` para uma leitura existente. Esta leitura indica DOI/versao/localizador; `receipts` liga o campo ao recibo e corpo com URL, dataUTC, bytes e SHA256. Valores desconhecidos continuam nulos. O catalogo evita duplicar uma prescricao alteravel em varios arquivos.

Consulta offline no checkout, com o Python configurado no host:

```powershell
python docs/conteudo/consultar-cuidadores.py
python docs/conteudo/consultar-cuidadores.py --item CG-02
python docs/conteudo/consultar-cuidadores.py --item CG-03
python docs/conteudo/consultar-cuidadores.py --item CG-04
python docs/conteudo/consultar-cuidadores.py --item CG-05
python docs/conteudo/consultar-cuidadores.py --write-audit
```

A consulta retorna documentacao para pesquisa, nao prescricao liberada. [Verificacoes](evidencias/2026-10-12/n15c-catalogo-modular/verificacoes.json) registra integridade dos corpos e contagens reais. Ainda nao existe importador, tela, suporte profissional contratado ou aprovacao de publicacao no app.

## Regras da consolidacao

1. Artigo, protocolo, manual e qualificacao podem complementar a mesma ficha quando familia/versao/variante correspondem. Mesma familia ou mesmo nome de movimento, sozinhos, nao provam equivalencia.
2. Cada componente conserva a origem e o contexto do programa. Resultado do pacote nao vira comprovacao de cada gesto isolado; nao e exigido umRCT independente de cada movimento.
3. Nao montar nova sequencia juntando dose de um estudo, postura de outro e encerramento de um terceiro. Mudancas de dose para cansaco/tempo nao sao geradas pelo app.
4. Avaliar direitos dos ativos escolhidos. Fatos/metodos sao distintos de expressao protegida; licenca do artigo nao cobre automaticamente CD/video/manual externo. Nao exigir direitos de um ativo nao usado, mas tambem nao retirar silenciosamente material que integra a entrega estudada.
5. Cada item pode futuramente ser publicado sozinho quando cumprir seus requisitos aplicaveis; nao esperar que os cinco estejam completos. Consolidacao documental e publicacao clinica/editorial sao estados diferentes.
6. NoCG01, o autor aceitou principios profissionais gerais compativeis, separados da prescricao e semalegar que a combinacao foi testada. Isso nao autoriza importar dose/variante de outro guia. A compatibilidade documental nao e validacao clinica independente.

## Prioridade concreta

CG01-05 fichas fechadas nosrecortes, semaprovacao depublicacao. CG04/05 conservam caminhos profissionais, nao aulas autonomas recuperadas. NoCG05 a escolha bibliografica de marcos3/6 concordantes comCERweb nao corrigeTable1tese nem aprova transicoes deexecucao. Comandos completos/seguranca/versao/calendario/apoio/direitos precisam deverificacao antes deuso; nao completar porIA. Nenhum proximoitem ou outraN iniciado. Aordem nao e recomendacao medica ou prazo delancamento.

PR135, PR137, PR138 e PR139 permanecem referencias ja pesquisadas, sem serem promovidos a exercicios pelo catalogo. Nao fechar N15-C/N21 por contagem de fontes, testes ou componentes.
