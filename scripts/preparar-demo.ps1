# ===================================================================
#  Prepara as alteracoes da DEMO no working tree (sem commitar):
#   1) Erro de ESLint no backend/src/index.ts
#   2) Cor do layout: verde -> azul
#   3) Migration 002 (tabela categorias)
#  Depois e so commitar/pushar pela Source Tree.
# ===================================================================

$ErrorActionPreference = 'Stop'

# Raiz do projeto = pasta-pai deste script (scripts\ -> raiz)
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "==================================================="
Write-Host "  PREPARAR ALTERACOES DA DEMO (local)"
Write-Host "==================================================="
Write-Host ""

# -- 1. Erro de ESLint no backend/src/index.ts ----------------------
Write-Host "[1/3] Injetando erro de ESLint (const minha_variavel)..."
$idx = Join-Path $root 'backend\src\index.ts'
if (-not (Test-Path $idx)) {
    Write-Host "      ERRO: nao encontrei $idx" -ForegroundColor Red
    exit 1
}
$c = Get-Content $idx -Raw
if ($c -notmatch 'const minha_variavel') {
    Set-Content $idx ("const minha_variavel = 'teste';`r`n" + $c) -NoNewline -Encoding UTF8
    Write-Host "      Erro de lint injetado."
} else {
    Write-Host "      Erro de lint ja presente (pulando)."
}

# -- 2. Cor do layout: verde -> azul --------------------------------
Write-Host "[2/3] Alterando cor do layout para azul..."
$css = Join-Path $root 'frontend\src\index.css'
if (-not (Test-Path $css)) {
    Write-Host "      ERRO: nao encontrei $css" -ForegroundColor Red
    exit 1
}
$c = Get-Content $css -Raw
$c = $c -replace '--primary:\s*#[0-9A-Fa-f]{6};', '--primary: #1565c0;'
$c = $c -replace '--primary-dark:\s*#[0-9A-Fa-f]{6};', '--primary-dark: #0d47a1;'
$c = $c -replace '--primary-light:\s*#[0-9A-Fa-f]{6};', '--primary-light: #e3f2fd;'
$c = $c -replace '#16a34a', '#1565c0'
$c = $c -replace '#15803d', '#0d47a1'
$c = $c -replace '#064e3b', '#0a2463'
Set-Content $css $c -NoNewline -Encoding UTF8
Write-Host "      Cor alterada para azul (#1565c0)."

# -- 3. Migration 002 (tabela categorias) ---------------------------
Write-Host "[3/3] Adicionando migration 002 (tabela categorias)..."
$migDir = Join-Path $root 'backend\src\database\migrations'
$mig    = Join-Path $migDir '002_create_categorias.sql'
$src    = Join-Path $root 'scripts\migration-categorias.sql'
if (Test-Path $mig) {
    Write-Host "      Migration 002 ja existe (pulando)."
} elseif (-not (Test-Path $src)) {
    Write-Host "      ERRO: nao encontrei a migration de referencia em $src" -ForegroundColor Red
    exit 1
} else {
    if (-not (Test-Path $migDir)) { New-Item -ItemType Directory -Path $migDir -Force | Out-Null }
    Copy-Item $src $mig -Force
    Write-Host "      Criada: 002_create_categorias.sql"
}

Write-Host ""
Write-Host "==================================================="
Write-Host "  PRONTO! As 3 alteracoes estao no working tree."
Write-Host "  Abra a Source Tree, escreva a mensagem do commit,"
Write-Host "  commite e de push. O Jenkins vai falhar no lint"
Write-Host "  (esperado) -- depois corrija e pushe de novo."
Write-Host "==================================================="
