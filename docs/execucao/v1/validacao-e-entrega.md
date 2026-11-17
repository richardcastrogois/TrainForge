# Validação e entrega: como interpretar e testar o estado atual

Consolidado em **17/11/2026**. O APK debug **0.4.7+29** foi compilado, teve assinatura/hash e correspondência às fontes conferidos; **não foi instalado nem publicado**. O último checkpoint instalado documentado foi0.4.6+28. Inspecionar o aparelho antes de agir: um relato antigo não descreve a tela atual.

<a id="android"></a>
## Avaliação Android local

O roteiro é emulador primeiro, depois Android físico com orientação. Os comandos de operação, logs, portas e parada ficam em [aprendizado](../../aprendizado/operacao-local.md). Iniciar normalmente usa os recursos provisionados; não chamar `init`, `activate`, importação ou restore para abrir o ambiente.

```powershell
python tools/ambiente.py status
python tools/ambiente.py start
python tools/avaliar_android.py prepare
```

`prepare` compila e confere o artefato; não instala. `avaliar_android.py start` tem efeitos próprios no ambiente/emulador e deve ser usado diante de uma avaliação concreta, preservando a conta e formulários. Não executar testes Flutter/análise/geração de localização em paralelo ao prepare: ele exige fontes estáveis.

O APK está em `build/app/outputs/flutter-apk/app-debug.apk`. Debug local e `adb reverse` não disponibilizam a API aos colegas. Distribuição por link exige API acessível por HTTPS, configuração de ambiente/OAuth, assinatura/release e validação de privacidade/operação. O propósito continua móvel; não há plano de substituir o app por uma versão web.

<a id="interface-e-figma"></a>
## Interface, Figma e material para apresentação

Figma é a referência visual aprovada, com marcaTF, Inter, Grafite/lima, rolagem Android sem esticar e apresentação clara/escura. O protótipo tem muitos quadros de variação; quantidade de quadros não equivale a telas implementadas. O shell mantém cinco abas; execução usa estados na mesma superfície.

Os [SVGs em design](../../design/README.md) são estudos históricos e foram preservados para a apresentação. Eles não são screenshots atualizados do APK. A pasta [SENAS](../../apresentacao-senas/output/Roteiro-e-pendencias.md) foi mantida integralmente. As prévias novas de Atividade são fixtures isoladas, em `.local/activity-preview`; não demonstram prática humana real.

No checkpoint recente, testes cobriram formulários320px/texto2x, pt-BR/pt-PT/inglês/espanhol, temas e descarte de respostas de outra conta. Isso não substitui TalkBack, teclado, contraste e aceite humano em dispositivo. A avaliação nativa iOS não foi executada no Windows.

<a id="ci"></a>
## Verificações reproduzíveis

| Camada | Comando/fonte | O que demonstra |
|---|---|---|
| Flutter | `flutter test --no-pub`, `flutter analyze --no-pub` | Contratos, controllers/widgets e análise; não comprova backend real por si só |
| Go | `tools/go-api.ps1 test ./...`, `tools/go-api.ps1 vet ./...` | Unidade, handlers e análise; SQL pode ficar explicitamente skip sem ambiente isolado |
| SQL de atividade | `python tools/verificar_atividade_local.py` | Banco descartável, credenciais reais do runtime local, concorrência e preservação da base entregue |
| CI SQL | `tools/sql_ci.py`, workflowGo | Bancos descartáveis em runner provisionado; não executar como migração da base pessoal |
| Documentação | `python tools/gerar_documentacao.py --write --check` | Inventário/backlog reproduzíveis e links da documentação |
| Diagramas | `python tools/gerar_diagramas.py --check` |15 SVG e draw.io multipágina derivados das fontes |
| Pesquisa arquivada | `python tools/evidencias.py verificar` | Caminhos, tamanhos e hashes dos registros originais, sem rede/extração |
| Python | `python -m unittest discover -s tools -p 'test_*.py'` | Ferramentas/guardas; não substitui aceite de produto |

Resultados funcionais anteriores ficam nos recibos originais. A limpeza documental tem verificação própria; não atualizar um recibo antigo como se seu ensaio tivesse ocorrido novamente.

<a id="matriz"></a>
## Critério de aceite e cenários

Usar a [matriz completa](matriz-cenarios.md), registrando pré-condição, ação, resultado observado, evidência, status e motivo. Incluir públicos/ambientes acordados, dois caminhos de treino, alimentação, foto, histórico, idiomas, acessibilidade, falhas, conta trocada, reenvio e exclusão quando aplicáveis. Uma lacuna permanece visível; não simular vídeo, dado, consumo, prescrição ou sucesso.

Os dados humanos e a refeição de teste existentes são preservados. Testes destrutivos usam fixtures descartáveis ou uma decisão específica do titular. Uma fonte pública, uma tabela, um HTTP200 ou uma prévia visual não constituem prática aprovada.

**Gates restantes:** programa próprio com revisão verificável; seleção/agenda; ciclo real de execução; fotos, composição e histórico/análise; fila offline privada; papel master; acessibilidade e carga; HTTPS/release/OAuth de distribuição; iOS. Critérios e dependências exatos permanecem no [backlog](backlog.json).
