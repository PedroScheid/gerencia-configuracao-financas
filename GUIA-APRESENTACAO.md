# Guia de Apresentação

## Acessos

| Recurso | URL | Login | Senha |
|---------|-----|-------|-------|
| SSH | `177.44.248.116` | `univates` | `pedro123` |
| Jenkins | `http://177.44.248.116:8082` | `admin` | `admin` |
| Integração | `http://177.44.248.116:3001` | — | — |
| Homologação | `http://177.44.248.116:3002` | — | — |
| Produção | `http://177.44.248.116:3000` | — | — |

## Como funciona (resumo)

Tudo é Infrastructure as Code. O `setup-vm.sh` provisiona a VM do zero: instala Docker/Terraform/Node, e o Terraform sobe a rede, o **Jenkins já configurado** (imagem pré-buildada com JCasC: admin/admin + job `financas-pipeline` com polling) e os volumes. O pipeline dispara **automaticamente** a cada `push` na `main` (polling SCM ~1 min) e clona o código do GitHub (`checkout scm`). Cada ambiente é um container Docker isolado com seu próprio banco SQLite em volume.

---

## Passo 1 — Mostrar que não existe nada rodando

Faça o reset (na sua máquina) **antes** de apresentar:

```powershell
.\reset-apresentacao.bat
```

Ele reverte a cor para verde e remove a migration localmente, dá commit/push (GitHub no estado inicial) e **limpa a VM por completo** (Docker vazio).

Na apresentação, mostre ao professor que está tudo desligado:

```bash
ssh univates@177.44.248.116 "docker ps -a"
```

> "Não há nada rodando — nem containers, nem imagens da aplicação. Vou provisionar tudo do zero."

Abra as 3 URLs da app (`:3000`, `:3001`, `:3002`) → todas fora do ar.

## Passo 2 — Subir o ambiente (setup)

```powershell
.\setup-vm.bat
```

O setup instala as dependências e, via Terraform, sobe a rede e o **Jenkins já configurado**. A imagem do Jenkins é pré-buildada (fica em cache), então sobe rápido.

> "Um comando provisiona toda a esteira: Docker, Terraform e o Jenkins já configurado por código — usuário, repositório, branch e polling. Tudo Infrastructure as Code."

Acesse o Jenkins (`:8082`), login **admin / admin** → o job **financas-pipeline** já está lá.

## Passo 3 — Primeiro build (integração)

No Jenkins → **financas-pipeline** → **Build Now**.

Stages: checkout → install & quality (lint + 37 testes) → build docker → deploy integração.

Acesse `http://177.44.248.116:3001` → app no ar (layout verde).

> "O pipeline roda lint, 37 testes e build. Passando, faz deploy automático na integração."

## Passo 4 — Promover homologação e produção

```powershell
.\promote-homolog.bat
.\promote-prod.bat
```

Acesse `:3002` e `:3000`. Mostre os 3 ambientes lado a lado.

> "Só chega em produção o que passou por integração e homologação."

## Passo 5 — Demo: mudança de layout + quebra de padrão + nova tabela

Prepare as três alterações de uma vez (na sua máquina):

```powershell
.\preparar-demo.bat
```

Deixa no working tree (Source Tree):
- cor do layout **verde → azul**,
- erro de **ESLint** em `backend/src/index.ts` (quebra o padrão de código),
- **migration 002** (cria a tabela `categorias`).

Na **Source Tree**, escreva a mensagem, commite e dê **push**. O Jenkins dispara sozinho (~1 min) e o build **falha no lint**.

> "Fiz as mudanças localmente num único commit. O Jenkins dispara automático a cada push. Aqui ele rejeita: o ESLint exige camelCase — nenhum deploy acontece, mesmo com a migration e a mudança visual no mesmo commit."

Mostre o erro no console do Jenkins. Depois corrija:

```powershell
.\corrigir-lint.bat
```

Commite e dê **push** de novo. O novo build **passa** e faz deploy na integração.

Acesse `http://177.44.248.116:3001`:
- cor mudou para **azul**,
- `http://177.44.248.116:3001/api/categorias` → tabela nova responde.

## Passo 6 — Propagar e consultar a tabela em homolog e prod

```powershell
.\promote-homolog.bat
.\promote-prod.bat
```

Consulte a tabela em cada ambiente (endpoint ou navegador):

```
http://177.44.248.116:3002/api/categorias   (homologação)
http://177.44.248.116:3000/api/categorias   (produção)
```

E veja a cor azul nos três. 

> "A mudança propaga: integração → homologação → produção. Cada ambiente é isolado, com seu próprio banco SQLite em volume."

---

## Regra de ouro do polling

Cada **Build Now manual consome o commit atual** — depois dele o polling dirá "No changes". Durante a demo, deixe o polling disparar sozinho (commit → push → aguarde ~1 min) e **não** clique em Build Now no meio, exceto no Passo 3 (baseline inicial).

## Comandos rápidos

```powershell
.\reset-apresentacao.bat   # Undo da demo + push + limpa a VM (Docker vazio)
.\setup-vm.bat             # Provisiona tudo do zero (rede + Jenkins + app)
.\preparar-demo.bat        # Cor azul + erro de lint + migration (working tree)
.\corrigir-lint.bat        # Remove o erro de lint
.\promote-homolog.bat      # Integracao -> Homologacao
.\promote-prod.bat         # Homologacao -> Producao
```

## Tecnologias

| Ferramenta | Função |
|------------|--------|
| Docker | Containerização |
| Jenkins | Pipeline CI/CD (build automático a cada push) |
| Terraform | Infraestrutura como código (rede + Jenkins + app) |
| Ansible | Provisionamento da VM |
| ESLint | Quality gate (padrão de código) |
| Jest/Vitest | Testes automatizados (37) |
| SQLite | Banco por ambiente (volume isolado) |
