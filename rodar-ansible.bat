@echo off
chcp 65001 >nul
echo.
echo ===================================================
echo   ANSIBLE - Provisionamento da VM (IaC)
echo ===================================================
echo.
echo Roda o playbook na VM (instala/garante Docker,
echo Terraform, Node, Git e firewall).
echo.
echo DICA: rode este .bat DUAS vezes seguidas. Na 2a vez
echo o resumo deve mostrar "changed=0" -- prova de que o
echo playbook e idempotente (so aplica o que falta).
echo.
echo VM: univates@177.44.248.116
echo Pressione qualquer tecla para iniciar...
pause >nul
echo.

ssh -t univates@177.44.248.116 "cd /home/univates/financas/ansible && sudo ansible-playbook playbook.yml -i inventory.ini"

echo.
echo ===================================================
echo   FIM. Veja o PLAY RECAP acima:
echo     - ok      = tarefas no estado desejado
echo     - changed = tarefas que o Ansible alterou
echo     - failed  = falhas (deve ser 0)
echo.
echo   Na 2a execucao, changed=0 demonstra idempotencia.
echo ===================================================
echo.
pause
