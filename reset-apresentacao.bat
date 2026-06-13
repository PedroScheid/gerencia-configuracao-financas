@echo off
setlocal enabledelayedexpansion
echo ===================================================
echo   RESET PARA APRESENTACAO
echo   Reverte cor (verde) + remove migration 002,
echo   commita/pusha (dispara build no Jenkins) e
echo   limpa os ambientes na VM.
echo ===================================================
echo.

cd /d "%~dp0"

REM -- 1. Restaura a cor verde no layout (index.css) -------------
echo [1/5] Restaurando cor verde no layout...
powershell -NoProfile -Command ^
  "$f='frontend\src\index.css';" ^
  "$c=Get-Content $f -Raw;" ^
  "$c=$c -replace '--primary:\s*#[0-9A-Fa-f]{6};','--primary: #16a34a;';" ^
  "$c=$c -replace '--primary-dark:\s*#[0-9A-Fa-f]{6};','--primary-dark: #15803d;';" ^
  "$c=$c -replace '--primary-light:\s*#[0-9A-Fa-f]{6};','--primary-light: #dcfce7;';" ^
  "Set-Content $f $c -NoNewline;"
echo       Cor restaurada para verde (#16a34a)

REM -- 2. Remove a migration 002 (tabela categorias) ------------
echo [2/5] Removendo migration 002 (se existir)...
set "MIG=backend\src\database\migrations\002_create_categorias.sql"
if exist "%MIG%" (
    del /f /q "%MIG%"
    echo       Removida: 002_create_categorias.sql
) else (
    echo       Ja nao existe
)

REM -- 3. Verifica se ha mudancas para commitar -----------------
echo [3/5] Verificando mudancas...
git add -A
git diff --cached --quiet
if %errorlevel%==0 (
    echo       Nenhuma mudanca - repositorio ja esta no estado inicial.
    echo       Pulando commit/push.
    goto RESET_VM
)

REM -- 4. Commit + push (dispara o build no Jenkins) ------------
echo [4/5] Commitando e enviando para o GitHub...
git commit -m "reset: estado inicial (layout verde, sem migration 002)"
git push origin main
if %errorlevel% neq 0 (
    echo       ERRO no push. Verifique autenticacao/branch e tente novamente.
    pause
    exit /b 1
)
echo       Commit/push concluido - o Jenkins vai disparar o build em ~1 min.

:RESET_VM
REM -- 5. Limpa os ambientes na VM (containers/volumes/etc) -----
echo [5/5] Limpando ambientes na VM...
scp scripts/reset-apresentacao.sh univates@177.44.248.116:/home/univates/reset-apresentacao.sh
ssh univates@177.44.248.116 "chmod +x /home/univates/reset-apresentacao.sh && /home/univates/reset-apresentacao.sh"

echo.
echo ===================================================
echo   RESET CONCLUIDO!
echo   - Layout: verde   - Migration 002: removida
echo   - Build disparado no Jenkins (aguarde ~1 min)
echo   - Ambientes da VM limpos
echo ===================================================
echo.
pause
