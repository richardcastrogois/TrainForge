# Qualidade, testes e lançamento

Base de 17/09/2026, ampliada em 24/09/2026 para [R01–R18](README.md). Plano de validação; os testes abaixo ainda não foram implementados/executados por esta entrega.

## Rastreabilidade

Cada requisito deve ligar: `requisito → tela/estado Figma → caso de uso → contrato → regra de persistência → teste → evidência`. Exemplo: retomar treino após encerramento do app exige tela de retomada, sessão local durável, sincronização idempotente e teste com processo encerrado. Uma seta correta no Figma não comprova esse requisito.

## Cenários prioritários

| ID | Cenário e resultado esperado |
|---|---|
| T01 | Novo utilizador configura só treino; alimentação mostra convite contextual e abre apenas os campos pendentes. |
| T02 | Trocar abas preserva filtro/scroll e não repete pedidos com cache válido. Atualização de resumo não apaga conteúdo existente. |
| T03 | Expirar token durante chamadas paralelas não dispara refresh concorrente descontrolado; logout revoga/limpa conforme política. |
| T04 | Trocar conta não revela cache, fotos, operações pendentes ou histórico da anterior. |
| T05 | Registar série offline, encerrar processo e reabrir preserva sessão; reenviar operação após timeout não duplica registro. |
| T06 | Treino concluído na semana anterior não bloqueia nova ocorrência; treino parcial e descanso têm contagem definida. |
| T07 | Trocar plano mantém histórico; alterar catálogo não altera o treino já executado. |
| T08 | Alteração do fuso e horário de verão de Lisboa não desloca indevidamente registros por data local. |
| T09 | Vírgula decimal, gramas, porções e dados nutricionais ausentes são tratados corretamente; desconhecido não aparece como zero. |
| T10 | Negar câmara/GPS/notificações permite continuar no fluxo aplicável; permissão revogada nas definições tem tratamento. |
| T11 | Sem tiles, o mapa mostra indisponibilidade sem inventar percurso; gravação segue a política de GPS aprovada. |
| T12 | Chamada telefónica/background/retorno não perde sessão; temporizador recalcula a partir do tempo persistido. |
| T13 | Teclado não cobre campo/CTA; autofill, mostrar senha, voltar, scroll e erros preservam dados. |
| T14 | Texto ampliado, leitor de tela, contraste e movimento/transparência reduzidos mantêm as funções utilizáveis. |
| T15 | Fonte externa retorna 429, timeout, payload incompleto ou remove ativo: app aplica fallback e informa limitação sem inventar dados. |
| T16 | Excluir refeição/foto/conta trata servidor, cache, ativos e fila pendente; uma sincronização antiga não ressuscita informação excluída. |
| T17 | Dois dispositivos editam a mesma entidade: conflito não sobrescreve silenciosamente dados importantes. |
| T18 | Dashboard distingue dia sem registro, treino não feito e incompleto; resumo e detalhe usam a mesma regra. |

## Cobertura adicional da visão integral

Cenários futuros, ainda não executados; complementam T01–T18.

| ID / requisitos | Cenário e resultado esperado |
|---|---|
| T19 / R01,R03 | Iniciante sem plano próprio encontra programa humano completo com instruções; catálogo apenas de exercícios não satisfaz o aceite |
| T20 / R02,R04 | Mesma pessoa tem experiência distinta em força/corrida; tempo, dias e equipamento restringem seleção sem inventar adaptação do programa |
| T21 / R02,R05 | Yoga/Pilates/circuito/atividade por distância usam unidades e sequência próprias; mídia corresponde ao movimento e texto continua disponível |
| T22 / R03,R10 | Importação preserva sequência/dose/progressão da fonte; alteração pessoal é identificada e não conserva selo de revisão automaticamente |
| T23 / R06 | Dor/contexto clínico fora da cobertura não dispara diagnóstico, tratamento ou progressão inventada; retorna limite e caminho pertinente |
| T24 / R07,R09 | Alimentação planeada e consumida permanecem distintas; alterar objetivo/receita não reescreve histórico nem cria dieta clínica automática |
| T25 / R08,R15 | Exemplo de rótulo ensina 100 g versus porção consumida; cru/cozido, unidade e alergénio desconhecido não são confundidos |
| T26 / R11 | Celular e fonte conectada reportam a mesma corrida: resolver duplicado sem somar duração/calorias duas vezes |
| T27 / R12 | Foto de exercício sem informação temporal não gera duração/gasto como se fossem medidos; OCR do painel mantém campos ausentes e revisão |
| T28 / R13 | Foto reconhecida incorretamente permite trocar alimento e quantidade; nenhum registro definitivo ocorre antes da confirmação |
| T29 / R12,R13 | Código/OCR/reconhecimento indisponível, modelo não baixado ou permissão negada oferece entrada manual; não envia foto sem informar o processamento |
| T30 / R09,R14 | Dashboard separa ingestão, energia ativa/total/basal e origem; não infere perda de gordura de calorias ou massa muscular de peso |
| T31 / R14,R15 | Pessoa entende próxima ação e tendência; pode escolher métricas e detalhe técnico; sem dados não aparece falha pessoal ou zero inventado |
| T32 / R16,R17 | Configuração adiada retorna só aos campos necessários, preserva rascunho/aba, teclado e progresso após interrupção |
| T33 / R18 | Licença retirada, limite gratuito atingido, conexão revogada ou exclusão de mídia têm política aplicável sem vazamento ou cobrança inesperada |

Avaliar o reconhecimento com conjunto representativo e critérios definidos antes do teste: confusões por alimento/preparo, campos OCR/unidades, necessidade de correção, tempo, bateria e custo. “Acertou uma foto” não homologa a função. Conteúdo clínico/nutricional precisa da revisão competente para seu escopo, além dos testes de software.

## Estratégia por camada

- Figma: auditoria estrutural e teste manual dos percursos, incluindo retorno e erro. Guardar diferenças não simuláveis.
- Domínio: testes de recorrência, métricas, unidades, estados e conflitos; validar regras, não apenas reproduzir código.
- API: schemas, autorização por recurso, paginação, erros, idempotência, concorrência e compatibilidade de contratos.
- Persistência: migração em base descartável, restrições, transações, histórico, exclusão e restauração de backup.
- Flutter: componentes e acessibilidade, navegação, estado, armazenamento e integração com APIs simuladas; depois testes em dispositivo com backend de teste.
- Ponta a ponta: ao menos conta → treino → registro → sincronização → histórico, com rede instável e retomada.

Seeds e cenários devem usar dados fictícios. Não copiar informações reais de saúde para logs, testes ou capturas compartilhadas. Remover logs de credenciais/dados apontados no diagnóstico antes de qualquer beta público.

## Desempenho e experiência

Definir dispositivos de referência Android e, separadamente, iPhone; medir primeira abertura, abertura com sessão/cache, troca de abas, gravação, consulta e sincronização. Separar tempo de interface, rede, servidor e retomada do banco. Usar percentis e volume de amostra informado, não apenas uma execução rápida.

Critérios iniciais verificáveis: nenhuma consulta duplicada de bootstrap; nenhuma recarga completa por mera troca de aba com cache válido; registro local preservado após interrupção; nenhuma mídia pesada carregada sem necessidade. Estabelecer orçamento de latência e memória depois da medição inicial. Medir frames perdidos durante animação/mapa, bateria durante GPS e tamanho de instalação. Não prometer fluidez em todos os dispositivos sem teste.

## Preparação das lojas e operação

1. Identificador definitivo, assinatura, guarda de chaves, versionamento, build reproduzível e ambientes separados.
2. HTTPS, permissões mínimas, URLs de produção e revisão das dependências/licenças; retirar configuração de debug e loopback do release.
3. Política de privacidade, termos, contato de suporte, retenção/exclusão, formulários de dados das lojas e declarações de saúde/publicidade coerentes com o app real.
4. Beta com utilizadores de referência e captura de falhas sem dados sensíveis. Para contas pessoais novas elegíveis, a Google exige teste fechado com pelo menos 12 testadores por 14 dias contínuos antes de solicitar acesso à produção: conferir [regra oficial](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-GB) na publicação.
5. Capturas e descrição honestas, revisão de acessibilidade e rede ruim, orçamento aprovado e monitorização de quota.
6. Procedimento de rollback compatível com migrações, backups e restauração testada; instruções de suporte a falha de sincronização e indisponibilidade de fonte.

Android é a trilha de lançamento inicial proposta. A trilha Apple adiciona ambiente de build, assinatura, dispositivo, requisitos de login, materiais/gestos e testes de acessibilidade próprios. O protótipo Apple pode avançar antes disso, mas não comprova prontidão para App Store.

## Critério de pronto para beta

Fluxos aprovados implementados e testados; problemas críticos do diagnóstico resolvidos ou explicitamente excluídos por recorte; nenhuma exposição conhecida de dados/credenciais; contratos e migrações consistentes; fontes/licenças aceites; funcionamento com interrupção/erro; limites e custos conhecidos. Documentação e Graphify atualizados por incremento. Não exigir testes sem relação com risco, nem declarar pronto apenas porque análise estática passou.
