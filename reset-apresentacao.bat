@echo off
setlocal enabledelayedexpansion
echo ===================================================
echo   RESET PARA APRESENTACAO
echo   1) Undo da demo (cor verde + remove migration)
echo   2) Commit/push (leva o GitHub ao estado inicial)
echo   3) Espera o build do undo terminar
echo   4) Limpa a VM -> ao final SO Jenkins e Zabbix UP
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

REM -- 3. Commit + push do undo (leva o GitHub ao estado inicial) -
echo [3/5] Commitando o undo e enviando para o GitHub...
git add -A
git diff --cached --quiet
if %errorlevel%==0 (
    echo       Nenhuma mudanca - GitHub ja esta no estado inicial.
    echo       Pulando commit/push e a espera do build.
    goto RESET_VM
)
git commit -m "reset: estado inicial (layout verde, sem migration 002)"
git push origin main
if %errorlevel% neq 0 (
    echo       ERRO no push. Verifique autenticacao/branch e tente novamente.
    pause
    exit /b 1
)
echo       Push concluido. O Jenkins vai buildar o undo.

REM -- 4. Confirmacao manual antes de limpar a VM --------------
echo.
echo ===================================================
echo   ATENCAO - confirme antes de continuar:
echo.
echo   O push acima disparou um build no Jenkins que vai
echo   subir a integracao (estado inicial: verde, sem migration).
echo.
echo   ESPERE esse build TERMINAR no Jenkins:
echo     http://177.44.248.116:8082
echo.
echo   Quando o build estiver concluido, confirme abaixo para
echo   DERRUBAR a integracao e deixar SO Jenkins + Zabbix up.
echo ===================================================
echo.
:CONFIRMA
set "RESP="
set /p "RESP=O build do undo ja terminou? Pode derrubar a integracao? (S/N): "
if /i "%RESP%"=="S" goto RESET_VM
if /i "%RESP%"=="N" (
    echo       Ok, aguardando... acompanhe o build no Jenkins e responda S quando terminar.
    goto CONFIRMA
)
echo       Responda S ou N.
goto CONFIRMA

:RESET_VM
REM -- 5. Limpa a VM por ULTIMO (garante so Jenkins + Zabbix up) -
echo [5/5] Limpando ambientes na VM (derruba integracao/homolog/prod)...
scp scripts/reset-apresentacao.sh univates@177.44.248.116:/home/univates/reset-apresentacao.sh
ssh univates@177.44.248.116 "chmod +x /home/univates/reset-apresentacao.sh && /home/univates/reset-apresentacao.sh"

echo.
echo === Estado atual na VM (confirme: so jenkins + zabbix) ===
ssh univates@177.44.248.116 "docker ps --format 'table {{.Names}}\t{{.Status}}'"
echo.
echo Se algum 'financas-*' aparecer acima, o build do undo subiu
echo a integracao apos a limpeza. Rode o reset novamente OU execute:
echo   ssh univates@177.44.248.116 "docker rm -f financas-integracao financas-homologacao financas-producao"
echo.
echo ===================================================
echo   RESET CONCLUIDO!
echo   - GitHub: estado inicial (verde, sem migration)
echo   - VM: esperado SO Jenkins e Zabbix UP
echo   - Pronto para rodar o setup-vm e iniciar a demo
echo ===================================================
echo.
pause
