# Melhoria: pacotes regionais de alimentos que se somam

Registrada em **19/11/2026** a pedido do autor, para execução logo em seguida à feira. Estado atual e decisões de hoje estão no [handoff](../execucao/v1/handoff.md).

## Decisão do autor

- O **banco do servidor (Neon) guarda somente o pacote Brasil**. Ele não recebe os pacotes extras.
- Os pacotes extras ficam como **arquivos públicos no GitHub Releases**. O app baixa sob demanda.
- Um pacote extra **complementa** o catálogo instalado, nunca o substitui. O Brasil continua embutido no APK.
- Primeira leva: **6 pacotes de até ~150 MB compactados** cada:

| # | Pacote | Seleção (Open Food Facts `countries_tags` / `categories_tags`) |
|---|---|---|
| 1 | Europa | Países europeus, incluindo Portugal, Espanha, França, Alemanha, Itália e Reino Unido |
| 2 | EUA | `en:united-states` + USDA Branded (produtos de marca dos EUA) |
| 3 | América Latina | América Central/Sul e México, **sem o Brasil** (já embutido) |
| 4 | Ásia e Oceania | Ásia, Austrália, Nova Zelândia |
| 5 | África e Oriente Médio | África e Oriente Médio |
| 6 | Enlatados e conservas | Categorias `en:canned-foods`, conservas e similares, todos os países |

Até 150 MB cabem cerca de 200 mil produtos por pacote (o Brasil tem 57 mil em 41 MB). Regiões maiores que isso levam **os produtos mais escaneados** (`unique_scans_n`) até o limite. Isso é registrado no manifesto de cada pacote (`offLimit`, `offCandidates`), sem afirmar cobertura completa. Um produto pode estar em mais de um pacote (por exemplo, um enlatado europeu). O app desduplica por `food_id`/`version_id`.

## Por que os pacotes extras não entram no Neon

Com só o Brasil (57.326 alimentos), o banco já tem **398 MB** (~7 KB por alimento com índices e anotações). O plano gratuito tem 1 GB. Seis pacotes de 200 mil produtos não cabem.

**Solução sem mudar servidor:** quando a pessoa registra um alimento de pacote extra, o app cria uma **cópia como alimento pessoal** (`create_private_food`, fluxo já existente e sincronizado). A cópia guarda nome, nutrientes, base, porções declaradas e a fonte/licença citada. A refeição referencia essa cópia. O Neon cresce só com o que é registrado, e funciona para qualquer país.

## Como fica o fluxo para a pessoa

1. **Alimentos → Catálogo offline** lista Brasil (instalado) e os 6 pacotes com o tamanho de cada um.
2. **Baixar:** abre um aviso com o tamanho ("prefira Wi-Fi"). O progresso aparece **no próprio botão** (anel com porcentagem, toque para cancelar), igual à tela de hoje. A notificação do Android fica para quando o download precisar continuar com o app fechado.
3. **Conferência:** assinatura Ed25519 do manifesto (chave de confiança embutida no APK), hash e `quick_check` do SQLite. Só então o pacote é ativado.
4. **Busca e código de barras** passam a consultar Brasil + pacotes instalados juntos.
5. **Remover pacote** apaga o arquivo e libera espaço. Refeições já registradas não mudam, porque viraram alimentos pessoais.

## Trabalho técnico

### 1. Gerador (`tools/food_catalog_slim.py`)

- Mapear `countries_tags` → região (tabela versionada no próprio script) e categorias de enlatados/conservas.
- Pacotes **sem os genéricos** (TACO/USDA/Ciqual/CoFID já vêm no pacote Brasil). Cada pacote é um "complemento", com `"kind": "extension"` e `"region"` no manifesto.
- Orçamento por tamanho: adicionar os mais escaneados até ~150 MB gzip (medir após gerar; ajustar o limite por região).
- Somente produtos com fonte/licença presentes. Exports por fonte continuam disponíveis (oferta ODbL).
- Saída: `build/catalog-packs/trainforge-catalog-<id>.zip` + relatório com contagem por fonte/país.

### 2. App: catálogos que se somam

- `CatalogInstaller`: além do catálogo principal (`active.json`), manter `extensions.json` com os pacotes instalados (envelope assinado de cada um). Validar com a mesma confiança. Instalar sem fechar o principal; remover com segurança (nunca o arquivo em uso).
- `LocalFoodRepository` (6 consultas: lista/busca, facetas, detalhe, `foodJson`, código de barras, contagens): consultar o principal e cada extensão e **mesclar** os resultados (ordenação por relevância/nome, desduplicação por identidade, paginação estável). Alternativa a medir: `ATTACH` read-only por extensão com `UNION ALL`.
- Ao registrar alimento de extensão: converter em alimento pessoal antes da confirmação, preservando a paridade de cálculo já testada.
- Tela: lista dos 6 pacotes, instalar/remover, "Instalado", espaço ocupado. Reaproveitar aviso e progresso de hoje.

### 3. Publicação

- GitHub Release `catalog-packs-v1` (repositório público) com os ZIPs. `AppConfig.catalogPacksUrl` já aponta para essa pasta.
- Se o repositório de código ficar privado (licença proprietária), publicar os pacotes em um **repositório público separado** só para dados e ajustar `CATALOG_PACKS_URL`.

### 4. Testes e entrega

- Widget: lista de pacotes, confirmação, progresso, cancelamento, remover.
- Repositório: busca/código de barras mesclando principal + 2 extensões com item duplicado; extensão inválida (assinatura/hash) é recusada sem afetar o principal.
- Registro de alimento de extensão vira alimento pessoal e sincroniza (teste existente de outbox/paridade).
- APK release verificado (`tools/preparar_release_android.py`), docs, graphify e commit.

**Estimativa:** gerador 40 min (+ ~1 h de geração em segundo plano); app 2 h 30; testes/APK/docs 1 h. Total de **3 a 4 horas**.

## Hoje (19/11), antes desta melhoria

- APK com o **pacote Brasil** embutido. A tela de catálogo mostra o Brasil como **Instalado**, aviso de tamanho e progresso no botão.
- O pacote Brasil + Portugal (`br-pt`, 52 MB) foi gerado em `.local/food-catalog/packs/br-pt`, mas **não é oferecido**: ele substituiria o catálogo, e alimentos portugueses não sincronizariam, pois o servidor só conhece o Brasil. Ele vira insumo do pacote Europa.
