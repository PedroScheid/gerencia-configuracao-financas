import Database from "better-sqlite3";
import bcrypt from "bcryptjs";
import path from "path";

const DB_PATH =
  process.env.DB_PATH || path.resolve(__dirname, "../../financas.db");

let db: Database.Database;

export function getDb(): Database.Database {
  if (!db) {
    db = new Database(DB_PATH);
    db.pragma("journal_mode = WAL");
    db.pragma("foreign_keys = ON");
    initializeDatabase(db);
  }
  return db;
}

function initializeDatabase(database: Database.Database): void {
  database.exec(`
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
  `);

  const usuarioCount = (
    database.prepare("SELECT COUNT(*) as count FROM usuario").get() as {
      count: number;
    }
  ).count;

  if (usuarioCount === 0) {
    // Seed: 1 usuário administrador (senha: admin123)
    const senhaHash = bcrypt.hashSync("admin123", 10);
    database
      .prepare(
        "INSERT INTO usuario (nome, login, senha, situacao) VALUES (?, ?, ?, ?)",
      )
      .run("Administrador", "admin", senhaHash, "ATIVO");

    // Seed: 10 lançamentos
    const insertLancamento = database.prepare(`
      INSERT INTO lancamento (descricao, data_lancamento, valor, tipo_lancamento, situacao)
      VALUES (@descricao, @data_lancamento, @valor, @tipo_lancamento, @situacao)
    `);

    const seedLancamentos = [
      {
        descricao: "Salário Janeiro",
        data_lancamento: "2026-01-05",
        valor: 5000.0,
        tipo_lancamento: "RECEITA",
        situacao: "ATIVO",
      },
      {
        descricao: "Aluguel Janeiro",
        data_lancamento: "2026-01-10",
        valor: 1200.0,
        tipo_lancamento: "DESPESA",
        situacao: "ATIVO",
      },
      {
        descricao: "Supermercado",
        data_lancamento: "2026-01-15",
        valor: 450.75,
        tipo_lancamento: "DESPESA",
        situacao: "ATIVO",
      },
      {
        descricao: "Salário Fevereiro",
        data_lancamento: "2026-02-05",
        valor: 5000.0,
        tipo_lancamento: "RECEITA",
        situacao: "ATIVO",
      },
      {
        descricao: "Conta de Luz Fevereiro",
        data_lancamento: "2026-02-12",
        valor: 180.5,
        tipo_lancamento: "DESPESA",
        situacao: "ATIVO",
      },
      {
        descricao: "Freelance Web",
        data_lancamento: "2026-02-20",
        valor: 1500.0,
        tipo_lancamento: "RECEITA",
        situacao: "ATIVO",
      },
      {
        descricao: "Internet Março",
        data_lancamento: "2026-03-01",
        valor: 99.9,
        tipo_lancamento: "DESPESA",
        situacao: "ATIVO",
      },
      {
        descricao: "Salário Março",
        data_lancamento: "2026-03-05",
        valor: 5000.0,
        tipo_lancamento: "RECEITA",
        situacao: "ATIVO",
      },
      {
        descricao: "Restaurante",
        data_lancamento: "2026-03-15",
        valor: 85.0,
        tipo_lancamento: "DESPESA",
        situacao: "ATIVO",
      },
      {
        descricao: "Rendimento CDB",
        data_lancamento: "2026-03-20",
        valor: 320.0,
        tipo_lancamento: "RECEITA",
        situacao: "ATIVO",
      },
    ];

    const insertMany = database.transaction(
      (records: typeof seedLancamentos) => {
        for (const record of records) {
          insertLancamento.run(record);
        }
      },
    );
    insertMany(seedLancamentos);
  }
}
