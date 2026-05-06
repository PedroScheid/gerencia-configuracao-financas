@echo off
echo [LINT] Removendo erro de lint na VM...
ssh univates@177.44.248.116 "sed -i '1d' /home/univates/financas/backend/src/index.ts"
echo [LINT] Erro removido! Rode o build no Jenkins - vai passar.
pause
