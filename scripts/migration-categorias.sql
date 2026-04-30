-- Migration 002: Criar tabela de categorias
-- Demonstra evolução do schema do banco de dados

CREATE TABLE IF NOT EXISTS categoria (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK(tipo IN ('RECEITA', 'DESPESA')),
    cor TEXT DEFAULT '#6b7280',
    criado_em TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Categorias padrão
INSERT INTO categoria (nome, tipo, cor) VALUES ('Salário', 'RECEITA', '#22c55e');
INSERT INTO categoria (nome, tipo, cor) VALUES ('Freelance', 'RECEITA', '#10b981');
INSERT INTO categoria (nome, tipo, cor) VALUES ('Investimentos', 'RECEITA', '#06b6d4');
INSERT INTO categoria (nome, tipo, cor) VALUES ('Alimentação', 'DESPESA', '#ef4444');
INSERT INTO categoria (nome, tipo, cor) VALUES ('Transporte', 'DESPESA', '#f97316');
INSERT INTO categoria (nome, tipo, cor) VALUES ('Moradia', 'DESPESA', '#8b5cf6');
INSERT INTO categoria (nome, tipo, cor) VALUES ('Lazer', 'DESPESA', '#ec4899');
INSERT INTO categoria (nome, tipo, cor) VALUES ('Saúde', 'DESPESA', '#f59e0b');
