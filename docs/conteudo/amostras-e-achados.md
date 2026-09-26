# Amostras e achados da pesquisa ampliada

**Publicação inicial — 24/09/2026:** scripts, resumos, inventário e manifestos de pesquisa podem ser consultados no repositório. Planilhas, respostas integrais de fornecedores e subconjuntos indicados como “apenas local” permanecem preservados nesta máquina e excluídos do Git; sua redistribuição não foi aprovada neste incremento. Os manifestos descrevem o conjunto local original, não uma garantia de que cada arquivo está no clone. Para reproduzir os analisadores, primeiro obter legitimamente as entradas documentadas; não esperar que funcionem com todos os dados em um clone limpo.


Coleta adicional: **23/09/2026**. Reutiliza as evidências de 22/09. Os números abaixo são observações da coleta, não percentuais de qualidade do catálogo inteiro, auditoria clínica ou benchmark de disponibilidade.

## Pilotos posteriores — 26/09/2026

Acrescentamos [evidência estrutural reproduzível](evidencias/2026-09-26/pilotos-resumo.json): um programa NHS de corrida com 27 sessões e 12 padrões, conferido contra HTML e PDF; uma rotina NHS de força com sete exercícios e 20 passos de instrução na fonte; e cálculos por massa para 12 alimentos CoFID. Isso melhora a prova de obtenção e importação experimental de conteúdo humano, sem indicar treino/dieta a uma pessoa nem aprovar o lote para publicação.

Exemplo aritmético: para a entrada fictícia **150 g**, o arroz integral basmati cozido CoFID `11-867` resulta em **196,50 kcal**; a mesma massa do cru `11-866`, **532,50 kcal**. Não são porções recomendadas ou alimentos intercambiáveis. Traço, desconhecido e limites superiores permanecem identificados; não são zeros. [Resultados e método](evidencias/2026-09-26/alimentacao-piloto.json).

Uma consulta OFF limitada a 30 produtos portugueses voltou a retornar 503, sem produto recebido. Um PDF de caminhada NHLBI retornou 404. A investigação CDC/Tufts encontrou divergência entre metadados e restrição de adaptação no material: não liberado. O [balanço da etapa 01](../planejamento/etapa-01-pesquisa.md) detalha as consequências e a passagem ainda pendente para a etapa 02.

## Resultado verificável — 23/09/2026

| Fonte | Operação | Resultado | Implicação |
|---|---|---|---|
| wger | Mais duas páginas de 25, offsets 300 e 600; combinadas com offset 0 anterior | 75 IDs únicos; 6 com português, 37 com imagens, 8 com vídeo; 4 imagens assinaladas como IA | Cobertura irregular; verificar idioma e ativo individualmente |
| CoFID 2021 | Download oficial e leitura da folha `1.3 Proximates` | 2.760 alimentos; 16 buscas por prefixos; 14 encontraram correspondência; 27 linhas selecionadas | Bom material para curadoria local; correspondência de nome é problema real |
| Ciqual 2025 | Metadados do depósito oficial e Excel | 3.484 alimentos; 16 buscas; 15 com correspondência; 29 linhas selecionadas | Alternativa europeia concreta com licença no depósito, não apenas link de divulgação |
| Compêndio 2024 | Cinco tabelas: corrida, caminhada, ciclismo, condicionamento e água | 20 registros preservados, quatro por categoria; na água selecionados itens de natação | Base pequena verificável para modelar atividades, sem gerar plano de treino |
| Fineli | Endpoint público de exemplo `foods/11060` | HTTP 403 | Permissão de reutilização documentada não garante acesso por este cliente |

Evidências: [resumo](evidencias/resumo-expansao.json), [wger](evidencias/wger-amostra-ampliada.json), CoFID (`evidencias/cofid-amostra.json`, apenas local), Ciqual (`evidencias/ciqual-amostra.json`, apenas local), [manifesto SHA-256](evidencias/manifesto.json).

## Exercícios: a tradução pode mudar o movimento

No wger, **ID 1022** reúne nomes ingleses/espanhóis de remada em prancha e uma versão italiana de balanço de kettlebell com um braço. A descrição italiana também trata do balanço. É uma divergência semântica observada, não uma conclusão sobre cada tradução da base. O item deve permanecer fora de publicação até revisão. O fato de existir um ID compartilhado não garante equivalência das instruções.

Dos 75 itens, 60 trazem licença principal CC BY-SA 4 e 15 CC BY-SA 3. Essa contagem não substitui a inspeção da licença da tradução, imagem ou vídeo usado. O campo de autor e o histórico de edições tampouco demonstram qualificação profissional ou revisão técnica.

As quatro imagens marcadas IA estão na primeira amostra. As páginas adicionais não acrescentaram imagens com a flag verdadeira. Isso não certifica as restantes como fotografias humanas. Nenhuma mídia foi descarregada, republicada ou validada biomecanicamente nesta coleta.

## Alimentação: correspondência errada pode gerar números plausíveis

A amostra CoFID contém exemplos que o futuro importador precisa distinguir:

| Mesmo termo de pesquisa | Registros observados | Erro que deve ser evitado |
|---|---|---|
| Arroz | `11-867`: basmati integral cozido, 131 kcal/100 g; `11-866`: cru, 355 kcal/100 g | Selecionar o cru para uma pesagem do prato pronto |
| Banana | `14-318`: parte comestível; `14-347`: pesado com casca | Interpretar peso bruto como massa efetivamente consumida |
| Frango | Amostras incluem pele e uma variante pesada com osso | Usar a mesma composição para peito sem pele e sem osso |
| Bacalhau | Aparecem seco/salgado/cozido e carne assada | Traduzir qualquer `cod` como uma única preparação portuguesa |
| Sardinha | Conserva em salmoura e em azeite, escorridas | Ignorar líquido de cobertura e condição escorrida |

Esses valores são exemplos do arquivo recebido, não recomendação alimentar. Fonte: [CoFID oficial](https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid). As regras de seleção estão no script, com os nomes originais preservados.

As buscas iniciais por aveia e iogurte não coincidiram com os prefixos esperados em inglês. **Zero correspondências da regra não significa alimento ausente do dataset.** É preciso melhorar sinónimos, normalização e seleção humana. Também não basta aceitar o primeiro resultado: a busca por ovo selecionou uma variante desidratada.

Vinte e duas das 27 linhas CoFID têm energia/proteína/gordura/hidratos expressos como números simples. Nas restantes há indicação de traços; não são necessariamente registros incompletos. `Tr`, `N` e branco devem conservar significados distintos. A folha de notas também diferencia 100 g de alimento, 100 ml para bebidas alcoólicas e algumas folhas de ácidos gordos por 100 g de ácidos gordos. Não existe uma conversão universal segura para toda a pasta de trabalho.

No Ciqual, os seis campos de energia/proteínas/hidratos/lípidos/fibra examinados no dataset completo contêm **304 células com limite `<`, 204 com `traces` e 361 com `-`**. Esses são contadores de células, não de alimentos. As colunas distinguem energia segundo métodos diferentes e proteína pelo fator de Jones ou N × 6,25. Preservar método, unidade, valor original e qualificador é requisito de importação.

O Excel Ciqual é adequado para uma amostra simples, mas a documentação informa que a proveniência por alimento/nutriente está no XML. O arquivo de composição XML listado no depósito tem cerca de 69 MB e não foi descarregado nesta rodada: não era necessário para a triagem. Fonte: [depósito Ciqual 2025](https://doi.org/10.57745/RDMHWY) e [documentação](https://ciqual.anses.fr/cms/sites/default/files/inline-files/Table%20Ciqual%202025%20doc%20FR_2025_11_19.pdf).

## Conteúdo que parece atual, mas exige conferir edição e idioma

- **PortFIR:** a página portuguesa indexada informa v7.1/2026 e 1.376 alimentos; a inglesa ainda apresenta v7.0/2025 e 1.372. O estudo anterior deve ser lido como retrato de sua consulta. Não foi comprovada a disponibilidade de cada ficheiro da edição nova. [Histórico português](https://portfir.insa.min-saude.pt/pt/versoes-e-atualizacoes/), [inglês](https://portfir.insa.min-saude.pt/en/versions-and-updates/).
- **NIA:** o URL que historicamente continha “four types” redireciona para artigo com três categorias principais, revisto em 14/01/2025. Guardar título/data atuais, não inferir pelo URL. [Artigo atual](https://www.nia.nih.gov/health/exercise-and-physical-activity/three-types-exercise-can-improve-your-health-and-physical).
- **ACSM:** há position stand de resistência de 2026. Foi lido o resumo oficial; o acesso ao artigo integral pelo leitor retornou 402. Não foi feita uma revisão crítica integral dos 137 trabalhos de síntese. [Resumo institucional](https://acsm.org/resistance-training-guidelines-update-2026/).

## Limites técnicos registrados

Foram registradas **12 tentativas de coleta de amostras adicionais**, sendo 10 HTTP 200, um 403 e uma falha de certificado anterior a qualquer resposta HTTP. Esse número não conta consultas do buscador e navegação documental.

O download Ciqual falhou inicialmente na cadeia de certificados do Python. Uma única verificação pelo cliente nativo Windows, mantendo a validação TLS padrão, recebeu o ficheiro correto de 1.541.998 bytes. A falha original foi preservada; o sucesso está em [evidência Windows](evidencias/ciqual-2025-windows.evidencia.json). Não se desabilitou validação de certificados.

Fineli permaneceu 403; não houve tentativa de contornar restrição. As consultas portuguesas OFF da rodada anterior permaneceram registradas como 503 e não foram repetidas nesta expansão. A página principal PortFIR também teve limitações de acesso; dados de edição vieram da página oficial indexada, fato identificado na ficha AL03.

Não foram criadas contas, usadas credenciais privadas, enviadas mensagens a instituições ou coletados dados de utilizadores. As amostras contêm dados públicos de conteúdo. Os scripts reutilizam arquivos existentes, inclusive falhas, para evitar consumo repetido de rede.
