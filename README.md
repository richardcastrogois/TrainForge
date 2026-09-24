# TrainForge

**Treinar. Aprender. Cuidar da rotina.**

TrainForge é um aplicativo em desenvolvimento para integrar **treino, movimento, alimentação e acompanhamento pessoal**. A proposta é ajudar tanto quem não sabe por onde começar como quem já tem experiência e quer montar ou personalizar os seus planos.

O conteúdo de treino pretendido vem de programas criados por humanos, com origem, autoria e direitos verificáveis. O projeto não pretende gerar prescrição de treino por IA.

## O produto que estamos a construir

- **Orientação e autonomia:** percursos guiados, programas prontos e montagem/importação do próprio plano.
- **Diferentes formas de praticar:** academia, casa e ar livre; força, caminhada, corrida, yoga, Pilates, circuitos e outras modalidades com conteúdo próprio.
- **Planos compatíveis com a rotina:** objetivos, experiência por modalidade, equipamento, tempo e dias disponíveis, sem resumir a pessoa a três níveis.
- **Aprendizagem visual:** como executar, entender um plano, pesar alimentos e ler uma embalagem, com linguagem simples e detalhe técnico opcional.
- **Alimentação integrada:** organizar refeições e planos alimentares, registar quantidades e acompanhar objetivos junto à prática.
- **Registo flexível:** listas, entrada manual, celular/dispositivos e captura assistida por imagem, conforme viabilidade demonstrada.
- **Acompanhamento pessoal:** Hoje, histórico e tendências compreensíveis, com contexto e origem das estimativas.

Dores, limitações e retornos após pausa ou cirurgia fazem parte da investigação de contextos. Não são o foco exclusivo do produto, nem há um sistema de diagnóstico ou tratamento automático aprovado.

## Estado atual

**Projeto em definição de produto e viabilidade; não está pronto para uso público ou publicação nas lojas.**

| Área | Situação |
|---|---|
| Aplicativo | Base Flutter existente, com autenticação e fluxos iniciais de treino; interface final ainda por implementar |
| Backend | API Fastify/TypeScript/Prisma/PostgreSQL mantida separadamente em `bootcamp-treinos-api`; não está incluída neste repositório |
| Design | Figma v0.4 inventariado em setembro de 2026; próximos ajustes especificados, ainda não aplicados |
| Conteúdo | 43 fontes/famílias investigadas; amostras e limites documentados. Não equivale a catálogo homologado |
| Planeamento | Etapa 0 inventariada; etapa 01 aberta para fechar conteúdo, direitos, métodos e viabilidade da visão integral |
| Publicação | [Primeiro commit da base](https://github.com/richardcastrogois/TrainForge/commit/16565d5e882e89d094150e79e2a2c0934af758af) em 24/09/2026; sem deploy ou lançamento nas lojas |

O código inicial ainda contém geração de planos e fluxos de IA herdados, além de problemas conhecidos de autenticação, recorrência e histórico. A mudança de direção do produto está documentada; **essa lógica não foi removida ou corrigida nesta entrega**.

Reconhecimento por foto, dietas guiadas, GPS/conexões, sincronização e dashboard integrado são objetivos de desenvolvimento, não recursos já disponíveis. Identificação visual não comprova peso de alimento, duração da atividade ou gasto calórico individual.

## Comece pela documentação

1. [Visão completa e requisitos do produto](docs/planejamento/README.md).
2. [Pitch e decisões](docs/planejamento/pitch-e-decisoes.md).
3. [Etapas e check-ins](docs/planejamento/plano-de-execucao.md).
4. [Etapa 01: pesquisa, o que temos e o que falta](docs/planejamento/etapa-01-pesquisa.md).
5. [Mudanças futuras do Figma](docs/design/ajustes-visao-integrada.md).
6. [Guia de execução e retomada](guia-do-projeto.md), [documentação técnica](documentacao-tecnica.md) e [riscos conhecidos](docs/diagnostico.md).

[Arquivo Figma](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl). O protótipo usa estados demonstrativos; não autentica, persiste dados ou executa integrações reais.

## Desenvolvimento local

A base utiliza Flutter/Dart, Dio, Flutter Secure Storage e Google Sign-In. O `pubspec.yaml` declara Dart `^3.11.1`; as versões resolvidas estão no lockfile. Consulte o guia para configurar a API e autenticação — o repositório mobile sozinho não substitui o backend.

Na raiz deste projeto:

```powershell
flutter pub get
flutter analyze --no-pub
flutter run
```

No cenário local documentado com Android físico por USB, `adb reverse tcp:8081 tcp:8081` encaminha a porta da API. Confirme a porta do backend e a configuração de ambiente antes de usar; o padrão da API pode diferir. Não colocar credenciais de banco no aplicativo.

Não há instrução de apagar volumes ou resetar banco no fluxo normal de inicialização. Análise estática não substitui validação integrada em dispositivo.

## Conteúdo, custos e privacidade

A intenção é começar por Android e público de Portugal, com variante iOS prevista. Operar com custo mínimo é uma meta a verificar; planos gratuitos, mídia, reconhecimento, lojas e manutenção têm limites. Monetização futura por anúncios ainda depende de decisão e avaliação de privacidade.

Os catálogos de pesquisa são **candidatos e referências**, não licença geral para redistribuir conteúdos ou garantia de adequação individual. Dados/fontes de terceiros mantêm os seus direitos. Evidências brutas cuja distribuição não foi aprovada, segredos, caches, logs e configurações de máquina permanecem locais; documentação e scripts indicam essas limitações.

## Graphify e continuidade

O [índice estrutural Graphify](docs/graphify.md) orienta consultas pontuais ao código. A visão de produto é mantida nos documentos; o grafo de `lib/` não indexa automaticamente a pesquisa.

Cada incremento deve atualizar documentação/check-ins e verificar incrementalmente o grafo, preservando mudanças manuais e separando intenção, evidência e funcionalidade implementada.
