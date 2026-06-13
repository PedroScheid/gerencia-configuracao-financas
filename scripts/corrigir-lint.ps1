# ===================================================================
#  Corrige o erro de ESLint da demo: remove a linha
#  'const minha_variavel = ...' do backend/src/index.ts.
#  Depois e so commitar/pushar -> build OK no Jenkins.
# ===================================================================
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "Corrigindo erro de ESLint (removendo const minha_variavel)..."
$idx = Join-Path $root 'backend\src\index.ts'
if (-not (Test-Path $idx)) {
    Write-Host "      ERRO: nao encontrei $idx" -ForegroundColor Red
    exit 1
}
$lines = Get-Content $idx
$before = $lines.Count
$lines = $lines | Where-Object { $_ -notmatch 'const\s+minha_variavel' }
if ($lines.Count -lt $before) {
    Set-Content $idx ($lines -join "`r`n") -NoNewline -Encoding UTF8
    Write-Host "      Erro de lint removido."
} else {
    Write-Host "      Nenhuma linha 'minha_variavel' encontrada (ja corrigido)."
}
Write-Host ""
Write-Host "Pronto. Commite/pushe pela Source Tree -> o build deve passar."
