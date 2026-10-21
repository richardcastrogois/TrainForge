param([int]$Porta = 8787, [switch]$Parar)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $PSScriptRoot 'painel_projeto.py'
$runtimePath = Join-Path $projectRoot '.project-runtime'
$pidPath = Join-Path $runtimePath "painel-$Porta.json"
$url = "http://127.0.0.1:$Porta"
if ($Porta -lt 1024 -or $Porta -gt 65535) { throw 'Use uma porta entre 1024 e 65535.' }

if ($Parar) {
    if (-not (Test-Path -LiteralPath $pidPath)) { Write-Output 'Nenhum processo registrado por este lançador.'; return }
    $record = Get-Content -LiteralPath $pidPath -Raw | ConvertFrom-Json
    $processInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $($record.processId)"
    if ($processInfo -and $processInfo.CommandLine -like "*$scriptPath*" -and $processInfo.CommandLine -like '*--serve*') {
        Stop-Process -Id $record.processId
        Write-Output 'Painel encerrado. Aplicativo, banco e emulador não são afetados.'
    } elseif ($processInfo) { throw 'PID reutilizado por outro processo; não foi encerrado.' }
    Remove-Item -LiteralPath $pidPath
    return
}

try {
    $health = Invoke-RestMethod -Uri "$url/api/health" -TimeoutSec 2
    if ($health.service -eq 'project-map' -and $health.root -eq $projectRoot.Replace('\','/')) {
        Write-Output "Painel já disponível: $url"
        return
    }
    throw 'A porta responde com outro serviço. Escolha -Porta diferente.'
} catch {
    # Uma porta ocupada por outro serviço não deve iniciar nem encerrar processos alheios.
    $listening = Get-NetTCPConnection -LocalPort $Porta -State Listen -ErrorAction SilentlyContinue
    if ($listening) { throw "Porta $Porta ocupada. Use, por exemplo, -Porta 8788." }
}

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
$pythonPath = if ($pythonCommand -and $pythonCommand.Source -notlike '*WindowsApps*') { $pythonCommand.Source } else { $null }
if (-not $pythonPath) {
    $bundledPython = Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
    if (Test-Path -LiteralPath $bundledPython) { $pythonPath = $bundledPython }
}
if (-not $pythonPath) { throw 'Python não encontrado. Use um Python3 existente; este script não instala dependências.' }
New-Item -Path $runtimePath -ItemType Directory -Force | Out-Null
$arguments = @('"' + $scriptPath + '"', '--serve', '--port', "$Porta")
$processInfo = Start-Process -FilePath $pythonPath -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtimePath 'painel.stdout.log') -RedirectStandardError (Join-Path $runtimePath 'painel.stderr.log')
@{processId=$processInfo.Id; root=$projectRoot; port=$Porta} | ConvertTo-Json | Set-Content -LiteralPath $pidPath -Encoding utf8
for ($attempt=0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Milliseconds 250
    try {
        $health = Invoke-RestMethod -Uri "$url/api/health" -TimeoutSec 1
        if ($health.service -eq 'project-map' -and $health.root -eq $projectRoot.Replace('\','/')) { Write-Output "Painel disponível: $url"; return }
    } catch {}
    if ($processInfo.HasExited) { throw "Falha ao iniciar; consulte $runtimePath/painel.stderr.log" }
}
throw "Sem resposta. Consulte $runtimePath/painel.stderr.log"
