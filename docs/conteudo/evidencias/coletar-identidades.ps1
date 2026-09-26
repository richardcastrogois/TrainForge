# Pesquisa N01: apenas alimentos/grupos Ciqual; sem composicao nutricional.
# Cache inclusive de falhas; TLS padrao, sem credenciais e sem retries.
$ErrorActionPreference = 'Stop'
$researchRoot = Join-Path $PSScriptRoot '2026-09-26/n01-alimentos'
$rawRoot = Join-Path $researchRoot 'raw'
New-Item -ItemType Directory -Force -Path $rawRoot | Out-Null
$targets = @(
    @{ Id = 'ciqual-alimentos'; FileId = '666252'; Md5 = '8e1171d63cee4b6010cfce25dd29243d' },
    @{ Id = 'ciqual-grupos'; FileId = '666250'; Md5 = 'c31aeea90349c3aab86f98ef5f4f10da' }
)
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($target in $targets) {
    $evidencePath = Join-Path $researchRoot ($target.Id + '.evidencia.json')
    if (Test-Path -LiteralPath $evidencePath) {
        $saved = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
        Write-Output ($target.Id + ' cached HTTP ' + $saved.status)
        continue
    }
    $bodyPath = Join-Path $rawRoot ($target.Id + '.xml')
    $record = [ordered]@{
        id = $target.Id
        url = 'https://entrepot.recherche.data.gouv.fr/api/access/datafile/' + $target.FileId
        method = 'GET'
        collectedAtUtc = [DateTime]::UtcNow.ToString('o')
        client = 'Invoke-WebRequest; default TLS certificate validation'
        requestHeaders = @{ 'User-Agent' = 'TrainForgeResearch/0.4 (food identity research)'; Accept = 'application/xml,text/xml' }
        status = $null
        use = 'research_only_not_release_approved'
    }
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $record.url -Headers $record.requestHeaders -OutFile $bodyPath -PassThru -TimeoutSec 30
        $size = (Get-Item -LiteralPath $bodyPath).Length
        if ($size -gt 2097152) { throw 'Response exceeds the expected 2 MiB research bound; do not parse.' }
        $record.status = [int]$response.StatusCode
        $record.bytes = $size
        $record.bodyFile = 'raw/' + $target.Id + '.xml'
        $record.sha256 = (Get-FileHash -LiteralPath $bodyPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $record.md5 = (Get-FileHash -LiteralPath $bodyPath -Algorithm MD5).Hash.ToLowerInvariant()
        $record.metadataMd5 = $target.Md5
        $record.metadataChecksumMatches = $record.md5 -eq $target.Md5
        if (-not $record.metadataChecksumMatches) { throw 'Received bytes do not match the pinned dataset metadata; do not use.' }
    }
    catch {
        $record.error = $_.Exception.Message
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $record.status = [int]$_.Exception.Response.StatusCode
        }
    }
    [IO.File]::WriteAllText($evidencePath, ($record | ConvertTo-Json -Depth 6) + [Environment]::NewLine, $utf8)
    Write-Output (([pscustomobject]$record | Select-Object id,status,bytes,metadataChecksumMatches,error) | ConvertTo-Json -Compress)
}
