# Diagnóstico e decisões a rever

**Leitura em 24/09/2026:** diagnóstico do código histórico, não definição do escopo futuro. A [visão integrada](planejamento/README.md) e o [balanço da etapa 01](planejamento/etapa-01-pesquisa.md) prevalecem para decisões de produto. Os problemas técnicos abaixo não foram corrigidos por atualizar documentação.


09/09/2026. Revisão de código e configurações, com análise estática. Severidade expressa prioridade para o produto; não representa incidente comprovado em produção. Nenhum defeito abaixo foi corrigido nesta etapa.

## Avaliação principal

A migração para Flutter e a separação por features são bases coerentes com um app móvel. Não há evidência de que seja necessário reescrever tudo outra vez. Há, porém, uma transição incompleta: a API ainda mora no projeto anterior, o app ainda oferece IA e o gerador manual não implementa o catálogo humano desejado.

Um app instalado resolve distribuição e experiência de acesso, mas não elimina sozinho consultas redundantes, latência do servidor ou dependência de rede. A lentidão histórica relatada é uma evidência de uso do autor; suas causas exatas não foram reproduzidas. O código atual já tem melhorias posteriores e também novos gargalos identificáveis.

## Achados prioritários

| ID / prioridade | Evidência | Consequência e direção de correção |
| --- | --- | --- |
| A01 — alta | `lib/core/http/app_dio.dart` registra `options.data` e `response.data` completos; `AppLogger` chama `developer.log` sem guarda de debug | ID token Google, access/refresh tokens e dados físicos passam por logs. Remover corpos de autenticação e adotar redação/allowlist; não compartilhar logs atuais sem revisão |
| A02 — alta | `src/routes/mobile-onboarding.ts` recebe `preferences.restrictions`, mas não passa ao builder; builder não aceita esse campo | Interface sugere considerar restrições que são ignoradas. Não publicar como plano individual adaptado; redesenhar o fluxo e a origem dos planos |
| A03 — alta | `WorkoutDayPage.hasCompletedSession` considera qualquer sessão concluída; `GetWorkoutDay` retorna todo o histórico | Concluir uma segunda-feira impede iniciar a mesma rotina numa segunda-feira futura pela UI. Definir sessão atual por data/estado, preservando histórico |
| A04 — alta | Última migration `20260321144259_partialunique` remove os três índices da migration anterior | Banco recriado não terá os índices parciais de plano ativo/sessão aberta/refresh. Investigar intenção e corrigir com migration nova; testar concorrência em banco isolado |
| A05 — alta | API emite refresh token; modelo Flutter ignora o campo; logout não chama API | Renovação e revogação incompletas. Implementar contrato de ciclo de sessão e tratar concorrência de refresh |
| A06 — alta antes de release | Android com `com.example.trainforge`, assinatura debug em release, INTERNET ausente do manifest principal; URL HTTP loopback fixa | Build de desenvolvimento não equivale a app distribuível. Configurar identidade, assinatura, rede e ambientes antes de testes da loja |
| A07 — média | `AuthGate` descarta `bootstrap.homeData`; HomePage busca o mesmo conteúdo | Requisição e consultas duplicadas na entrada. Reutilizar bootstrap com política explícita de atualização |
| A08 — média | `AppShell` alterna `pages[currentIndex]`; repositories não guardam dados | Reentrada nas abas pode recarregar; sem treino disponível offline. Definir preservação de estado/cache e depois sincronização |
| A09 — média | `GetStats` e `GetHomeData` filtram só plano ativo | Trocar plano faz histórico anterior sumir das métricas; leitura não corresponde à evolução global |
| A10 — média | `calculateWorkoutStreak` conta descanso e interrompe no treino de hoje não concluído | Sequência pode premiar descanso sem exercício ou zerar antes do fim do dia. Definir regra de produto e testar datas |
| A11 — média | Refresh verifica `revokedAt` antes da transação e atualiza por ID sem condição de não revogado | Duas requisições simultâneas podem validar o mesmo token antes da rotação. Risco por inspeção; reproduzir com teste concorrente |
| A12 — média | Rate limiter com `global:false`, chave baseada em `x-forwarded-for`, estado local; locks em `Set` | Limite “global” não protege todas as rotas; spoofing depende da camada de proxy; múltiplas instâncias não compartilham locks. Rever na arquitetura de deploy |
| A13 — média | Dados físicos atualizados antes de criar o plano | Falha de geração deixa perfil alterado sem plano. Definir atomicidade e estados de falha |
| A14 — média | `env.ts` exige chave Gemini e rotas IA continuam registradas | App desejado sem IA ainda não pode ser operado simplesmente omitindo a chave; remover fluxo/dependências/configuração em conjunto |
| A15 — média | Nenhuma suíte de produto localizada; checks foram com dependências já instaladas | Tipagem não cobre autorização, recorrência, concorrência, offline e publicação. Criar cenários na fase 3 |

As referências `src/...` e `prisma/...` acima são relativas a `C:\dev\bootcamp-treinos-api`; `lib/...` é relativo ao app.

## O que foi uma boa decisão

- **Flutter:** oferece uma base compartilhada para Android e iOS. Manter é uma hipótese razoável; ausência de frontend definitivo não significa ausência de código aproveitável.
- **Dio central e secure storage:** bons pontos de extensão para ambientes, autenticação, redação de logs e tratamento de falhas.
- **Features/data/domain/presentation:** torna a retomada navegável sem exigir uma arquitetura pesada agora.
- **Casos de uso da API separados das rotas:** compartilham regras entre web e mobile e facilitam testes futuros.
- **Propriedade dos recursos validada:** os casos de plano/dia/sessão verificam a cadeia do utilizador antes de agir.
- **Zod e validação de domínio:** schema de entrada/saída e regras de sete dias/ordenação evitam diversas inconsistências estruturais.
- **Transações e bloqueios de linhas:** início/fim de sessão já têm preocupação real com concorrência; a existência do problema de índices não anula esse trabalho.
- **Bootstrap e select/Promise.all:** houve esforço de diminuir chamadas e dados transferidos. A adoção pelo cliente precisa ser completada.
- **Troca de plano com preservação:** desativa o plano anterior em vez de apagá-lo. Falta exibir o histórico de forma coerente.

## O que não atende mais à direção desejada

O builder manual é automático, embora não use LLM: escolhe templates, dias, séries, repetições e pausas. Não é um editor livre nem uma API de planos humanos. Não basta trocar o texto “IA” por “manual” para obter confiança ou rastreabilidade.

A duração escolhida apenas muda a estimativa; peso/altura/idade/gordura não mudam o plano. A coleta obrigatória de gordura corporal também cria fricção para quem não sabe esse valor. Na fase 3, coletar apenas o que tiver finalidade e decidir o que pode ser ignorado/pulado.

Sessões atuais são início e fim do dia, não diários de execução. Para musculação, carga e séries realizadas serão um domínio próprio; corrida precisa de duração/distância/ritmo e eventualmente GPS; alimentação exige porções e fontes de composição. Unir esses domínios numa única tabela genérica antes de entender seus contratos aumentaria o retrabalho.

## O que não é necessário agora

Não há justificativa atual para microserviços, Kubernetes, múltiplos bancos, um serviço de IA próprio, dezenas de integrações de saúde ou reescrita de todo o backend. Também não é necessário manter o Next.js para o Flutter funcionar. Uma API modular, um banco e escopo de lançamento pequeno são hipóteses suficientes para estudar na fase 3.

Não é preciso fechar agora a API pública, o fornecedor de anúncios, uma biblioteca Liquid Glass ou o design completo. O protótipo desta etapa serve para conversar sobre prioridades e navegação.

## Publicação e viabilidade

**Vercel + Neon é intenção, não infraestrutura já escolhida.** O modelo cliente → API → PostgreSQL é compatível conceitualmente com essa separação, mas o deploy precisa ser validado com o Fastify real, Prisma, conexões e limites. Locks/limites locais também precisam de revisão ao distribuir a API.

O requisito de custo zero deve ser separado em: desenvolvimento local sem tokens, piloto dentro de cotas, lançamento comercial e crescimento. Vercel Hobby restringe uso comercial; lojas têm taxas. Não há como prometer operação comercial eternamente gratuita. [Vercel](https://vercel.com/docs/plans/hobby), [Google](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en), [Apple](https://developer.apple.com/programs/enroll/).

Neon continua candidato a avaliar com limites, armazenamento, conexões, região e comportamento de suspensão/retomada do plano escolhido. Não foi criada conta, projeto ou branch. [Neon](https://neon.com/pricing).

Para Portugal, preparar português europeu, unidades métricas, `Europe/Lisbon` quando aplicável e política de dados coerente com o público. Dados de saúde recebem proteção especial no RGPD; a finalidade da coleta e o uso de dados em anúncios precisam ser tratados antes da implementação comercial. [Comissão Europeia](https://commission.europa.eu/law/law-topic/data-protection/rules-business-and-organisations/legal-grounds-processing-data/sensitive-data_en).

AdMob é somente um exemplo a avaliar: possui requisitos de consentimento para anúncios na Europa e regras próprias de moeda/conta. Receber utilizadores portugueses não muda automaticamente a moeda de pagamento. [Consentimento](https://support.google.com/admob/answer/13554020?hl=en), [moedas](https://support.google.com/admob/answer/7276705?hl=en-GB).

Liquid Glass é uma direção de experiência para iOS, não um componente que aparece automaticamente porque o app usa Flutter. A escolha de integração nativa, biblioteca ou tratamento visual equivalente fica para estudo de compatibilidade/desempenho na fase 3. [Apple](https://developer.apple.com/documentation/technologyoverviews/liquid-glass).

## Ordem recomendada para a próxima decisão

1. Confirmar esta reconstrução: Flutter é produto principal; API do bootcamp contém o backend atual.
2. Definir fronteira do GitHub: app isolado com dependência documentada, ou estrutura que inclua backend preservando seu histórico. Não mover nada sem resolver isso.
3. Pesquisar fontes por categoria (exercício, programa, alimento), com licença e autoria como filtros eliminatórios.
4. Fechar o primeiro fluxo completo e seus cenários antes de construir corrida/alimentação.
5. Corrigir bloqueadores de uso real e segurança, depois medir desempenho do fluxo em aparelho.
