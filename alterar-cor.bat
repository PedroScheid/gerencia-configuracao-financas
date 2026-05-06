@echo off
echo [LAYOUT] Alterando cor do layout para azul na VM...
ssh univates@177.44.248.116 "sed -i 's/--primary: #16a34a/--primary: #1565c0/g; s/--primary-dark: #15803d/--primary-dark: #0d47a1/g; s/--primary-light: #dcfce7/--primary-light: #e3f2fd/g' /home/univates/financas/frontend/src/index.css"
ssh univates@177.44.248.116 "sed -i 's/#16a34a/#1565c0/g; s/#15803d/#0d47a1/g; s/#064e3b/#0a2463/g' /home/univates/financas/frontend/src/index.css"
echo [LAYOUT] Cor alterada de verde para azul! Rode o build no Jenkins.
pause
