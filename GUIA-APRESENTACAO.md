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

```powershell
.\reset-apresentacao.bat
```

Limpa os containers da app, mantém Jenkins + Zabbix.

---

## Step 1 — Nenhum ambiente existe

Abrir as 3 URLs da app → todas fora do ar. Jenkins (8082) e Zabbix (8080) estão no ar.

> "A infra de CI/CD e monitoramento já está rodando via Terraform. Nenhum ambiente da aplicação existe ainda."

## Step 2 — Mostrar o projeto

Abrir no GitHub ou VS Code e mostrar rapidamente: `Jenkinsfile`, `Dockerfile`, `terraform/main.tf`, `backend/src/database/migrations/`.

> "Tudo é Infrastructure as Code — pipeline, containers, infra."

## Step 3 — Primeiro build (integração)

Jenkins → **Build Now**. ~2 min. Mostrar os stages: install → lint → test → build → docker → deploy.

Acessar `http://177.44.248.116:3001` → app funcionando.

> "O pipeline roda lint, 37 testes e build. Se tudo passa, faz deploy automático na integração."

## Step 4 — Promover homologação

```powershell
.\promote-homolog.bat
```

Acessar `http://177.44.248.116:3002` → app em homologação.

> "Um comando. Pega a imagem aprovada na integração e sobe em homologação."

## Step 5 — Promover produção

```powershell
.\promote-prod.bat
```

Acessar `http://177.44.248.116:3000` → app em produção. Mostrar os 3 ambientes lado a lado.

> "Mesmo processo. Só chega em produção o que passou por integração e homologação."

## Step 6 — Quality gate (ESLint falha)

```powershell
.\simular-erro-lint.bat
```

Jenkins → **Build Now** → pipeline **falha no lint**.

> "O ESLint exige camelCase. Código fora do padrão é rejeitado — nenhum deploy acontece."

```powershell
.\corrigir-erro-lint.bat
```

## Step 7 — Migration do banco + alteração visual

```powershell
.\aplicar-migration.bat
.\alterar-cor.bat
```

Jenkins → **Build Now** → sucesso.

Acessar `http://177.44.248.116:3001/api/categorias` → tabela nova existe.

Acessar `http://177.44.248.116:3001` → cor mudou (verde → azul).

> "Adicionamos uma migration 002 que cria a tabela categorias. O sistema de migrations verifica quais já rodaram e aplica só as novas. Também alteramos o layout — tudo passou pelo pipeline."

## Step 8 — Propagar para todos os ambientes

```powershell
.\promote-homolog.bat
.\promote-prod.bat
```

Mostrar a cor nova e `/api/categorias` nos 3 ambientes.

> "A mudança propaga: integração → homologação → produção. Cada ambiente é um container isolado com volume de dados próprio."

## Step 9 — Zabbix

Acessar `http://177.44.248.116:8080` → Monitoring → Hosts → Latest data.

> "Zabbix monitora CPU, memória, disco e rede do servidor em tempo real."

## Step 10 — Testes no Jenkins

No último build, clicar em **Test Result** → mostrar os 37 testes passando.

> "37 testes automatizados (Jest + Vitest) com report JUnit integrado ao Jenkins."

---

## Comandos rápidos

```powershell
.\reset-apresentacao.bat       # Reset (mantém Jenkins/Zabbix)
.\simular-erro-lint.bat        # Injeta erro de lint
.\corrigir-erro-lint.bat       # Remove erro de lint
.\aplicar-migration.bat        # Adiciona migration 002
.\alterar-cor.bat              # Muda cor verde → azul
.\promote-homolog.bat          # Integração → Homologação
.\promote-prod.bat             # Homologação → Produção
```

## Tecnologias

| Ferramenta | Função |
|------------|--------|
| Docker | Containerização |
| Jenkins | Pipeline CI/CD |
| Terraform | Infraestrutura como código |
| Ansible | Provisionamento da VM |
| Zabbix | Monitoramento |
| ESLint | Quality gate |
| Jest/Vitest | Testes automatizados (37) |
