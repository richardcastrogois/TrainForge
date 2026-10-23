# Caminho da pesquisa ao APK

23/10 · visual02: busca alimentar/porção convertidas; APKdebug0.1.7+10 instalado com conta/consumo real preservados,70testesFlutter/analyze0issues. [Recibo](frontend-food-verification.json). Figmaatingiu quotaStarter para104:1260; demais referências/famílias pendentes, semcontratação. Prioridade continua todo o front antes de novas funcionalidades.


23/10 · visual01: shell/cinco abas/entrada/perfil e resumo diário real implementados noAndroiddebug0.1.6+9; Inter e22SVGs originais locais.68testesFlutter/analyze0issues. Frontend completo/fidelidade integral ainda pendentes; próxima fatia é biblioteca e alimentação. Nenhuma nova funcionalidade debackend nesta prioridade. [Evidências](frontend-shell-verification.json).


**Prioridade nova23/10:** autor quer ajustar todo o frontend para ficar exatamente igual aoFigma vigente antes de novas funcionalidades. [Plano e inventário atuais](frontend-fidelidade-figma.md). V1-020 funcional concluída com consumo real confirmado, cadastro próprio/ownership/cálculo/revisões testados; UI completa e fidelidade visual seguem abertas. [Entrega020](alimentacao-registro.md). Parágrafos datados anteriores abaixo descrevem o checkpoint anterior.

Estado vigente23/10/2026: [etapa01 encerrada](etapa-01-fechamento.md) e [etapa02/M1 concluída](etapa-02-fechamento.md). Go/API/DB/Swagger são reais localmente; authGo/Flutter têm checkpoint local, APKdebug instalado; loginGoogle Androiddebug real validado; OAuthrelease confirmado; HTTPS/testeAPKrelease com validação futura nas histórias dedistribuição. V1-014 concluída: catálogo Go/Flutter real com73metadados, busca/filtros/atribuição/versões; APK0.1.3+4 e comando de retomada em avaliacao-android.md. V1-019 concluída:6369registrosCiqual/CoFID noDBisolado, manifesto aprovado/importadorGo e backupnovo restaurado; ConsultaGo/Flutter entregue como preparação parcial020/025; cadastro e consumo pendentes. Ver alimentacao-importacao.md. Demais módulos/APKintegrado ainda não entregues. V1-003 concluída com publicação autorizada e CI remota bem-sucedida; documentação permanece transversal. Conteúdo:73metadados/439excluídos/0prática aprovada.

| Ordem / marco | Histórias | Resultado verificável | Condição de saída |
|---|---|---|---|
| M0 — recorte e decisão |001–005,002 em sequência própria,003 transversal | Lote candidato, decisão Go/fronteira e contrato editorial; revisão dos usos | Fontes/limites reais; decisões não confundidas com implementação |
| M1 — fundação e dados |007–010 e006 após revisão | API local Go, Swagger gerado por comentários, banco isolado migrado e lote real importado | Dry run/reimportação, restore e contrato verificados |
| M2 — primeira fatia vertical |011–016,021–022 | Login Android real → API Go → catálogo no DB → detalhe/autoria/seleção | Sessão segura e conteúdo permitido, sem generator fallback |
| M3 — uso e alimentação |017–020,023–027 | Registrar atividade, consultar histórico, buscar alimento e registrar consumo; recuperação | UI/API/DB coerentes com unidades, ausência e idempotência |
| M4 — confiabilidade e infraestrutura |028–033 | Segurança, baseline de carga, telemetria, pipeline e staging HTTPS | Custos/provedor aprovados; deploy e restauração reais |
| M5 — arquivo para teste |034–037 | APK assinado, jornada release validada, instalação e feedback | Roteiro real, checksum e limpeza após uso |
| M6 — iOS e expansão |038–043 | macOS/Xcode e paridade, lojas e funcionalidades posteriores | Cada capacidade tem evidência de uso/direitos/custo próprios |

As dependências exatas estão em `backlog.json`; intervalos da tabela são orientação macro e não autorização para pular dependência. É possível investigar hospedagem/contratos independentemente de um material bloqueado; não fingir que bloqueio editorial fechou.

## Avaliar antes de concluir o produto

As [respostas de21/10](decisoes-piloto.md) ampliam a cobertura do piloto: o autor quer o APK para entender o app inteiro, percorrendo todos os cenários um de cada vez. V1-001 deve mapear a cobertura pesquisada completa e suas lacunas, em vez de escolher uma única jornada ou poucos alimentos como produto final do teste. Importações continuam em lotes técnicos com direitos e qualidade conferidos.

M2 e M3 devem produzir checkpoints de APK de avaliação assim que houver fatias reais instaláveis, com versão, configuração, assinatura, proteção dos fluxos habilitados e roteiro do que pode ser testado. Usar as tarefas de034/036 também como referência de build/distribuição, antecipando somente os requisitos necessários ao checkpoint. Suas dependências e o aceite integral permanecem válidos para fechar a V1; não marcar034/036 concluídas por entregar uma build intermediária. Não aguardar todos os módulos prontos para colher feedback. M5 continua sendo o aceite integrado da V1 e sua entrega completa.

Cada checkpoint relaciona todos os cenários a um estado real: disponível para teste, incompleto, bloqueado por conteúdo/requisito ou ainda não implementado. Não usar telas, dados ou ações simulados para aparentar cobertura. O feedback orienta refinamento ou pesquisa direcionada com nova pista. Custo atualizado: priorizar fontes gratuitas; o autor indicou cerca deUS$19 como possibilidade em pagamento único e considerou valores maiores inviáveis. Assinatura não atende a essa direção; nenhuma compra foi aprovada. O inventário de fontes e cenários independe da decisão sobre uma compra específica.

## Incrementos que o agente deve executar

1. Ler índice, AGENTS e história pronta pelas dependências. Registrar escopo e limites da rodada.
2. Implementar uma fatia concreta, com contrato e dados reais quando for o fluxo integrado. Evitar migrar toda a lib/backend de uma vez.
3. Rodar verificações relevantes. Relatar o que foi executado, qual resultado e qual limitação. Não usar teste documental como comprovação clínica ou teste do app.
4. Atualizar fonte canônica: backlog, OpenAPI/modelo quando existir, achados e intenção do mapa. Regenerar a documentação versionada e conferir os mapas. `done` exige evidência.
5. Fazer commit local da unidade autorizada; push/deploy/publicação conforme o pedido e a aprovação aplicáveis. Deixar handoff com próxima ação, sem nova varredura de pesquisa sem pista.

## Critério para revisitar Go

`V1-002` registra a decisão. Se a primeira fatia exigir prazo incompatível com o objetivo do teste, apresentar o impacto e comparar com adaptar Fastify; não manter dois backends gravando o mesmo domínio para “acelerar”. A recomendação continua Go modular, mas sem alegar que Fastify é incapaz de escalar ou que mudar a linguagem resolve o domínio.

## Cobertura da visão

R01–R06 e R15–R17: catálogo, requisitos, sessão, acessibilidade e evolução multiplataforma. R07–R10/R14: fatia alimentar, registro, histórico e origem das métricas. R11: sessão/recuperação agora, sensores/GPS na041. R12/R13: imagem/OCR na042. Acompanhamento legítimo de outra pessoa e alimentação avançada na043. R18 é transversal a conteúdo, segurança, custo e operação. A matriz exata de IDs está em cada história.

23/10: [V1-013](privacidade-013.md) implementada/validada tecnicamente,18operações/Go0.4.0 e48testesFlutter. LoginAndroiddebug real/aceite privado passaram; OAuthrelease confirmado; HTTPS/testeAPKrelease continuam pendentes; aceite local011/012/013 encerrado; desenvolvimento pode seguir pelas dependências. Push dos incrementos validados autorizado, deploy não. Meta de milhões simultâneos exige carga/infraestrutura próprias, não comprovada neste checkpoint.

**Prioridade atual:** autor não quer hospedagem agora. Teste local pronto;011/012/013 concluídas com [critérios/evidência](auth-local-fechamento.md). DistribuiçãoHTTPS/release/iOS permanece futura, sem bloquear consultas noemulador.
