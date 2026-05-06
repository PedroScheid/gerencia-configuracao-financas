# Tecnologias do Projeto — Como Apresentar Cada Uma

---

## Jenkins — Integração e Entrega Contínua

**O que é:** Servidor de automação que orquestra todo o pipeline CI/CD. Cada push no código dispara automaticamente: lint, testes, build e deploy.

**Como mostrar:**

1. Abra `http://177.44.248.116:8082` (login: `admin` / `admin`)
2. Clique no pipeline `financas-pipeline`
3. Abra o último build e mostre a visualização dos stages:
   - `Checkout` → `Lint (paralelo)` → `Testes (paralelo)` → `Build Docker` → `Deploy Integração`
4. Clique em **Test Result** para mostrar os 37+ testes que passaram

**O que dizer:**

> "O Jenkins é o coração do nosso CI/CD. Cada push no GitHub dispara automaticamente o pipeline. Ele executa lint em paralelo no backend e frontend, roda mais de 20 testes automatizados, builda a imagem Docker e faz deploy automático no ambiente de integração. Se qualquer etapa falhar, o pipeline para e nenhum deploy acontece."

**Arquivo para mostrar no VS Code:** `Jenkinsfile`

---

## Docker — Containerização

**O que é:** Plataforma de containers que empacota a aplicação com todas as dependências, garantindo que roda igual em qualquer ambiente.

**Como mostrar:**

1. Mostre o `Dockerfile` no VS Code — destaque o multi-stage build:
   - Stage `builder`: compila TypeScript e React
   - Stage `production`: copia só os artefatos finais (imagem leve)
2. No terminal, liste os containers rodando:

```powershell
ssh univates@177.44.248.116 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

3. Mostre que cada ambiente tem seu próprio volume de dados:

```powershell
ssh univates@177.44.248.116 "docker volume ls"
```

**O que dizer:**

> "O Docker containeriza a aplicação. Usamos multi-stage build: o primeiro stage compila o TypeScript e o React, e o segundo copia apenas os artefatos finais para uma imagem Alpine leve. Cada ambiente — integração, homologação e produção — roda em seu próprio container isolado com volume de dados separado. Isso garante que os ambientes são independentes."

**Arquivo para mostrar no VS Code:** `Dockerfile`

---

## Terraform — Infraestrutura como Código

**O que é:** Ferramenta de IaC (Infrastructure as Code) que declara toda a infraestrutura em arquivos de configuração. Com um único comando, cria ou destrói todos os recursos.

**Como mostrar:**

1. Mostre o `terraform/main.tf` no VS Code — destaque:
   - Rede Docker (`financas-network`)
   - Container do Jenkins com volumes e portas
   - Stack completo do Zabbix (server, web, agent, postgres)
   - Variáveis para habilitar/desabilitar ambientes
2. No terminal, mostre os recursos gerenciados:

```powershell
ssh univates@177.44.248.116 "cd /home/univates/financas/terraform && terraform show"
```

3. Mostre também as variáveis (`terraform/variables.tf`) e outputs (`terraform/outputs.tf`)

**O que dizer:**

> "O Terraform gerencia toda a infraestrutura como código. Todos os containers, redes e volumes estão declarados no main.tf. Com um único 'terraform apply', criamos Jenkins, Zabbix completo com PostgreSQL, e toda a rede. Se precisar recriar do zero, basta rodar o comando novamente. Tudo é reproduzível e versionado no Git."

**Arquivo para mostrar no VS Code:** `terraform/main.tf`

---

## Ansible — Provisionamento da VM

**O que é:** Ferramenta de automação que provisiona a VM do zero — instala Docker, Terraform, Node.js, Git e configura o firewall. O playbook é idempotente (pode rodar várias vezes sem efeitos colaterais).

**Como mostrar:**

1. Mostre o `ansible/playbook.yml` no VS Code — destaque as tasks:
   - Instalar Docker
   - Instalar Terraform
   - Instalar Node.js 20
   - Configurar firewall (UFW)
2. Para demonstrar a idempotência, rode no terminal:

```powershell
ssh univates@177.44.248.116 "cd /home/univates/financas/ansible && sudo ansible-playbook playbook.yml -i inventory.ini --connection=local"
```

Todas as tasks devem retornar "ok" (já instalado), provando que é idempotente.

**O que dizer:**

> "O Ansible provisiona a VM do zero. O playbook instala Docker, Terraform, Node.js e configura o firewall com todas as portas necessárias. Ele é idempotente — se rodarmos novamente, ele verifica o que já está instalado e pula, sem causar problemas. Isso garante que a VM pode ser recriada a qualquer momento."

**Arquivo para mostrar no VS Code:** `ansible/playbook.yml`

---

## Zabbix — Monitoramento

**O que é:** Plataforma de monitoramento que coleta métricas em tempo real da infraestrutura (CPU, memória, disco, rede) e pode disparar alertas quando algo sai do normal.

**Como mostrar:**

1. Acesse `http://177.44.248.116:8080` (login: `Admin` / `zabbix`)
2. **Dashboard (Global View):**
   - Host Availability: host verde = agent conectado e coletando dados
   - Top hosts by CPU: mostra utilização atual da VM
   - System Information: versão do Zabbix, número de items monitorados
3. **Monitoring → Hosts:** mostre o host `Zabbix server` com status verde
4. **Monitoring → Latest data:** mostre as métricas coletadas em tempo real:
   - CPU utilization
   - Memory usage
   - Disk space
   - Network interfaces
5. **Data collection → Hosts → Zabbix server:** mostre os templates aplicados:
   - `Linux by Zabbix agent` (métricas do SO)
   - `Zabbix server health` (saúde do próprio Zabbix)

**O que dizer:**

> "O Zabbix monitora toda a infraestrutura em tempo real. O agent roda em um container dedicado e coleta métricas de CPU, memória, disco e rede do servidor. No dashboard vemos o status de todos os hosts, problemas ativos e gráficos de utilização. Em um ambiente real, configuraríamos alertas por e-mail ou Telegram para notificar a equipe quando algo estiver fora do normal."
