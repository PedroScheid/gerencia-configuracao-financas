@echo off
chcp 65001 >nul
echo.
echo ===================================================
echo   Setup Remoto da VM - Financas Pessoais
echo ===================================================
echo.
echo Este script vai:
echo   1. Copiar o script de setup para a VM
echo   2. Executar na VM (instala Docker, Terraform, Node;
echo      builda a imagem do Jenkins e sobe tudo via Terraform)
echo.
echo VM: univates@177.44.248.116
echo.
echo Pressione qualquer tecla para iniciar...
pause >nul
echo.
echo [1/2] Copiando script para a VM... (digite a senha)
scp scripts/setup-vm.sh univates@177.44.248.116:/tmp/setup-vm.sh
if %errorlevel% neq 0 (
    echo ERRO: Falha ao copiar o script. Verifique a conexao SSH.
    pause
    exit /b 1
)
echo.
echo [2/2] Executando setup na VM... (digite a senha novamente)
ssh -t univates@177.44.248.116 "chmod +x /tmp/setup-vm.sh && /tmp/setup-vm.sh"
echo.
echo ===================================================
echo   Jenkins: http://177.44.248.116:8082  (admin / admin)
echo   Job 'financas-pipeline' ja configurado - de Build Now.
echo ===================================================
echo.
pause
