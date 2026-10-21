# Pesquisa Complementar: N15-C, N18-I, N19-I e N20-I

Rodada de 05/10/2026, posterior a [fechamento-dirigido](../fechamento-dirigido/relatorio.md). Pesquisa e registro documental, sem app/API/Figma/banco, contato com autores, commit ou push. **Nenhum dos quatro complementos foi fechado; N21 nao iniciada.**

## O Que Foi Recebido

13 novas chamadas, todas HTTP200, corpos reais recebidos e hashes conferidos: quatro PDFs, seis DOCX e tres paginas HTML. Nenhum desafio executado, nenhuma falha anterior repetida. PDFs sem teto de bytes conforme autorizacao; DOCX abaixo do teto ordinario2MiB, sem ampliar a excecao REACT para outros documentos.

| Fonte Primaria | Retorno E Leitura | Resultado Para Fechamento |
|---|---|---|
| [My Ten / Penner, Lambert e Cohen](https://link.springer.com/article/10.1186/s12904-026-02309-4), PR58 | Artigo in press, PDF22p e seis DOCX recebidos; metodos/Table1/direitos e texto OOXML integral | Atividade propria do cuidador em casa. Formularios, nao rotina prescrita; DOCX4 referencia manual e worksheet nao incluidos.12semanas planejadas,6testadas; artigo CC BY4.0, sem preencher ausentes. |
| [IMPACCT / NARI](https://www.nari.net.au/impacct), PR59 | Pagina oficial e protocolo17p conforme href publicado, elegibilidade/intervencao lidas | Terapeuta escolhe programa individual de cada praticante. Cartilha de dose/instrucao e kits VHI externos ausentes. Otago-Plus nao e apenas Otago base; direitos operacionais nao demonstrados. |
| [REACT / protocolo NIHR](https://njl-admin.nihr.ac.uk/document/download/2025815), PR56 | PDF161p, versao1.7/16May2018; Appendix4 pp63-84 lido;14paginas selecionadas visualizadas | Instrucao funcional real recebida, mas nao manual de regulagem de maquinas. Divergencias semanticas e direitos do protocolo/fotos/desenhos sem resolucao. Nao substitui suplemento2023 bloqueado. |
| [Benson / cuidadores de cancer](https://brieflands.com/journals/ijcm/articles/131622.pdf), PR60 | PDF8p; identidade/metodos/intervencao/direitos lidos | CC BY-NC4.0 explicita: fora da incorporacao comercial gratuita. CD domiciliar referido nao recebido. |
| [Benson / cuidadores de hemodialise](https://revistas.udea.edu.co/index.php/iee/article/view/351819), PR61 | HTML editorial com direitos; nao corpo integral/manual/audio | CC BY-NC-SA4.0 primaria. Nao adotar CC BY indicada por indice secundario para trocar licenca. |

Extrair texto de161paginas nao significa ler/validar visualmente161paginas. DOCX sem word/media nao significa ausencia de figuras: S1 contem caixas de texto; fluxos S1/S2 nao renderizados. Nao houve ensaio de uso com pessoas ou validacao clinica/legal.

## Proveniencia Para O APK

[Inventario reproduzivel](inventario-manuais.json): cada corpo tem ID, recibo, URL original/resolvida, bytes e SHA256. O recibo preserva data UTC, metodo GET e headers. Raw fica local e ignorado pelo Git, sem redistribuicao de textos/documentos integrais.

[Leitura de cuidadores](leitura-myten-impacct.json), [REACT2018](leitura-react-protocolo2018.json) e [mapa de campos do APK](mapa-apk-campos.json) separam:

- autoria/DOI/versao, localizador de pagina/secao/XML e fonte de cada campo;
- papel de quem pratica, ambiente, variante de equipamento e acompanhamento;
- dose recebida versus exemplo/formulario/plano individual ainda ausente;
- licenca do artigo versus direito de cada manual, foto, video ou kit essencial;
- campo pesquisado versus programa selecionado e liberacao para publicar.

Importacao futura deve resolver `sourceId -> localEvidence -> recibo + hash -> versao/localizador -> licenca por ativo`. Um DOI de artigo sozinho nao comprova procedencia de um treino completo. Campos ausentes permanecem `null`/pendentes, sem rotina montada por inferencia ou por mistura de estudos.

O mapa inclui os campos do log do My Ten como referencia, mas a lista `approvedExecutableProgrammeMappings` continua vazia. O exemplo de caminhada nao e dose; tarefas habituais de cuidar nao fazem parte desse log. Nenhum treino foi gerado, traduzido ou integrado no APK nesta rodada.

## Pendencias Exatas

| Complemento | Criterios Ainda Falsos | O Que Falta |
|---|---|---|
| N15-C | C15-G03/G04 | Selecionar programa proprio do cuidador com instrucao/dose/progressao integrais e caminho comercial dos ativos essenciais, mantendo acompanhamento quando exigido. My Ten/IMPACCT nao entregaram esses manuais; fontes Benson NC nao entram na selecao. |
| N18-I | I18-G03 | Instrucao operacional e direitos das variantes essenciais da academia para idosos; nao substituir maquinas por cadeira para declarar cobertura. |
| N19-I | I19-G03 | Percurso humano selecionado com semantica/instrucoes/direitos completos; versoes2018/2023 nao intercambiaveis. |
| N20-I | I20-G02/G03 | Postura/ajuste/apoio/execucao de todas variantes do percurso selecionado e direitos dos ativos. REACT2018 acrescenta instrucao, nao fecha os itens de maquinas ou ambiguidades. |

No REACT2018, p66 manda baixar ate sentado, mas a nota manda nao sentar completamente; p78 oferece dois limiares de demonstracao sem vinculo inequivoco a cada exercicio. Nao corrigir esses passos por plausibilidade. Ausencia de concessao comercial localizada nao significa proibicao comprovada, mas nao permite declarar os direitos demonstrados.

### Retomada Direcionada

Nao recapturar os13corpos nem repetir PMC/Zenodo/EPMC que falharam anteriormente. Reusar os hashes/leituras. A proxima pesquisa deve mirar **manual instrucional e licenca** de um percurso candidato, nao mais artigos apenas com duracao/frequencia. Para cuidadores, preservar a distincao entre rotina predefinida e cartilha escolhida individualmente por terapeuta. Para academia, manter as variantes/equipamentos do percurso humano de fato selecionado.

N18-I permanece ativo, N15-C/N19-I/N20-I pendentes; seis reusos e dez Ns fechadas para pesquisa na fila anterior. Onze complementos fechados, incluindo N15-I, nao significam N15 pai fechado. N21 somente depois de todos os complementos anteriores atenderem seus criterios, sem mudar o criterio para um resultado negativo.

## Verificacao Local

- 35 testes documentais passaram: 28 anteriores mais 7 de inventario/OOXML, incluindo hash divergente, HTML falso, limite de ZIP, caminho inseguro e runs de texto. Sem requisicoes reais nos testes.
- 13 corpos desta rodada conferidos pelo analisador; 15 fichas documentais reproduzidas sem rede, quatro ainda `parcial`.
- Indice acumulado: 342 chamadas / 286 HTTP200 / 302 corpos com hash; inclui falhas/barreiras/vazios historicos, nao 342 fontes utilizaveis.
- 131 familias: 24 candidatas, 40 condicionais, 16 incompativeis_zero, 51 referencias; catalogo nao e homologacao.
- Pacote ES2019-DOM-01 preservado: cinco instrucoes, SHA256 `39ee2f7304123c223254ac7879c430421df4180304bae5a01ed1462c23df19ee`; sem ampliar recorte domestico.
- Graphify incremental de `lib/`: 0 alterados, 42 inalterados, 0 removidos; saidas preservadas. Nao indexacao semantica dos documentos de pesquisa.
- Fila de 20 Ns validada, N21 retida; sete documentos conferidos sem erros de links locais, com avisos heuristicos de possiveis placeholders. `git diff --check` sem erros de whitespace; sem diff em `lib/test/pubspec.yaml/android/ios`. Raw ignorado pelo Git, nao conteudo publicado.

Reproduzir a nova leitura sem rede:

```powershell
& 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -X utf8 docs/conteudo/evidencias/analisar-manuais-02.py
& 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -X utf8 -m unittest discover -s docs/conteudo/evidencias -p 'test_*.py'
& 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -X utf8 docs/conteudo/evidencias/validar-fila-complementos.py
```

Executar da raiz `C:/dev/TrainForge/trainforge`. Raw local e necessario; falta de arquivo nao justifica recaptura automatica. Fontes e manifestos acima registram primeiras coletas, nao comandos para repeti-las.
