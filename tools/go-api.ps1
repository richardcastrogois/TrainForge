param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GoArgs)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskGo = Join-Path $taskRoot '.tools/go/bin/go.exe'
if (-not (Test-Path -LiteralPath $taskGo)) { $taskGo = (Get-Command go -ErrorAction Stop).Source }
$env:PATH = (Split-Path -Parent $taskGo) + ';' + (Join-Path $taskRoot '.tools/bin') + ';' + $env:PATH
$env:GOCACHE = Join-Path $taskRoot '.tools/gocache'
$env:GOMODCACHE = Join-Path $taskRoot '.tools/gomodcache'
$env:GOTOOLCHAIN = 'local'
Push-Location (Join-Path $taskRoot 'services/api')
try { & $taskGo @GoArgs; $taskExitCode = $LASTEXITCODE } finally { Pop-Location }
exit $taskExitCode
