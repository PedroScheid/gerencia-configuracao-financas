# FinançasPessoais — Gerência de Receitas e Despesas

Aplicação full-stack em **React + TypeScript** (frontend) e **Node.js + TypeScript + Express** (backend) com banco de dados **SQLite**.

---

## Índice

1. [Sobre a Aplicação](#1-sobre-a-aplicação)
2. [Arquitetura e Classes](#2-arquitetura-e-classes)
3. [Modelagem do Banco de Dados](#3-modelagem-do-banco-de-dados)
4. [Rodando Localmente](#4-rodando-localmente)
5. [Publicação na VM](#5-publicação-na-vm)
6. [Acesso à Aplicação](#6-acesso-à-aplicação)
7. [Tempos Gastos](#7-tempos-gastos)

---

## 1. Sobre a Aplicação

Sistema de registro de **despesas e receitas pessoais** com:

- Login com autenticação JWT
- Listagem de lançamentos com resumo financeiro (total receitas, despesas e saldo)
- Cadastro, edição e exclusão de lançamentos
- Filtros por tipo e situação
- Interface responsiva

---

## 2. Arquitetura e Classes

### Estrutura de pastas

```
gerencia-configuracao-financas/
├── backend/
│   └── src/
│       ├── database/db.ts          # Inicialização e seed do SQLite
│       ├── middleware/auth.ts      # Middleware JWT
│       ├── routes/auth.ts          # Rotas de autenticação
│       ├── routes/lancamentos.ts   # CRUD de lançamentos
│       └── index.ts               # Entry-point do servidor Express
├── frontend/
│   └── src/
│       ├── types/index.ts          # Interfaces TypeScript compartilhadas
│       ├── services/api.ts         # Cliente Axios com interceptors
│       ├── contexts/AuthContext.tsx# Context API de autenticação
│       ├── components/
│       │   ├── Header.tsx          # Barra de navegação superior
│       │   └── PrivateRoute.tsx    # Rota protegida (React Router)
│       ├── pages/
│       │   ├── Login.tsx           # Tela de login
│       │   ├── Lancamentos.tsx     # Listagem de lançamentos
│       │   └── LancamentoForm.tsx  # Modal formulário add/edit
│       ├── App.tsx                 # Roteamento principal
│       ├── main.tsx               # Entry-point React
│       └── index.css              # Estilos globais
├── ecosystem.config.js             # Configuração PM2
└── deploy.sh                       # Script de deploy automático
```

### Número de classes/módulos

| Camada   | Arquivo                       | Responsabilidade                       |
| -------- | ----------------------------- | -------------------------------------- |
| Backend  | `database/db.ts`              | Conexão SQLite, DDL, seed              |
| Backend  | `middleware/auth.ts`          | Validação JWT, tipagem AuthRequest     |
| Backend  | `routes/auth.ts`              | POST /login, GET /me                   |
| Backend  | `routes/lancamentos.ts`       | GET, POST, PUT, DELETE /lancamentos    |
| Backend  | `index.ts`                    | Servidor Express, static files         |
| Frontend | `types/index.ts`              | Interfaces (Lancamento, Usuario, etc.) |
| Frontend | `services/api.ts`             | Instância Axios + interceptors         |
| Frontend | `contexts/AuthContext.tsx`    | Estado global de autenticação          |
| Frontend | `components/Header.tsx`       | Header com logout                      |
| Frontend | `components/PrivateRoute.tsx` | Proteção de rotas                      |
| Frontend | `pages/Login.tsx`             | Tela de login                          |
| Frontend | `pages/Lancamentos.tsx`       | Dashboard + tabela de lançamentos      |
| Frontend | `pages/LancamentoForm.tsx`    | Modal add/edit                         |
| Frontend | `App.tsx`                     | Configuração de rotas                  |

**Total: 14 módulos**

---

## 3. Modelagem do Banco de Dados

### Tabela: `usuario`

| Coluna   | Tipo    | Restrições                             |
| -------- | ------- | -------------------------------------- |
| id       | INTEGER | PRIMARY KEY AUTOINCREMENT              |
| nome     | TEXT    | NOT NULL                               |
| login    | TEXT    | NOT NULL UNIQUE                        |
| senha    | TEXT    | NOT NULL (hash bcrypt)                 |
| situacao | TEXT    | NOT NULL, CHECK IN ('ATIVO','INATIVO') |

### Tabela: `lancamento`

| Coluna          | Tipo    | Restrições                               |
| --------------- | ------- | ---------------------------------------- |
| id              | INTEGER | PRIMARY KEY AUTOINCREMENT                |
| descricao       | TEXT    | NOT NULL                                 |
| data_lancamento | TEXT    | NOT NULL (formato YYYY-MM-DD)            |
| valor           | REAL    | NOT NULL                                 |
| tipo_lancamento | TEXT    | NOT NULL, CHECK IN ('RECEITA','DESPESA') |
| situacao        | TEXT    | NOT NULL, CHECK IN ('ATIVO','INATIVO')   |

### Dados pré-populados (seed)

**Usuário:**
| login | senha |
|-------|----------|
| admin | admin123 |

**Lançamentos (10 registros):**
| # | Descrição | Data | Valor | Tipo |
|---|------------------------|------------|----------|---------|
| 1 | Salário Janeiro | 2026-01-05 | 5.000,00 | RECEITA |
| 2 | Aluguel Janeiro | 2026-01-10 | 1.200,00 | DESPESA |
| 3 | Supermercado | 2026-01-15 | 450,75 | DESPESA |
| 4 | Salário Fevereiro | 2026-02-05 | 5.000,00 | RECEITA |
| 5 | Conta de Luz Fevereiro | 2026-02-12 | 180,50 | DESPESA |
| 6 | Freelance Web | 2026-02-20 | 1.500,00 | RECEITA |
| 7 | Internet Março | 2026-03-01 | 99,90 | DESPESA |
| 8 | Salário Março | 2026-03-05 | 5.000,00 | RECEITA |
| 9 | Restaurante | 2026-03-15 | 85,00 | DESPESA |
|10 | Rendimento CDB | 2026-03-20 | 320,00 | RECEITA |

---

## 4. Rodando Localmente

### Pré-requisitos

- Node.js >= 18
- npm >= 9

### Backend

```bash
cd backend
npm install
npm run dev        # desenvolvimento (porta 3000)
```

### Frontend (em outro terminal)

```bash
cd frontend
npm install
npm run dev        # desenvolvimento (porta 5173, proxy → backend:3000)
```

Acesse: http://localhost:5173

---

## 5. Publicação na VM

### Dados de acesso à VM

| Item    | Valor                       |
| ------- | --------------------------- |
| IP      | 177.44.248.116              |
| Acesso  | ssh univates@177.44.248.116 |
| Usuário | univates                    |
| Senha   | ........                    |

---

### Passo a Passo de Instalação na VM

#### 5.1 Conectar na VM

```bash
ssh univates@177.44.248.116
```

#### 5.2 Atualizar o sistema

```bash
sudo apt update && sudo apt upgrade -y
```

#### 5.3 Instalar Node.js 20 (via NodeSource)

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node --version    # deve exibir v20.x.x
npm --version
```

#### 5.4 Instalar dependências de compilação nativa (necessário para better-sqlite3)

```bash
sudo apt install -y build-essential python3
```

#### 5.5 Instalar PM2 (gerenciador de processos)

```bash
sudo npm install -g pm2
pm2 --version
```

#### 5.6 Criar diretório da aplicação

```bash
mkdir -p /home/univates/financas/backend
mkdir -p /home/univates/financas/frontend
```

---

### 5.7 Implantar a aplicação (a partir da sua máquina local)

#### Opção A — Deploy manual passo a passo

**1. Build local do frontend:**

```bash
cd frontend
npm install
npm run build
cd ..
```

**2. Build local do backend:**

```bash
cd backend
npm install
npm run build
cd ..
```

**3. Copiar arquivos para a VM via SCP:**

```bash
# Backend compilado
scp -r backend/dist      univates@177.44.248.116:/home/univates/financas/backend/
scp    backend/package.json univates@177.44.248.116:/home/univates/financas/backend/

# Frontend compilado
scp -r frontend/dist     univates@177.44.248.116:/home/univates/financas/frontend/

# Configuração PM2
scp ecosystem.config.js  univates@177.44.248.116:/home/univates/financas/
```

**4. Instalar dependências de produção na VM:**

```bash
ssh univates@177.44.248.116 "cd /home/univates/financas/backend && npm install --omit=dev"
```

**5. Iniciar com PM2:**

```bash
ssh univates@177.44.248.116 "cd /home/univates/financas && pm2 start ecosystem.config.js && pm2 save"
```

#### Opção B — Script automático (Linux/macOS)

```bash
chmod +x deploy.sh
./deploy.sh
```

---

### 5.8 Configurar PM2 para iniciar automaticamente após reboot

```bash
ssh univates@177.44.248.116
sudo pm2 startup systemd -u univates --hp /home/univates
pm2 save
```

---

### 5.9 (Opcional) Liberar porta 3000 no firewall

```bash
# Na VM:
sudo ufw allow 3000/tcp
sudo ufw status
```

---

## 6. Acesso à Aplicação

| Item                 | Valor                      |
| -------------------- | -------------------------- |
| URL                  | http://177.44.248.116:3000 |
| Usuário da aplicação | admin                      |
| Senha da aplicação   | admin123                   |

---

## 7. Tempos Gastos

| Etapa                       | Tempo estimado |
| --------------------------- | -------------- |
| Planejamento e arquitetura  | 15 min         |
| Desenvolvimento do backend  | 45 min         |
| Desenvolvimento do frontend | 60 min         |
| Estilização (CSS)           | 30 min         |
| Testes locais               | 15 min         |
| **Total desenvolvimento**   | **~165 min**   |
| Criação do ambiente na VM   | 15 min         |
| Publicação da aplicação     | 10 min         |
| **Total publicação**        | **~25 min**    |
| **TOTAL GERAL**             | **~190 min**   |
