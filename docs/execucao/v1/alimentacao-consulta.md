# Consulta alimentar de referência — checkpoint Android

Implementação local de22/10/2026: API Go0.3.0 e Flutter/APKdebug0.1.2+3 consultam o lote real importado na [V1-019](alimentacao-importacao.md). Esta é uma preparação parcial deV1-020/025. Cadastro próprio, registro de consumo, cálculo de porção, refeições e totais continuam pendentes das dependências e do aceite Google; essas histórias não estão concluídas.

## Contrato entregue

| Método e rota | Comportamento |
|---|---|
| GET /api/v1/foods | q, sourceId, limit1–50(default20), cursor; lista sem carregar nutrientes |
| GET /api/v1/foods/filters | Fontes, contagens e referências sem base confirmada, somente entre registros visíveis |
| GET /api/v1/foods/{id} | Detalhe; versionId SHA-256 opcional, versão mais recente por padrão |

Busca literal no nome original, ignorando caixa e uniformizando espaços apenas na comparação. Quebras de linha do nome da fonte não são removidas do registro. q limitado a100bytesUTF-8; o app pede usar parte do nome quando excedido. Cursor vinculado a busca/fonte/tamanho, ordenação estável pelo identificador derivado da fonte; não representa ordem alfabética, recomendação ou ranking nutricional. Filtro por preparo separado ainda não existe: o preparo permanece no nome original.

Somente versões sem titular privado, com fonte, operações food_catalog e food_composition, revisão vinculada a lote importado e sem retirada são consultáveis. A seleção da versão mais recente ocorre antes da permissão: não ressuscita uma anterior porque a atual ficou indisponível. Consulta explícita de versão também verifica sua retirada e permissão. ETag é calculado depois dessas verificações; retirada prevalece sobre304. Cache privado exige revalidação em cada uso. Erros400/404/503 seguros; sem corpo de requisição ou credenciais em logs.

Migration00006 adiciona somente índices de versão/consulta do lote. Migration00005 já aplicada permanece imutável. O runtime conserva somente SELECT nas tabelas editoriais. Nenhum POST alimentar foi implementado.

## Fidelidade dos dados e interface

6369referências:3484Ciqual/2885CoFID. As2identidades conflitantes do código13-669 permanecem excluídas. As3bases desconhecidas continuam null, sem escala. Idioma, nome, código, publicação, versão, fonte e licença aparecem no detalhe; não houve tradução automática nem inferência de preparo. Quebras de linha em nomes/cabeçalhos são apresentadas como espaços para leitura; os campos originais daAPI/DB permanecem intactos. Declarações e métodos diferentes são exibidos em colunas separadas.

Valores exatos permanecem strings decimais; zero real aparece como zero. Ausência, traço, presença sem quantidade, limite superior e célula não interpretada têm rótulos distintos. A base de cada célula é exibida separadamente: uma base geral conhecida não substitui a base desconhecida/conflitante de um nutriente. Não há soma, conversão de porção, peso por foto, dieta prescrita ou calorias pré-preenchidas.

Entrada **Consultar alimentos sem registrar consumo**, disponível sem login e na conta conectada. Busca com atraso de400ms e descarte de respostas antigas, filtro de fonte, paginação, atualização, vazio/erro/retry. Lista e detalhe revalidam ao voltar ao primeiro plano. O detalhe não mantém valores antigos na tela durante uma atualização que pode revelar retirada. As URLs da fonte/licença são selecionáveis; não abrem navegação externa automaticamente.

## Verificação e limites

- [HTTP do lote real](food-read-verification.json): todas as páginas, identidades sem duplicação, fontes, busca original, campos do detalhe comparados aoDB, bases desconhecidas, ETag e identidade protegida; nenhuma conta/refeição criada.
- [PostgreSQL descartável](food-import-fixtures-verification.json): cadastro privado e fonte sem revisão excluídos, contagens sem vazamento, cursor vinculado, busca literal/multilinha, retirada antes de304, versão nova indisponível sem fallback e falta de grant. Fixtures removidas com aDB; não validam login Google.
- Flutter: estados de nutrientes, busca antiga, busca longa acentuada, paginação/erro/vazio, detalhe indisponível, atribuição e tela320x568 com texto2x. Testes de sessão e catálogo preservados. Teste de rolagem de logout agora aguarda o novo frame antes do toque.
- [APK e inspeção](android-auth-checkpoint.json): assinatura debug existente, hash doAPK instalado conferido. Capturas locais somente das telas públicas, após conferir app em primeiro plano e0contas; sem captura de login/Google. A falha deGooglePlayServices observada no emulador foi dispensada sem alterar contas ou configurações; sua resolução não foi comprovada por login real.
- Swagger gerado por comentários/DTOs:14operações reais. [Avaliação ao retornar](avaliacao-android.md).
- O backup/restore alimentar já validado não foi repetido por causa da leituraHTTP. O novo índice não altera dados. O backup alimentar validado contém migrations até00005; após restaurá-lo, aplicar00006 antes de retomar esta build. iOS e release/HTTPS continuam sem validação.

Para repetir quando houver mudança relevante: tools/verificar_importacao_alimentos.py usaDBdescartável; tools/verificar_consulta_alimentos.py requer API local existente e faz somente leituras no lote real. Não instala ferramentas nem coleta novamente as fontes.
