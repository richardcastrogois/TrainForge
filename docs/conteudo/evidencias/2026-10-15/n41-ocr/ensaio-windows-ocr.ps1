param([Parameter(Mandatory=$true)][string]$InputDirectory, [Parameter(Mandatory=$true)][string]$OutputFile)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType=WindowsRuntime]
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType=WindowsRuntime]
function Wait-WinRt($Operation, [Type]$ResultType) {
    $method = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    } | Select-Object -First 1
    $task = $method.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $task.GetAwaiter().GetResult()
}
$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
if ($null -eq $engine) { throw 'No preinstalled OCR language is available.' }
$results = @()
foreach ($inputFile in Get-ChildItem -LiteralPath $InputDirectory -File -Filter '*.png') {
    $file = Wait-WinRt ([Windows.Storage.StorageFile]::GetFileFromPathAsync($inputFile.FullName)) ([Windows.Storage.StorageFile])
    $stream = Wait-WinRt ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
    try {
        $decoder = Wait-WinRt ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
        $bitmap = Wait-WinRt ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
        $converted = [Windows.Graphics.Imaging.SoftwareBitmap]::Convert($bitmap, [Windows.Graphics.Imaging.BitmapPixelFormat]::Bgra8)
        try {
            $watch = [System.Diagnostics.Stopwatch]::StartNew()
            $ocr = Wait-WinRt ($engine.RecognizeAsync($converted)) ([Windows.Media.Ocr.OcrResult])
            $watch.Stop()
            $results += [pscustomobject]@{file=$inputFile.Name; text=$ocr.Text; milliseconds=$watch.ElapsedMilliseconds; lines=@($ocr.Lines | ForEach-Object {$_.Text}); sourceSha256=(Get-FileHash -LiteralPath $inputFile.FullName -Algorithm SHA256).Hash; width=$decoder.PixelWidth; height=$decoder.PixelHeight}
        } finally { $converted.Dispose(); $bitmap.Dispose() }
    } finally { $stream.Dispose() }
}
[pscustomobject]@{date='2026-10-15';engine='Preinstalled Windows.Media.Ocr';language=$engine.RecognizerLanguage.LanguageTag;host='Windows PowerShell 5.1';newPackagesInstalled=$false;fixtures='Own synthetic printed text; no real nutrition label or exercise machine';results=$results;androidMLKitTested=$false;appTested=$false;clinicalValidation=$false} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputFile -Encoding UTF8
