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

## Como funciona (resumo)

Jenkins e Zabbix ficam **sempre rodando** na VM (provisionados via Terraform, `restart=unless-stopped`). O pipeline dispara **automaticamente** a cada `push` na branch `main` (polling SCM a cada 1 min) e o checkout clona o código direto do GitHub (`checkout scm`). Cada ambiente é um container Docker isolado com seu próprio banco SQLite em volume.

---

## Passo 0 — Reset (antes de apresentar)

Na sua máquina:

```powershell
.\reset-apresentacao.bat
```

O reset faz, nesta ordem:

1. Reverte a cor do layout para **verde** e remove a **migration 002** localmente.
2. Faz commit + push do undo (leva o GitHub ao estado inicial).
3. **Pergunta se pode derrubar a integração** — acompanhe o build do undo no Jenkins (`:8082`) e responda **S** somente quando ele terminar.
4. Limpa a VM (derruba integração/homolog/prod, remove volumes e a tabela `categoria`).

Ao final, **só Jenkins e Zabbix ficam no ar**. O `docker ps` exibido confirma o estado.

> Se algum `financas-*` ainda aparecer no `docker ps` final, o build do undo subiu a integração depois da limpeza — rode o reset de novo ou o comando indicado na tela.

## Passo 1 — Setup (provisiona a aplicação)

```powershell
.\setup-vm.bat
```

Sincroniza o repositório com o GitHub (estado inicial) e aplica o Terraform da aplicação. Não toca em Jenkins/Zabbix, que já estão rodando.

> "A infra de CI/CD e monitoramento já está no ar via Terraform. O setup prepara a aplicação. Nenhum ambiente da app existe ainda."

## Passo 2 — Primeiro build (integração)

No Jenkins (`:8082`), abra o job **financas-pipeline** → **Build Now** (este primeiro é manual, para estabelecer a baseline do polling).

Stages: checkout → install & quality (lint + 37 testes) → build docker → deploy integração.

Acesse `http://177.44.248.116:3001` → app no ar (layout verde).

> "O pipeline roda lint, 37 testes e build. Passando, faz deploy automático na integração."

## Passo 3 — Promover homologação

```powershell
.\promote-homolog.bat
```

Acesse `http://177.44.248.116:3002`.

> "Um comando promove a imagem aprovada na integração para homologação."

## Passo 4 — Promover produção

```powershell
.\promote-prod.bat
```

Acesse `http://177.44.248.116:3000`. Mostre os 3 ambientes lado a lado.

> "Mesmo processo. Só chega em produção o que passou por integração e homologação."

## Passo 5 — Demo: mudanças + quality gate

Prepare as três alterações da demo de uma vez (na sua máquina):

```powershell
.\preparar-demo.bat
```

Isso deixa no working tree (Source Tree):
- erro de **ESLint** em `backend/src/index.ts`,
- cor do layout **verde → azul**,
- **migration 002** (tabela categorias).

Na **Source Tree**, escreva a mensagem, commite e dê **push**. O Jenkins dispara sozinho (~1 min) e o build **falha no lint**.

> "Fiz as mudanças localmente e um único commit. O Jenkins dispara automático a cada push. Aqui ele rejeita o código: o ESLint exige camelCase — nenhum deploy acontece, mesmo com migration e mudança visual no mesmo commit."

Mostre o erro no console do Jenkins. Depois corrija:

```powershell
.\corrigir-lint.bat
```

Commite e dê **push** de novo. Novo build dispara, **passa** e faz deploy na integração.

Acesse `http://177.44.248.116:3001`:
- cor mudou para **azul**,
- `http://177.44.248.116:3001/api/categorias` → tabela nova existe.

> "O sistema de migrations aplica só as novas. A mudança visual e a migration entraram pelo mesmo fluxo — tudo passou pelo pipeline."

## Passo 6 — Propagar para todos os ambientes

```powershell
.\promote-homolog.bat
.\promote-prod.bat
```

Mostre a cor azul e `/api/categorias` nos 3 ambientes.

> "A mudança propaga: integração → homologação → produção. Cada ambiente é isolado, com volume de dados próprio."

## Passo 7 — Zabbix

`http://177.44.248.116:8080` → Monitoring → Hosts → Latest data.

> "Zabbix monitora CPU, memória, disco e rede do servidor em tempo real."

## Passo 8 — Testes no Jenkins

No último build, **Test Result** → 37 testes passando.

> "37 testes automatizados (Jest + Vitest) com report JUnit integrado ao Jenkins."

---

## Regra de ouro do polling

Cada **Build Now manual consome o commit atual** — depois dele o polling dirá "No changes". Durante a demo, deixe o polling disparar sozinho (commit → push → aguarde ~1 min) e **não** clique em Build Now no meio, exceto no Passo 2 (baseline inicial).

## Comandos rápidos

```powershell
.\reset-apresentacao.bat   # Undo da demo + push + (confirma) limpa VM -> so Jenkins/Zabbix
.\setup-vm.bat             # Provisiona a aplicacao (nao toca Jenkins/Zabbix)
.\preparar-demo.bat        # Injeta erro lint + cor azul + migration (working tree)
.\corrigir-lint.bat        # Remove o erro de lint
.\promote-homolog.bat      # Integracao -> Homologacao
.\promote-prod.bat         # Homologacao -> Producao
```

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
| SQLite | Banco por ambiente (volume isolado) |
