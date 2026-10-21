# Guia do projeto

Raiz real: `C:/dev/TrainForge/trainforge`. Projeto Flutter existente; backend Fastify externo em `C:/dev/bootcamp-treinos-api`. Produto Android/iOS, com Android primeiro. Go e nova integração de conteúdo são trabalho planejado, não dependências já instaladas por esta etapa.

Leia [documentação atual](docs/README.md), [diagnóstico](docs/arquitetura/diagnostico-atual.md) e [plano V1](docs/execucao/v1/plano-macro.md). O [guia técnico](documentacao-tecnica.md) aponta contratos, banco e fluxos.

## Acompanhar o trabalho

Abra [arquitetura dinâmica](docs/arquitetura/README.md) e seus mapas de telas, HTTP, banco e progresso. Os arquivos Markdown/Mermaid estão no próprio clone; não é necessário executar servidor para ler.

O painel local foi removido por decisão do autor. A [CI documental](docs/arquitetura/documentacao-dinamica.md) gera/verifica os derivados após mudanças enviadas ao remoto. Manutenção local pelo agente: `python tools/gerar_documentacao.py --write --check`. Isso não inicia app/API/banco.

## Desenvolvimento do app existente

Reutilizar Flutter/Android SDK/ADB/emulador existentes. Conferir `flutter doctor`, dependências e dispositivo antes de instalar qualquer ferramenta. `flutter pub get`, `flutter analyze` e `flutter run` são comandos do app atual, mas esta entrega não os executou nem garante login/backend por executá-los.

O app atual tem base URL fixa `http://127.0.0.1:8081`; o backend usa porta padrão8080. Emulador não aponta para o notebook pelo mesmo loopback: configurar `10.0.2.2` ou adb reverse na história021 e validar. Não distribuir esse debug build à esposa como V1.

Não copiar .env, chave Google privada, tokens ou keystore para o Git. IDs públicos OAuth não são segredos. Não rodar migrations/reset ou subir recursos cloud só por seguir uma proposta antiga.

## Próxima etapa

Executar V1-001 e dependências em [backlog](docs/execucao/v1/backlog.md). O [roteiro de implantação/APK](docs/execucao/v1/implantacao-e-apk.md) explica API/banco/HTTPS, assinatura, arquivo e teste. iOS requer sua etapa real de macOS/Xcode e paridade; não foi validado no Windows.
