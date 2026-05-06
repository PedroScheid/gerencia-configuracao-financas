@echo off
echo [MIGRATION] Enviando e aplicando migration 002 na VM...
scp scripts/migration-categorias.sql univates@177.44.248.116:/home/univates/financas/backend/src/database/migrations/002_create_categorias.sql
echo [MIGRATION] Migration 002 adicionada! Rode o build no Jenkins.
echo.
echo Depois do build, verifique: http://177.44.248.116:3001/api/categorias
pause
