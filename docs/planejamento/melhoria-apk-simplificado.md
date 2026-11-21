# Melhoria: APK mais simples e didático, sem perder o que já existe

Registrada em **20/11/2026** a pedido do autor. É um **plano**: nada foi removido nem ocultado. O autor ainda não decidiu o que sai. Este documento organiza **como decidir** e **como manter registrado** o que ficar de fora.

## Objetivo

Um APK menor e mais fácil de entender e de apresentar, com poucas telas e um caminho principal claro, sem apagar o trabalho feito. Tudo que sair do APK simples continua no repositório, documentado, testado e recuperável.

## Princípio: ocultar antes de apagar

Para não perder o que já se sabe fazer, cada funcionalidade passa por três níveis, nesta ordem:

1. **Ocultar no APK simples**: o código continua compilando e com testes, mas a entrada fica desligada nessa variante. É o padrão.
2. **Tirar do APK simples**: o código continua no repositório, mas não entra no binário. Serve para o que pesa: dependências nativas (scanner, câmera) e o catálogo.
3. **Apagar do repositório**: só com decisão explícita do autor, depois de uma tag Git que preserve a versão completa.

Mecanismo a decidir na etapa 2 (abaixo):

- **Flavor Android + `--dart-define`** (`TF_EDITION=simple|full`): uma base de código, dois APKs. As rotas e abas leem a edição em `lib/core/config`, e o `production_dependencies.dart` monta só o necessário.
- **Branch ou tag "completo" + `main` simplificada**: mais simples de entender, mas as duas versões se afastam com o tempo. Não recomendado.

## Etapa 1: inventário do que existe hoje

Base: `lib/features/` em 20/11/2026 (contagem de arquivos e linhas Dart). As colunas "Proposta" e "Motivo" ficam **em branco para o autor decidir**.

| Funcionalidade | Pasta | Tamanho | O que faz hoje | Proposta | Motivo |
|---|---|---|---|---|---|
| Entrada e login Google/visitante | `auth/` | 11 arq., ~1,9 mil linhas | Cena de entrada, Google, visitante, sessão | | |
| Termos e consentimentos | `legal/` | 6 arq., ~1,2 mil linhas | Aceite de uso e de dados de saúde, com versão e hash | Manter (exigência legal) | LGPD art. 11 |
| Hoje | `home/` | 1 arq., ~0,4 mil linhas | Resumo do dia | | |
| Biblioteca de exercícios | `catalog/` | 7 arq., ~1,8 mil linhas | 73 metadados de consulta, sem prática liberada | | |
| Configuração de treino | `training_configuration/` | 5 arq., ~1,4 mil linhas | Etapas de contexto, ambiente e recursos | | |
| Atividade/execução | `activity/` | 5 arq., ~1,9 mil linhas | Ocorrências e sessão (V1-017/023 em andamento) | | |
| Busca de alimentos e catálogo offline | `food_reference/` | 11 arq., ~2,7 mil linhas | Busca FTS, detalhes, instalador do catálogo, ferramentas de pacotes | | |
| Scanner de código de barras | `food_reference/barcode_scanner_page.dart` | 1 arquivo + `mobile_scanner` | Leitura EAN (teste nativo amplo ainda falhando) | | |
| Refeições e diário | `nutrition/` | 30 arq., ~7,8 mil linhas | Refeição, rascunho, diário, totais, porções, paridade de cálculo | | |
| Alimento próprio e contribuição | `nutrition/own_food_*`, `food_contribution_page.dart` | parte de `nutrition/` | Cadastro de alimento pessoal; contribuição opcional | | |
| Fila offline e sincronização | `nutrition/offline_*`, `nutrition_sync.dart` | parte de `nutrition/` | Fila cifrada por conta e painel de sincronização | | |
| Privacidade/exclusão | `privacy/` | 5 arq., ~0,7 mil linhas | Exportar e excluir dados | Manter (direito do titular) | LGPD |
| Idiomas | `lib/l10n/` | 5 ARB (en, es, pt, pt_BR, pt_PT) | Interface em 4 idiomas | | |
| Animações de entrada | `core/motion`, `StaggeredEntrance` | — | Respeitam "reduzir movimento" | | |

Fora do Flutter, também entram na decisão:

- **Catálogo embutido**: `assets/food_catalog` tem cerca de 40 MB (Brasil, 57.326 alimentos, 103 MB instalado). O APK release 0.5.4 tem 139 MB. Opção a medir: embutir só os genéricos (TACO e afins, poucos milhares de itens) e baixar o resto sob demanda, junto com os [pacotes regionais](melhoria-pacotes-regionais.md).
- **API**: os endpoints de treino continuam no servidor. O APK simples só deixa de chamá-los.

## Etapa 2: decidir com o autor

Para cada linha do inventário, o autor responde:

1. Isso aparece na apresentação ou no uso diário da piloto?
2. Funciona de verdade hoje ou mostra uma tela "bloqueada" ou "ainda não implementada"?
3. Quanto pesa no APK e na explicação?
4. Nível: ocultar, tirar do APK ou apagar.

Proposta inicial, **a confirmar**: o APK simples fica com entrada, termos, alimentação (busca, refeição, diário, totais) e privacidade. Treino e atividade saem enquanto V1-015/016 seguem bloqueadas por conteúdo, porque hoje mostram mais limitação do que uso.

## Etapa 3: registrar o que saiu (para "não esquecer o que já sei")

- Uma tag Git `completo-0.5.4` (ou a versão vigente) antes de qualquer mudança.
- Uma seção **"Fora do APK simples"** neste documento, com uma linha por item: o que faz, onde está o código, testes que o cobrem, por que saiu e como religar (flag ou flavor).
- Os testes das funcionalidades ocultas continuam rodando na suíte completa. Desligar no APK não pode desligar o teste.
- O backlog não muda de status por causa disso: ocultar não é concluir nem cancelar uma história.
- O "didático" também vale para o código. Atualizar `docs/aprendizado/` com um roteiro curto do APK simples: telas → controllers → repositórios → API.

## Etapa 4: implementação e verificação

1. Criar a edição (`TF_EDITION`) e o ponto único que liga e desliga rotas e abas.
2. Montar as dependências por edição em `lib/composition/`.
3. Se for decidido, tirar dependências nativas e reduzir o catálogo embutido no flavor simples.
4. Medir: tamanho do APK das duas edições, testes Flutter completos, análise 0 e navegação no emulador e no celular.
5. Atualizar documentação, diagramas e Graphify conforme o fluxo de pendências.

## Perguntas em aberto

- O APK simples substitui o link público atual ou convive com ele (dois downloads)?
- Manter 4 idiomas ou só pt-BR na edição simples?
- O scanner de código de barras fica (útil, mas o teste nativo ainda falha e pesa no APK)?
- A voz (ver [pesquisa voz e foto](pesquisa-registro-voz-e-foto.md)) entra na edição simples, como alternativa ao formulário?
