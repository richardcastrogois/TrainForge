# N03: tres leituras publicas pontuais; cache de sucesso/falha, sem retry.
$ErrorActionPreference = 'Stop'
$dayRoot = Join-Path $PSScriptRoot '2026-09-27'
$evidenceRoot = Join-Path $dayRoot 'n03-porcoes'
$rawRoot = Join-Path $dayRoot 'raw'
New-Item -ItemType Directory -Force -Path $evidenceRoot,$rawRoot | Out-Null
$targets = @(
    @{ Id='usda-rice-drink'; Ext='json'; Url='https://api.nal.usda.gov/fdc/v1/food/171942?api_key=DEMO_KEY' },
    @{ Id='cofid-guide'; Ext='pdf'; Url='https://assets.publishing.service.gov.uk/media/60538e66d3bf7f03249bac58/McCance_and_Widdowsons_Composition_of_Foods_integrated_dataset_2021.pdf' },
    @{ Id='usda-foundation-guide'; Ext='html'; Url='https://fdc.nal.usda.gov/Foundation_Foods_Documentation/' }
)
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($target in $targets) {
    $metadataPath = Join-Path $evidenceRoot ($target.Id + '.evidencia.json')
    if (Test-Path -LiteralPath $metadataPath) {
        Write-Output ($target.Id + ' cached; do not retry automatically')
        continue
    }
    $bodyPath = Join-Path $rawRoot ($target.Id + '.' + $target.Ext)
    $record = [ordered]@{
        id=$target.Id; url=$target.Url; method='GET'
        collectedAtUtc=[DateTime]::UtcNow.ToString('o')
        requestHeaders=@{ 'User-Agent'='TrainForgeResearch/0.5 (portion research)'; Accept='application/json,application/pdf,text/html' }
        client='Invoke-WebRequest; default TLS verification'
        status=$null; use='research_only'
    }
    try {
        $response=Invoke-WebRequest -UseBasicParsing -Uri $target.Url -Headers $record.requestHeaders -OutFile $bodyPath -PassThru -TimeoutSec 30
        $record.status=[int]$response.StatusCode
        $record.bytes=(Get-Item -LiteralPath $bodyPath).Length
        $record.bodyFile='../raw/' + $target.Id + '.' + $target.Ext
        $record.sha256=(Get-FileHash -LiteralPath $bodyPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($record.bytes -gt 2097152) { throw 'Unexpected response larger than 2 MiB; do not parse.' }
    } catch {
        $record.error=$_.Exception.Message
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) { $record.status=[int]$_.Exception.Response.StatusCode }
    }
    [IO.File]::WriteAllText($metadataPath,($record | ConvertTo-Json -Depth 6) + [Environment]::NewLine,$utf8)
    Write-Output (([pscustomobject]$record | Select-Object id,status,bytes,error) | ConvertTo-Json -Compress)
}
