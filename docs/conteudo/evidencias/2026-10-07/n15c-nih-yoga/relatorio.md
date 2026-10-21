# N15-C: Protocolo NIH e Care Me Too

Escopo exclusivo: exercicios do proprio cuidador em casa. Pesquisa documental, nao treino montado pelo agente, aprovacao clinica ou implementacao. Estado: parcial; G03/G04 continuam falsos.

## Originais Recebidos

Cinco GETs, cinco HTTP200, cinco corpos utilizaveis e cinco hashes. [Manifesto](requisicoes.json), [inventario reproduzivel](inventario.json), [leitura e registros](leitura-fontes.json), [triagem](triagem-web.json) e [verificacoes](verificacoes.json). PDF sem teto autorizado; DOCX651720bytes abaixo2MiB. ZIP25membros/3479263bytes descomprimidos/razao maxima31.95, dentro dos limites locais de inspecao. Somente XML visivel, sem executar OLE incorporado ou acessar relacoes externas.

[Lee et al.2022](https://doi.org/10.1371/journal.pone.0277009), PDF14paginas, publica o S1File (URL suffix s002) com protocolo original14/02/2018. Foram visualizadas realmente PDF1/3/4/11/12. O protocolo foi lido por secao/AppendixA em OOXML; nao declaramos inspecao visual integral do DOCX. A lista instrucional nao tem imagens ancoradas; objetos/imagens observados em outras secoes nao foram executados ou transformados em cartilha ilustrada recebida.

## Programa NIH

Schumacher (instrutor Advanced Iyengar) e Ross (PhD/RN, mestrado enfermagem psiquiatrica e professora certificada Iyengar) desenvolveram o programa; qualifica a autoria alem de simplesmente existir um artigo. Ensaio50 cuidadores familiares de primeiro HSCT alogenico,25por grupo,44concluintes. Pratica diaria20min por6semanas, ensino individual/retorno-demonstracao/pratica inicial supervisionada, suporte semanas2/4. Protocolo explicita casa/leito; cadeira/parede/superficie sao necessarias apesar de nao haver equipamentos especializados.

Nao houve diferenca entre grupos em estresse/depressao/ansiedade. Achados exploratorios de biomarcadores nao autorizam promessa de prevenir diabetes nem beneficio de cada postura isolada. Recorte nao inclui cuidador remunerado, qualquer doenca, todas as idades ou qualquer limitacao funcional. Exclusoes da analise de sangue nao sao regras universais de contraindicacao de exercicio.

AppendixA tem oito entradas, sete praticas distintas: flexao sentada, bracos na parede, inclinacao na parede, bracos sentados elevados, torcao sentada, relaxamento sentado, respiracao sentada e repeticao do relaxamento. O JSON guarda preparacao/execucao/tempos e localizadores; termino ausente permanece null. Torcao descreve somente direita: nao acrescentamos esquerda. Inspiracao/expiracao1-2min nao sao apneia. Relaxamento final3-5min nao tem roteiro explicito de saida da sessao.

Artigo/protocolo diferem na idade (>=18/>18), tempo de ensino e ordem inicial (em pe versus flexao sentada); artigo menciona backbends nao nomeados na lista. Uma passagem dos intervalos explicitos soma725-1035segundos, nao define gravacao20min: aproximacoes/narracao/transicoes podem explicar, mas nao verificadas. Nao aumentamos tempos ou repeticoes para preencher a diferenca.

Artigo e protocolo publicado possuem base editorial aberta: CC0 explicitamente no artigo, politica PLOS recebida cobre obras publicadas/reuso comercial. Isso nao licencia automaticamente audio e cartilha nao publicados/recebidos. O ensaio usa esses ativos, nao apenas a tabela. E um candidato instrucional mais forte, mas ainda nao um pacote completo fiel ao estudo. Orientacao no APK nao substitui ensino inicial e nao resolve suporte humano inexistente.

## Care Me Too

[Liu et al.2020](https://doi.org/10.2196/20325), JATS completo/licenca CC BY4 recebidos. Inclui16cuidadores formais e6familiares, laboratorio e1semana em casa,21concluintes. Descreve videos de automassagem/respiracao/imagery e necessidades de acesso, mas nao publica seus passos/doses. Dois suplementos sao guias de entrevista, nao manual de exercicios. Media de26.8min de uso do app nao e prescricao. Estudo de usabilidade nao mediu eficacia clinica ou mudanca de comportamento; artigo aberto nao licencia automaticamente videos YouTube ausentes. PR83 referencia, nao programa aprovado.

## Uso Futuro No APK

Recuperar `exerciseRecords[].id/locator` e juntar `recordDefaults`, fonte/versao/qualificacao/entrega/direitos; em seguida recibo, SHA256 e corpo original. Guardar nulls e limites. Nao copiar tabela transformando-a em audio criado por IA e alegar que e a intervencao validada. Nenhum importador, tela, audio, traducao publicada, aprovacao clinica/juridica ou contato executado.

Proximo trabalho: receber roteiro/audio e cartilha originais licenciados ou outro programa domestico especifico com instrucoes completas; resolver transicoes/versoes e acompanhamento. Nao repetir URLs com desafios/falhas para tentar desbloquear. N15-C permanece unico foco, outras Ns retidas.
