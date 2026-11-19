# Distribuição do APK

**Link fixo para baixar:** https://github.com/richardcastrogois/TrainForge/releases/latest/download/TrainForge.apk

![QR code para baixar o TrainForge](qrcode-baixar-trainforge.png)

O QR code ([PNG](qrcode-baixar-trainforge.png) · [SVG](qrcode-baixar-trainforge.svg)) aponta sempre para a **versão mais recente**: cada release publica o arquivo com o mesmo nome `TrainForge.apk`, então o link e o QR **não mudam** entre versões.

## Publicar uma nova versão (3 comandos)

1. Subir a versão em `pubspec.yaml` (ex.: `0.5.2+32`) e em `legalAppVersion` (`lib/features/legal/legal_documents.dart`); o teste `legal_consent_test.dart` confere os dois.
2. Gerar e verificar o APK release (assinatura, catálogo e políticas):

   ```powershell
   python tools/preparar_release_android.py --config .local/android-release/release-config.json --certificate-sha256 BFA91D8792CE53124A777B15BF4650C40AB72592366362B6A5581F211C208878
   ```

3. Publicar no GitHub Releases (sem `--confirm-publish` só confere):

   ```powershell
   python tools/publicar_release_android.py --confirm-publish --notes "O que mudou"
   ```

O app já instalado não se atualiza sozinho: a pessoa baixa pelo mesmo link e instala por cima (mesma assinatura, dados preservados). Atualização automática fica para a publicação na Play Store.

## Versões publicadas

| Versão | Data | SHA-256 (início) |
|---|---|---|
| 0.5.4+34 | 19/11/2026 | `7d0ad4e3e8ea04c0` — plugins nativos restaurados; login Google confirmado no celular; catálogo offline corrigido; download público conferido |
| 0.5.3+33 | 19/11/2026 | `d3aa1962d5f6d7ea` — busca/detalhes usam servidor se o catálogo local falhar; login Google bloqueado pela ausência do registrador de plugins |
| 0.5.2+32 | 19/11/2026 | `88f6825c51ccad9a` — termos só após login; sem tela vazia |
| 0.5.1+31 | 19/11/2026 | `f4567de648a04caf` | — termos antes da entrada travavam (substituída) |

O preparo do release gera os arquivos nativos com `flutter build apk --release --config-only` antes de medir as fontes e compilar. O APK final só recebe recibo se definir a classe `io.flutter.plugins.GeneratedPluginRegistrant` no DEX. Apagar o registrador e compilar diretamente com `--no-pub` produziu a falha nativa da 0.5.3; testes Flutter isolados não detectam esse problema de empacotamento.
