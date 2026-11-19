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
| 0.5.1+31 | 19/11/2026 | `f4567de648a04caf` |
