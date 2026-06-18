@echo off
setlocal enabledelayedexpansion
echo ===================================================
echo   RESET PARA APRESENTACAO
echo   1) Undo da demo (cor verde + remove migration) no local
echo   2) Commit/push (leva o GitHub ao estado inicial)
echo   3) Limpa a VM por completo (docker fica vazio)
echo ===================================================
echo.

cd /d "%~dp0"

REM -- 1. Restaura a cor verde no layout (index.css) -------------
echo [1/4] Restaurando cor verde no layout...
powershell -NoProfile -Command ^
  "$f='frontend\src\index.css';" ^
  "$c=Get-Content $f -Raw;" ^
  "$c=$c -replace '--primary:\s*#[0-9A-Fa-f]{6};','--primary: #16a34a;';" ^
  "$c=$c -replace '--primary-dark:\s*#[0-9A-Fa-f]{6};','--primary-dark: #15803d;';" ^
  "$c=$c -replace '--primary-light:\s*#[0-9A-Fa-f]{6};','--primary-light: #dcfce7;';" ^
  "Set-Content $f $c -NoNewline;"
echo       Cor restaurada para verde (#16a34a)

REM -- 2. Remove a migration 002 (tabela categorias) ------------
echo [2/4] Removendo migration 002 (se existir)...
set "MIG=backend\src\database\migrations\002_create_categorias.sql"
if exist "%MIG%" (
    del /f /q "%MIG%"
    echo       Removida: 002_create_categorias.sql
) else (
    echo       Ja nao existe
)

REM -- 3. Commit + push do undo (leva o GitHub ao estado inicial) -
echo [3/4] Commitando o undo e enviando para o GitHub...
git add -A
git diff --cached --quiet
if %errorlevel%==0 (
    echo       Nenhuma mudanca - GitHub ja esta no estado inicial.
) else (
    git commit -m "reset: estado inicial (layout verde, sem migration 002)"
    git push origin main
    if %errorlevel% neq 0 (
        echo       ERRO no push. Verifique autenticacao/branch e tente novamente.
        pause
        exit /b 1
    )
    echo       Push concluido - GitHub no estado inicial.
)

REM -- 4. Limpa a VM por completo ------------------------------
echo [4/4] Limpando a VM (remove TUDO do Docker)...
scp scripts/reset-apresentacao.sh univates@177.44.248.116:/home/univates/reset-apresentacao.sh
ssh univates@177.44.248.116 "chmod +x /home/univates/reset-apresentacao.sh && /home/univates/reset-apresentacao.sh"

echo.
echo ===================================================
echo   RESET CONCLUIDO!
echo   - GitHub: estado inicial (verde, sem migration)
echo   - VM: Docker vazio (nada rodando)
echo   - Proximo: rodar o setup-vm para subir tudo
echo ===================================================
echo.
echo OBS: a imagem financas-jenkins:latest foi preservada na VM
echo para o setup subir o Jenkins rapido (sem rebuild de ~9 min).
echo Para zerar 100%% (rebuild do Jenkins no proximo setup), rode:
echo   ssh univates@177.44.248.116 "/home/univates/reset-apresentacao.sh --full"
echo.
pause
