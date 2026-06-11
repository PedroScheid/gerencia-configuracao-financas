# Guia de Apresentação

## Acessos

| Recurso | URL | Login | Senha |
|---------|-----|-------|-------|
| SSH | `177.44.248.116` | `univates` | `pedro123` |
| Jenkins | `http://177.44.248.116:8082` | `admin` | `admin` |
| Zabbix | `http://177.44.248.116:8080` | `Admin` | `zabbix` |
| Integração | `http://177.44.248.116:3001` | — | — |
| Homologação | `http://177.44.248.116:3002` | — | — |
| Produção | `http://177.44.248.116:3000` | — | — |

## Antes de começar

Estado inicial da apresentação: **nada está rodando na VM** — nem a aplicação, nem Jenkins, nem Zabbix. Tudo será provisionado na hora pelo script de setup.

```bash
ssh univates@177.44.248.116
cd /home/univates/financas && bash scripts/setup-vm.sh
```

> "Vou rodar o script de setup. Ele instala Docker, Terraform, Node e, via Terraform, sobe do zero os containers de CI/CD e monitoramento — Jenkins e Zabbix são criados e configurados nesse momento, não estão pré-instalados."

O script leva alguns minutos (faz build/pull das imagens do Jenkins e do Zabbix e instala Docker CLI + Node dentro do Jenkins). Ao final ele imprime os containers ativos e a senha inicial do Jenkins.

---

## Step 1 — Provisionar a infra (setup)

Rodar `scripts/setup-vm.sh` na VM. Acompanhar a saída: Docker → Terraform → containers Jenkins + Zabbix subindo.

Ao terminar, abrir Jenkins (8082) e Zabbix (8080) → ambos no ar pela primeira vez. As 3 URLs da app (3000/3001/3002) ainda fora do ar.

> "Tudo é Infrastructure as Code. Um comando provisionou toda a esteira de CI/CD e o monitoramento. Nenhum ambiente da aplicação existe ainda."

## Step 2 — Primeiro build (integração)

Jenkins → **Build Now**. ~2 min. Mostrar os stages: install → lint → test → build → docker → deploy.

Acessar `http://177.44.248.116:3001` → app funcionando.

> "O pipeline roda lint, 37 testes e build. Se tudo passa, faz deploy automático na integração."

## Step 3 — Promover homologação

```powershell
.\promote-homolog.bat
```

Acessar `http://177.44.248.116:3002` → app em homologação.

> "Um comando. Pega a imagem aprovada na integração e sobe em homologação."

## Step 4 — Promover produção

```powershell
.\promote-prod.bat
```

Acessar `http://177.44.248.116:3000` → app em produção. Mostrar os 3 ambientes lado a lado.

> "Mesmo processo. Só chega em produção o que passou por integração e homologação."

## Step 5 — Alterações locais + commit único

Agora todas as mudanças são feitas **localmente na minha máquina**, em um único commit. Ao dar push, o Jenkins dispara o build automaticamente.

Na minha máquina, fazer as três alterações no código:

1. **Erro de ESLint** — adicionar uma variável fora do padrão (ex.: `snake_case`) em `backend/src/index.ts`.
2. **Alteração visual** — trocar a cor do front de verde para azul em `frontend/src/index.css`.
3. **Migration do banco** — adicionar `backend/src/database/migrations/002_create_categorias.sql` (cria a tabela `categorias`).

Depois, um único commit + push:

```bash
git add .
git commit -m "feat: migration categorias + ajuste visual"
git push origin main
```

> "Fiz as alterações localmente e dei um único commit. O Jenkins está configurado para disparar o build automaticamente a cada push — não preciso clicar em nada."

### 5a — Quality gate pega o erro de lint

O build dispara sozinho e **falha no stage de lint** por causa da variável fora do padrão.

> "O ESLint exige camelCase. Código fora do padrão é rejeitado — nenhum deploy acontece, mesmo com migration e alteração visual no mesmo commit."

Corrigir o erro de lint localmente, commitar e dar push de novo:

```bash
git add .
git commit -m "fix: corrige nome de variavel (eslint)"
git push origin main
```

### 5b — Build passa e aplica tudo

O novo push dispara outro build. Agora passa no lint, roda os 37 testes, builda e faz deploy na integração.

Acessar `http://177.44.248.116:3001/api/categorias` → tabela nova existe.

Acessar `http://177.44.248.116:3001` → cor mudou (verde → azul).

> "O sistema de migrations verifica quais já rodaram e aplica só as novas. A alteração visual e a migration entraram no mesmo fluxo — tudo passou pelo pipeline antes de chegar no ambiente."

## Step 6 — Propagar para todos os ambientes

```powershell
.\promote-homolog.bat
.\promote-prod.bat
```

Mostrar a cor nova e `/api/categorias` nos 3 ambientes.

> "A mudança propaga: integração → homologação → produção. Cada ambiente é um container isolado com volume de dados próprio."

## Step 7 — Zabbix

Acessar `http://177.44.248.116:8080` → Monitoring → Hosts → Latest data.

> "Zabbix monitora CPU, memória, disco e rede do servidor em tempo real."

## Step 8 — Testes no Jenkins

No último build, clicar em **Test Result** → mostrar os 37 testes passando.

> "37 testes automatizados (Jest + Vitest) com report JUnit integrado ao Jenkins."

---

## Comandos rápidos

```bash
bash scripts/setup-vm.sh        # Provisiona infra do zero (Jenkins + Zabbix via Terraform)
```

```powershell
.\reset-apresentacao.bat        # Reset da app (para reapresentar)
.\promote-homolog.bat           # Integração → Homologação
.\promote-prod.bat              # Homologação → Produção
```

As alterações de demonstração (erro de lint, cor verde→azul, migration 002) são feitas **localmente** e enviadas por commit/push, que dispara o build automático no Jenkins.

## Tecnologias

| Ferramenta | Função |
|------------|--------|
| Docker | Containerização |
| Jenkins | Pipeline CI/CD (build automático a cada push) |
| Terraform | Infraestrutura como código (provisiona Jenkins + Zabbix) |
| Ansible | Provisionamento da VM |
| Zabbix | Monitoramento |
| ESLint | Quality gate |
| Jest/Vitest | Testes automatizados (37) |
