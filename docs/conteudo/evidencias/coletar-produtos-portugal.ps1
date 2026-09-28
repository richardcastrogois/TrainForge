# N04: cache inclusive de falhas; tres GETs planejados e, apenas com amostra valida,
# um detalhe por codigo observado. Nenhuma credencial, imagem ou escrita externa.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$dayRoot = Join-Path $PSScriptRoot '2026-09-27'
$outRoot = Join-Path $dayRoot 'n04-produtos-portugal'
$rawRoot = Join-Path $dayRoot 'raw'
New-Item -ItemType Directory -Force -Path $outRoot,$rawRoot | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(25)
$client.MaxResponseContentBufferSize = 1048576
$ua = 'TrainForgeResearch/0.6 (+https://github.com/richardcastrogois/TrainForge; N04 research)'
$client.DefaultRequestHeaders.TryAddWithoutValidation('User-Agent',$ua) | Out-Null
$client.DefaultRequestHeaders.TryAddWithoutValidation('Accept','application/json,text/html') | Out-Null
function Get-N04Evidence([string]$id,[string]$url,[string]$extension) {
    $metaPath = Join-Path $outRoot ($id + '.evidencia.json')
    if (Test-Path -LiteralPath $metaPath) {
        Write-Host ($id + ': cached; no repeat')
        return (Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json)
    }
    $record = [ordered]@{
        id=$id; url=$url; method='GET'; collectedAtUtc=[DateTime]::UtcNow.ToString('o')
        requestHeaders=@{ 'User-Agent'=$ua; Accept='application/json,text/html' }
        client='HttpClient; default TLS validation; 25 s timeout; 1 MiB response buffer limit'
        status=$null; use='research_only'
    }
    $response=$null
    try {
        $response=$client.GetAsync($url).GetAwaiter().GetResult()
        $record.status=[int]$response.StatusCode
        $bytes=$response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
        $bodyName=$id + '.' + $extension
        [IO.File]::WriteAllBytes((Join-Path $rawRoot $bodyName),$bytes)
        $record.bytes=$bytes.Length
        $record.bodyFile='../raw/' + $bodyName
        $hasher=[Security.Cryptography.SHA256]::Create()
        try { $record.sha256=([BitConverter]::ToString($hasher.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() }
        finally { $hasher.Dispose() }
        $record.contentType=[string]$response.Content.Headers.ContentType
        $record.retryAfter=[string]$response.Headers.RetryAfter
        if (-not $response.IsSuccessStatusCode) { $record.error='HTTP ' + $record.status + ' ' + $response.ReasonPhrase }
    } catch { $record.error=$_.Exception.GetBaseException().Message }
    finally { if ($null -ne $response) { $response.Dispose() } }
    [IO.File]::WriteAllText($metaPath,($record | ConvertTo-Json -Depth 6) + [Environment]::NewLine,$utf8)
    Write-Host (([pscustomobject]$record | Select-Object id,status,bytes,error) | ConvertTo-Json -Compress)
    return [pscustomobject]$record
}
try {
    $null=Get-N04Evidence 'off-api-guide' 'https://openfoodfacts.github.io/openfoodfacts-server/api/' 'html'
    $null=Get-N04Evidence 'off-license-guide' 'https://openfoodfacts.github.io/openfoodfacts-server/api/tutorials/license-be-on-the-legal-side/' 'html'
    $fields='code,product_name,product_name_pt,brands,countries_tags,lang,quantity,product_quantity,product_quantity_unit,serving_size,serving_quantity,serving_quantity_unit,nutrition_data_per,nutriments,last_modified_t'
    $url='https://world.openfoodfacts.org/api/v2/search?countries_tags=en%3Aportugal&page_size=10&page=1&sort_by=unique_scans_n&fields=' + [Uri]::EscapeDataString($fields)
    $search=Get-N04Evidence 'off-portugal-10' $url 'json'
    if ($search.status -eq 200 -and -not $search.error) {
        $body=Get-Content -LiteralPath (Join-Path $outRoot $search.bodyFile) -Raw | ConvertFrom-Json
        $first=@($body.products | Where-Object { $_.code -match '^([0-9]{8}|[0-9]{12}|[0-9]{13}|[0-9]{14})$' } | Select-Object -First 1)
        if ($first.Count -eq 1) {
            $detailUrl='https://world.openfoodfacts.org/api/v3.6/product/' + $first[0].code + '?fields=' + [Uri]::EscapeDataString($fields)
            $null=Get-N04Evidence 'off-product-observed' $detailUrl 'json'
        }
    }
} finally { $client.Dispose() }
