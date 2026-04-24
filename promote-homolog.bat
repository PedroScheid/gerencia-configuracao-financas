@echo off
chcp 65001 >nul
echo.
echo ===================================================
echo   Promovendo para HOMOLOGACAO
echo ===================================================
echo.
ssh -t univates@177.44.248.116 "cd /home/univates/financas && chmod +x scripts/promote-homolog.sh && ./scripts/promote-homolog.sh"
echo.
echo   Acesse: http://177.44.248.116:3002
echo.
pause
