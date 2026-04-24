@echo off
echo ===================================================
echo   RESET PARA APRESENTACAO
echo   (mantem Jenkins + Zabbix)
echo ===================================================
echo.

scp scripts/reset-apresentacao.sh univates@177.44.248.116:/home/univates/reset-apresentacao.sh
ssh univates@177.44.248.116 "chmod +x /home/univates/reset-apresentacao.sh && /home/univates/reset-apresentacao.sh"

echo.
pause
