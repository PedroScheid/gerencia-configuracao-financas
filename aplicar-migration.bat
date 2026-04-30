@echo off
echo ===================================================
echo   APLICANDO MIGRATION: Tabela de Categorias
echo ===================================================
echo.

echo [1/4] Copiando migration para o projeto...
copy "scripts\migration-categorias.sql" "backend\src\database\migrations\002_create_categorias.sql"

echo.
echo [2/4] Adicionando ao Git...
git add backend\src\database\migrations\002_create_categorias.sql
git commit -m "feat: migration 002 - criar tabela categorias"

echo.
echo [3/4] Enviando para o GitHub...
git push

echo.
echo ===================================================
echo   MIGRATION ADICIONADA E ENVIADA!
echo.
echo   Agora va no Jenkins e clique Build Now.
echo   Depois promova para homologacao e producao.
echo.
echo   Para verificar, acesse no navegador:
echo   http://177.44.248.116:3001/api/categorias (Integracao)
echo   http://177.44.248.116:3002/api/categorias (Homologacao)
echo   http://177.44.248.116:3000/api/categorias (Producao)
echo ===================================================
echo.
pause
