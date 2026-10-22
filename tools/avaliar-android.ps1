param(
 [ValidateSet('start','prepare','status','stop')][string]$Action='start',
 [string]$Serial
)
$ErrorActionPreference='Stop'
$tfRoot=Split-Path -Parent $PSScriptRoot
$tfPython=Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
if(-not(Test-Path -LiteralPath $tfPython)){$tfPython=(Get-Command python -ErrorAction Stop).Source}
$tfArgs=@((Join-Path $PSScriptRoot 'avaliar_android.py'),$Action)
if($Serial){$tfArgs+=@('--serial',$Serial)}
Push-Location $tfRoot
try{& $tfPython @tfArgs;$tfResult=$LASTEXITCODE}finally{Pop-Location}
exit $tfResult
