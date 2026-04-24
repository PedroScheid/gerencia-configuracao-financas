-- Migration 001: Schema inicial
CREATE TABLE IF NOT EXISTS usuario (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    login TEXT NOT NULL UNIQUE,
    senha TEXT NOT NULL,
    situacao TEXT NOT NULL DEFAULT 'ATIVO' CHECK(situacao IN ('ATIVO', 'INATIVO'))
);

CREATE TABLE IF NOT EXISTS lancamento (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descricao TEXT NOT NULL,
    data_lancamento TEXT NOT NULL,
    valor REAL NOT NULL,
    tipo_lancamento TEXT NOT NULL CHECK(tipo_lancamento IN ('RECEITA', 'DESPESA')),
    situacao TEXT NOT NULL DEFAULT 'ATIVO' CHECK(situacao IN ('ATIVO', 'INATIVO'))
);
