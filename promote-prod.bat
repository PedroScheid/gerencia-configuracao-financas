@echo off
chcp 65001 >nul
echo.
echo ===================================================
echo   Promovendo para PRODUCAO
echo ===================================================
echo.
ssh -t univates@177.44.248.116 "cd /home/univates/financas && chmod +x scripts/promote-prod.sh && ./scripts/promote-prod.sh"
echo.
echo   Acesse: http://177.44.248.116:3000
echo.
pause
