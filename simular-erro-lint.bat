@echo off
echo [LINT] Injetando erro de lint na VM...
ssh univates@177.44.248.116 "sed -i '1s/^/const minha_variavel_errada = \"teste\";\n/' /home/univates/financas/backend/src/index.ts"
echo [LINT] Erro injetado! Rode o build no Jenkins - vai falhar no lint.
pause
