# N15-C - Originais, Seguimento e Lacunas

Rodada iniciada em07/10/2026 e continuada em08/10/2026. Escopo exclusivo: atividade do proprio cuidador. **N15-C nao fechada; G03/G04 falsos; nenhum programa novo liberado.**

## O Que Foi Recebido

30 chamadas novas,19 respostas HTTP200,18 corpos200 utilizaveis e26 hashes verificados incluindo erros. HTTP200 do script editorial acima2MiB nao produziu corpo/hash: nao contar como arquivo recebido. Falhas, captcha203 eJATS500vazio nao sao estudos. Sem retries, bypass, script executado ou contato.

Quatro guiasVA somam90paginas com texto extraido; nove paginas operacionais realmente inspecionadas. FolhetoNIVA adicional1pagina recebida/visualmente conferida, quatro gestos. Nao foi feita revisao visual integral dos guiasVA. Fontes/hash em [inventario](inventario.json), interpretacao por fonte em [leitura](leitura-fontes.json) e web sem corpo local em [triagem](triagem-web.json).

## Achados Para o APK

| Registro | Evidencia e limite | Importacao |
| --- | --- | --- |
| PR68 ReViEEW | Graduacao em Fisioterapia2018 declarada pela EHU, confirmada por releitura do corpo ja recebido. Resumo1ano: dor lombar media sem melhora significativa P0.140; nao invalidar resultado inicial12semanas ou prometer persistencia. Artigo integral1ano nao recebido. | Instrucao/aquecimento/retorno e material/licencas da modalidade selecionada ainda faltam. |
| PR68 adesao2026 | Analise exploratoria105participantes, inclui segunda onda da lista de espera. Turnos/experiencia/recursos psicossociais importam; nao so tempo disponivel. Associacao nao causa ou regra automatica de exclusao/medicacao. | Mesmo programa/familia; nao publica os ativos faltantes. |
| PR86 PMR paliativo | 66familiares,28sessoes4semanas,30min/dia; enfermeira ensina/demonstra/checa eapoia. OriginalCD/audio da TurkishPsychologistsAssociation nao recebido. | ArtigoNC-ND e ativos externos impedem presumir adaptacao comercial gratuita. |
| PR87 Walking to Wellness | Modulo especifico considera respiro/apoio para sair, dupla/cognicao/seguranca e metas educativas viaveis.13tips nao13exercicios; nao dose fixa validada ou ensaio clinico recebido do modulo. | Referencia editorial; autoria academica nao credencial clinica individual, fotos/terceiros sem concessao demonstrada. |
| PR88 Jakobsen | 200trabalhadoras hospitalares; WORKsupervisionado superiorHOME com movimentos diferentes. Planejadas5x10min/semana, realizadas2.2versus1.0. Tres cartazes404; analise tronco mesmafamilia. | Nao levar resultadoWORK aHOME retirando instrutor/material/cointervencao. |
| PR89 PMR enfermeiros | 46enfermeiros COVID19,13grupos descritos, ensino2x60min e20min/dia2semanas. CD/audio e tempos individuais/retorno ausentes. Table1 atribuida a terceiroNC. | ArtigoCCBY nao sublicencia tabela/midia; nao criar gravacao ou resolver postura contraditoria por IA. |
| PR90 respiracao Alzheimer | Piloto10cuidadores,10min/dia2semanas: resumo relata sobrecarga/ansiedade piores no grupo de intervencao. | Evidencia negativa contextual, nao rotina pronta ou prejuizo universal. |
| PR91 Benson/4-7-8 | RegistroCOMPLETED,80inscritos, semresultsSection/hasResultsfalse. Passos presentes, duracaoBenson/retorno e resultados ainda faltam. Registro posterior ao inicio. | Concluido no registro nao significa clinicamente eficaz. |

ComplementoPR88: [folheto institucionalNIVA](https://niva.org/app/uploads/Exercises-with-elasticband.pdf) recebido1p, quatro movimentos e orientacoes de treino/progressao/seguranca. Credito da campanhaJobandBody e nomes compativeis com lista do protocolo; identidade de versao2014 nao comprovada. Dose do folheto nao equivale ao programaHOME5x10min, outros cartazes/direitos ainda ausentes. Nao deixar falha404 significar que nenhum material existe, nem substituir programa por folheto de escritorio.

Fontes primarias: [seguimento PR68](https://doi.org/10.1097/JOM.0000000000003474), [adesao2026](https://doi.org/10.1007/s10926-026-10449-w), [PMR paliativo](https://doi.org/10.1002/nop2.70149), [guiasVA](https://www.mirecc.va.gov/visn16/walking-to-wellness-manuals.asp), [Jakobsen](https://doi.org/10.5271/sjweh.3479), [PMR enfermeiros](https://doi.org/10.1186/s12888-022-04456-3), [piloto respiratorio](https://doi.org/10.1016/j.gerinurse.2021.02.006), [registro Benson](https://clinicaltrials.gov/study/NCT06997523). Metadados e localizadores especificos acompanham a leitura; textos de protocolos/ensaios e resultados nao sao intercambiaveis.

## Recuperacao Sem Nova Pesquisa

`fontes.json -> sourceId/localEvidence -> leitura.families[] ou followup/adherencePR68 -> locator/receipt -> inventario.sources[].record -> recibo.url/collectedAtUtc/status/bytes/sha256/bodyFile`.

[Mapa para campos do APK](mapa-apk-campos.json) registra fonte/versao, publico/praticante, material/ambiente/preparo/suporte, dose/ausentes, desfecho/endpoint e direitos por ativo. Cadeia documental pronta para consulta editorial, **nao importador de producao implementado**. Originalguardado nao significa ativo licenciavel para embutir noAPK.

Dose ausente fica`null`. Criterio observacional de completar50% dos exercicios para contar aderencia nao autoriza reduzir a dose clinica pela metade. Sem alterar medicamentos, dispensar fisioterapeuta ou usar modelos de aderencia como triagem clinica automatica. Fatiga/turnos/apoio/disponibilidade sao dimensoes distintas de viabilidade, com fundamento explicito ou decisao de produto identificada.

## O Que Impede o Fechamento

Nao e a palavra casa. Para o PR68 prioritario faltam instrucoes integrais/preparo/retorno originais para uma entrega clara e o pacote/licencas dos ativos necessarios a modalidade escolhida. Fonte clinica e qualificacao profissional ja identificadas nao preenchem esses campos. A manutencao sem supervisao nao recebeu prova de eficacia domiciliar independente.

TesePR68: portal institucional recebido, link antigo404, sem PDF publicado localizado. TeseMontero2017: duas chamadastimeout, metadadoswebNCND, identidade com programa2020 nao confirmada. CartazesJakobsen: tres404. SuplementosCREA: quatro identificadores publicados encontrados; JS excedeu2MiB/semcorpo, coletaZIP independente terminoutimeout. Navegador nao inicializou; nenhumPDF suplemento recebido. Nao afirmar inexistencia global dos materiais, contornar barreiras ou herdarCCBY de artigo para tese/CD/cartaz.

Busca primaria na equipeAgeingOn/divulgacao/teses nao localizou os materiais ReViEEW; videos genericos de idosos/Parkinson nao os substituem. Novos programas tambem nao satisfazem simultaneamente instrucao completa, evidencia adequada, entrega e direitos gratuitos. G01/G02 cumpridos; G03/G04 nao.

Retomada: permanecerN15-C e buscar **originais operacionais/licencas**, nao repetir corpos, colecionar resumos equivalentes ou montar partes de ensaios diferentes. OutrasNs/N21 retidas. SemAPK/API/Figma/banco, contatos, commit ou push.

## Verificacao Local

Suite documental135testes; fichaN15-C108corpos/55dependencias; indice441chamadas/362HTTP200/393hashes;161familias24candidatas/62condicionais/20incompativeis/55referencias. Contagens incluem erros/barreiras/duplicatas historicas, nao quantidade de rotinas prontas. PacoteES2019-DOM-01 preservado, hash anterior inalterado. Graphify apenasDart:0alterados/42inalterados/0removidos, sem indice semantico desta pesquisa. Detalhes em [verificacoes](verificacoes.json). Testes documentais nao sao validacao clinica/legal ou testeAPK.
