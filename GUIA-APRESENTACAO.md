# Guia de Apresentação — Gerência de Configuração de Software

## Dados de Acesso

| Recurso | URL / Endereço | Usuário | Senha |
|---------|---------------|---------|-------|
| VM (SSH) | `177.44.248.116` | `univates` | `pedro123` |
| Jenkins | `http://177.44.248.116:8082` | `admin` | `admin` |
| Zabbix | `http://177.44.248.116:8080` | `Admin` | `zabbix` |
| GitHub | `github.com/PedroScheid/gerencia-configuracao-financas` | — | — |
| App Integração | `http://177.44.248.116:3001` | — | — |
| App Homologação | `http://177.44.248.116:3002` | — | — |
| App Produção | `http://177.44.248.116:3000` | — | — |

---

## Pré-apresentação (fazer antes de começar)

Garanta que o Jenkins e o Zabbix já estejam rodando e configurados. Se já estiverem, rode apenas o reset para limpar os containers da aplicação:

```powershell
.\reset-apresentacao.bat
```

Isso remove apenas integração, homologação e produção, mas mantém Jenkins e Zabbix intactos.

Se for a primeira vez ou precisar subir tudo do zero, rode:

```powershell
.\setup-vm.bat
```

Depois configure o Jenkins (veja o Passo 3 abaixo).

---

## Passo 1 — Mostrar que não existe nada rodando

Abra no navegador as URLs da aplicação e mostre que estão fora do ar:

- `http://177.44.248.116:3001` (Integração — fora do ar)
- `http://177.44.248.116:3002` (Homologação — fora do ar)
- `http://177.44.248.116:3000` (Produção — fora do ar)

Mostre que o Jenkins e Zabbix estão no ar (infraestrutura pronta):

- `http://177.44.248.116:8082` (Jenkins — funcionando)
- `http://177.44.248.116:8080` (Zabbix — funcionando)

**O que explicar:** "A infraestrutura de CI/CD (Jenkins) e monitoramento (Zabbix) estão no ar, gerenciados pelo Terraform. Ainda não existe nenhum ambiente da aplicação rodando."

---

## Passo 2 — Mostrar a estrutura do projeto

Abra o repositório no GitHub ou no VS Code e mostre rapidamente:

- `Jenkinsfile` — pipeline declarativo (Checkout → Lint → Testes → Build Docker → Deploy)
- `Dockerfile` — build multi-stage (builder + produção)
- `terraform/main.tf` — infraestrutura como código (Jenkins, Zabbix, containers)
- `backend/src/database/migrations/` — sistema de migrations
- `scripts/` — scripts de promoção de ambientes
- `backend/.eslintrc.json` — regras de qualidade de código

**O que explicar:** "Todo o projeto utiliza Infrastructure as Code. O Jenkinsfile define o pipeline CI/CD, o Dockerfile containeriza a aplicação, e o Terraform gerencia todos os containers."

---

## Passo 3 — Pipeline CI/CD (primeiro build)

Se o Jenkins já está configurado (job `financas-pipeline` já existe), pule para o build. Caso contrário:

1. Acesse `http://177.44.248.116:8082`
2. Login: `admin` / `admin`
3. **New Item** → nome: `financas-pipeline` → tipo **Pipeline** → OK
4. Na configuração:
   - Pipeline → **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/PedroScheid/gerencia-configuracao-financas.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
   - **Salvar**

Agora clique em **Build Now** e acompanhe a execução.

**O que explicar durante o build:** "O pipeline executa automaticamente: checkout do código, instalação de dependências, lint em paralelo (backend e frontend), testes automatizados em paralelo (mais de 20 testes), build da imagem Docker, e deploy automático no ambiente de integração."

Quando o build passar (todos os stages verdes), acesse:

- `http://177.44.248.116:3001` → aplicação rodando no ambiente de integração

**O que explicar:** "O ambiente de integração é atualizado automaticamente a cada build bem-sucedido. Nenhuma intervenção manual necessária."

---

## Passo 4 — Promoção para Homologação (1 comando)

No PowerShell, na pasta do projeto:

```powershell
.\promote-homolog.bat
```

Espere a mensagem de sucesso e acesse:

- `http://177.44.248.116:3002` → aplicação rodando em homologação

**O que explicar:** "A promoção para homologação é feita com um único comando. O script pega a imagem Docker aprovada na integração, re-tagueia como homolog, e sobe um container dedicado na porta 3002. É uma promoção controlada — só vai para homologação o que já passou por todos os testes."

---

## Passo 5 — Promoção para Produção (1 comando)

```powershell
.\promote-prod.bat
```

Espere a mensagem de sucesso e acesse:

- `http://177.44.248.116:3000` → aplicação rodando em produção

**O que explicar:** "Da mesma forma, a promoção para produção é um comando. A imagem de homologação vira a imagem de produção. O fluxo garante que só chega em produção o que passou por integração e homologação."

Agora mostre os 3 ambientes lado a lado no navegador:

- `http://177.44.248.116:3001` (Integração)
- `http://177.44.248.116:3002` (Homologação)
- `http://177.44.248.116:3000` (Produção)

**O que explicar:** "Temos 3 ambientes isolados rodando simultaneamente, cada um em seu próprio container Docker com volume de dados separado."

---

## Passo 6 — Alteração no código (ciclo completo)

Faça uma alteração visível no código. Por exemplo, mude a cor do header no arquivo `frontend/src/index.css`:

```css
/* Mudar as variáveis --primary de verde para outra cor, ou vice-versa */
--primary: #1565c0;       /* azul */
--primary-dark: #0d47a1;
--primary-light: #e3f2fd;
```

Commit e push:

```powershell
git add .
git commit -m "feat: alterar cor do header"
git push
```

Vá no Jenkins → **Build Now**. Quando o build passar:

1. Acesse `http://177.44.248.116:3001` → cor nova aparece na integração
2. Rode `.\promote-homolog.bat` → acesse `http://177.44.248.116:3002` → cor nova em homologação
3. Rode `.\promote-prod.bat` → acesse `http://177.44.248.116:3000` → cor nova em produção

**O que explicar:** "Esse é o fluxo completo de CI/CD. Uma mudança no código passa por: commit → pipeline (lint + testes + build) → integração automática → promoção manual para homologação → promoção manual para produção. Em nenhum momento acessamos o servidor manualmente."

---

## Passo 7 — ESLint como Quality Gate

Demonstre que o pipeline rejeita código que não segue o padrão. Abra qualquer arquivo TypeScript (ex: `frontend/src/App.tsx`) e adicione uma variável com nome errado:

```typescript
const minha_variavel_errada = "teste";
```

Commit e push:

```powershell
git add .
git commit -m "test: variavel com nome incorreto"
git push
```

No Jenkins, clique **Build Now**. O pipeline vai **falhar no stage de Lint**.

**O que explicar:** "O ESLint funciona como um quality gate. Código que não segue as convenções de nomenclatura (camelCase) é rejeitado automaticamente. O pipeline para e nenhum deploy acontece. Isso garante a qualidade do código antes de chegar a qualquer ambiente."

Depois, remova a linha, faça commit e push para restaurar:

```powershell
git add .
git commit -m "fix: remover variavel incorreta"
git push
```

Build novamente no Jenkins para confirmar que volta a passar.

---

## Passo 8 — Monitoramento com Zabbix

Acesse `http://177.44.248.116:8080`:

- Login: `Admin` / `zabbix`
- Vá em **Monitoring → Hosts** — mostre o host sendo monitorado
- Vá em **Monitoring → Latest data** — mostre métricas coletadas
- Vá em **Dashboards** — mostre o dashboard padrão

**O que explicar:** "O Zabbix monitora a infraestrutura em tempo real. O agent coleta métricas de CPU, memória, disco e rede do servidor. Em um ambiente real, configuraríamos alertas para notificar a equipe quando algo estiver fora do normal."

---

## Passo 9 — Testes Automatizados

Mostre os resultados de teste no Jenkins:

1. Abra o último build bem-sucedido
2. Clique em **Test Result** — mostra os testes JUnit que passaram
3. Mostre o número de testes (37+)

**O que explicar:** "Temos mais de 20 testes automatizados que rodam em paralelo (backend com Jest, frontend com Vitest). Os resultados são integrados ao Jenkins via JUnit reporter. Se qualquer teste falhar, o pipeline para."

---

## Passo 10 — Infraestrutura como Código (Terraform)

Mostre o arquivo `terraform/main.tf` no VS Code ou GitHub:

- Rede Docker gerenciada pelo Terraform
- Containers do Jenkins, Zabbix (server, web, agent, postgres) declarados como código
- Volumes persistentes para dados
- Variáveis para habilitar/desabilitar ambientes

**O que explicar:** "Toda a infraestrutura é declarada como código no Terraform. Isso significa que podemos recriar o ambiente inteiro a partir do zero com um único comando. Não existe configuração manual — tudo é reproduzível e versionado."

---

## Passo 11 — Docker e Containerização

Mostre o `Dockerfile`:

- **Build multi-stage:** stage `builder` compila TypeScript e React, stage `production` copia apenas os artefatos finais
- Imagem base `node:20-alpine` (leve)
- Health check integrado
- Sistema de migrations copiado para dentro da imagem

Para mostrar os containers rodando, use o terminal:

```powershell
ssh univates@177.44.248.116 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

**O que explicar:** "Cada ambiente roda em seu próprio container Docker isolado. O build multi-stage garante que a imagem final é pequena e contém apenas o necessário para produção. Os dados são persistidos em volumes Docker separados por ambiente."

---

## Resumo das Ferramentas

| Ferramenta | Função no Projeto |
|-----------|-------------------|
| **Docker** | Containerização da aplicação e dos serviços |
| **Jenkins** | Pipeline CI/CD (lint, testes, build, deploy) |
| **Terraform** | Infraestrutura como código (gerencia todos os containers) |
| **Ansible** | Provisionamento da VM (instalação de Docker, Terraform, Node.js) |
| **Zabbix** | Monitoramento da infraestrutura |
| **ESLint** | Quality gate (padrão de código) |
| **Jest/Vitest** | Testes automatizados (37+ testes) |
| **Git/GitHub** | Controle de versão e repositório remoto |

---

## Comandos Rápidos de Referência

```powershell
# Reset para apresentação (mantém Jenkins + Zabbix)
.\reset-apresentacao.bat

# Setup completo do zero (primeira vez)
.\setup-vm.bat

# Promover para homologação
.\promote-homolog.bat

# Promover para produção
.\promote-prod.bat

# Ver containers na VM
ssh univates@177.44.248.116 "docker ps"

# Ver logs de um container
ssh univates@177.44.248.116 "docker logs financas-integracao"
ssh univates@177.44.248.116 "docker logs financas-homologacao"
ssh univates@177.44.248.116 "docker logs financas-producao"
```

---

## Fluxo Resumido da Apresentação

```
1. Mostrar que app não existe (URLs fora do ar)
2. Mostrar estrutura do projeto (GitHub/VS Code)
3. Build no Jenkins → integração sobe automaticamente (porta 3001)
4. promote-homolog.bat → homologação sobe (porta 3002)
5. promote-prod.bat → produção sobe (porta 3000)
6. Alterar código → push → build → promover → mostrar mudança nos 3 ambientes
7. ESLint quality gate → pipeline falha com código ruim
8. Zabbix → monitoramento
9. Testes → resultados no Jenkins
10. Terraform → infraestrutura como código
11. Docker → containerização
```
