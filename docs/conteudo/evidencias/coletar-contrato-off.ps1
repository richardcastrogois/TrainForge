# N04: contrato e amostra dirigida. Cache de falhas/sucessos, sem retries.
# O codigo de produto veio da amostra de 27/09; nenhum dado do utilizador enviado.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$dayRoot = Join-Path $PSScriptRoot '2026-09-28'
$outRoot = Join-Path $dayRoot 'n04-contrato-off'
$rawRoot = Join-Path $dayRoot 'raw'
New-Item -ItemType Directory -Force -Path $outRoot,$rawRoot | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(25)
$client.MaxResponseContentBufferSize = 1048576
$ua = 'TrainForgeResearch/0.7 (+https://github.com/richardcastrogois/TrainForge; N04 research)'
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
    $null=Get-N04Evidence 'off-schema-changelog' 'https://openfoodfacts.github.io/openfoodfacts-server/api/ref-api-and-product-schema-change-log/' 'html'
    $fields='code,product_name,brands,countries_tags,nutrition,nutriments,schema_version,quantity,product_quantity,product_quantity_unit,serving_quantity,serving_quantity_unit,no_nutrition_data'
    $url='https://world.openfoodfacts.org/api/v3.6/product/5449000054227?fields=' + [Uri]::EscapeDataString($fields)
    $null=Get-N04Evidence 'off-product-nutrition-v36' $url 'json'
    # Convenience strata chosen before collection: two supermarket labels and two food brands.
    # Queries are hypotheses about source tags; validate returned tags and country before counting.
    $sampleFields='code,product_name,product_name_pt,brands,brands_tags,countries_tags,categories_tags,lang,quantity,product_quantity,product_quantity_unit,serving_size,serving_quantity,serving_quantity_unit,nutrition_data_per,nutriments,last_modified_t'
    foreach ($brand in @('continente','pingo-doce','mimosa','compal')) {
        $sampleUrl='https://world.openfoodfacts.org/api/v2/search?countries_tags=en%3Aportugal&brands_tags=' + $brand + '&page_size=5&page=1&sort_by=unique_scans_n&fields=' + [Uri]::EscapeDataString($sampleFields)
        $null=Get-N04Evidence ('off-brand-' + $brand) $sampleUrl 'json'
    }
    # Explicit synthetic negative fixtures; not real products or measured brand coverage.
    $emptyUrl='https://world.openfoodfacts.org/api/v2/search?countries_tags=en%3Aportugal&brands_tags=trainforge-validation-absent-20260928&page_size=1&fields=code'
    $null=Get-N04Evidence 'off-empty-search-fixture' $emptyUrl 'json'
    $null=Get-N04Evidence 'off-missing-product-fixture' 'https://world.openfoodfacts.org/api/v3.6/product/0000000000000?fields=code,product_name,nutrition' 'json'
    # Synthetic checksum-valid candidate; response decides whether it exists. No assignment asserted.
    $null=Get-N04Evidence 'off-missing-valid-gtin-fixture' 'https://world.openfoodfacts.org/api/v3.6/product/9500000001232?fields=code,product_name,nutrition' 'json'
} finally { $client.Dispose() }
