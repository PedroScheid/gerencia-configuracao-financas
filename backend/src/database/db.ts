import Database from "better-sqlite3";
import bcrypt from "bcryptjs";
import path from "path";
import fs from "fs";

const DB_PATH =
  process.env.DB_PATH || path.resolve(__dirname, "../../financas.db");

let db: Database.Database;

export function getDb(): Database.Database {
  if (!db) {
    db = new Database(DB_PATH);
    db.pragma("journal_mode = WAL");
    db.pragma("foreign_keys = ON");
    runMigrations(db);
    seedData(db);
  }
  return db;
}

function runMigrations(database: Database.Database): void {
  // Cria tabela de controle de migrations
  database.exec(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      filename TEXT NOT NULL UNIQUE,
      applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);

  // Resolve o diretório de migrations (funciona com ts-node e JS compilado)
  const migrationsDir = path.resolve(__dirname, "migrations");

  if (!fs.existsSync(migrationsDir)) {
    console.warn(`Diretório de migrations não encontrado: ${migrationsDir}`);
    return;
  }

  // Lê e ordena os arquivos .sql
  const files = fs
    .readdirSync(migrationsDir)
    .filter((f) => f.endsWith(".sql"))
    .sort();

  // Busca migrations já aplicadas
  const applied = new Set(
    (
      database
        .prepare("SELECT filename FROM schema_migrations")
        .all() as { filename: string }[]
    ).map((row) => row.filename)
  );

  // Executa migrations pendentes
  for (const file of files) {
    if (applied.has(file)) {
      continue;
    }

    console.log(`Aplicando migration: ${file}`);
    const sql = fs.readFileSync(path.join(migrationsDir, file), "utf-8");

    database.transaction(() => {
      database.exec(sql);
      database
        .prepare("INSERT INTO schema_migrations (filename) VALUES (?)")
        .run(file);
    })();

    console.log(`Migration aplicada com sucesso: ${file}`);
  }
}

function seedData(database: Database.Database): void {
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
