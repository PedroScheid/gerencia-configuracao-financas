import Database from "better-sqlite3";
import {
  LancamentoService,
  CreateLancamentoData,
  LancamentoRow,
} from "../services/lancamentoService";
import type {
  IEmailService,
  LancamentoEmailData,
  EmailAction,
} from "../services/emailService";

// ── In-memory DB helper ───────────────────────────────────────────────────────

function createTestDb(): Database.Database {
  const db = new Database(":memory:");
  db.pragma("foreign_keys = ON");
  db.exec(`
    CREATE TABLE lancamento (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      descricao TEXT NOT NULL,
      data_lancamento TEXT NOT NULL,
      valor REAL NOT NULL,
      tipo_lancamento TEXT NOT NULL,
      situacao TEXT NOT NULL DEFAULT 'ATIVO'
    );
  `);
  return db;
}

// ── Mock email service ────────────────────────────────────────────────────────

class MockEmailService implements IEmailService {
  calls: Array<{ lancamento: LancamentoEmailData; action: EmailAction }> = [];
  shouldThrow = false;

  async sendLancamentoNotification(
    lancamento: LancamentoEmailData,
    action: EmailAction,
  ): Promise<void> {
    if (this.shouldThrow) throw new Error("Email service unavailable");
    this.calls.push({ lancamento, action });
  }
}

// ── Seed helpers ──────────────────────────────────────────────────────────────

function seedLancamentos(db: Database.Database) {
  const insert = db.prepare(
    "INSERT INTO lancamento (descricao, data_lancamento, valor, tipo_lancamento, situacao) VALUES (?, ?, ?, ?, ?)",
  );
  insert.run("Salário", "2026-01-05", 5000, "RECEITA", "ATIVO");
  insert.run("Aluguel", "2026-01-10", 1200, "DESPESA", "ATIVO");
  insert.run("Supermercado", "2026-02-15", 450, "DESPESA", "INATIVO");
  insert.run("Freelance", "2026-03-01", 2000, "RECEITA", "ATIVO");
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("LancamentoService – CRUD", () => {
  let db: Database.Database;
  let emailSvc: MockEmailService;
  let service: LancamentoService;

  beforeEach(() => {
    db = createTestDb();
    seedLancamentos(db);
    emailSvc = new MockEmailService();
    service = new LancamentoService(db, emailSvc);
  });

  afterEach(() => db.close());

  // Test 12
  it("getAll returns all seeded records when no filters applied", () => {
    const result = service.getAll();
    expect(result).toHaveLength(4);
  });

  // Test 13
  it("getById returns the correct record", () => {
    const first = db.prepare("SELECT id FROM lancamento LIMIT 1").get() as {
      id: number;
    };
    const result = service.getById(first.id);
    expect(result).toBeDefined();
    expect(result!.descricao).toBe("Salário");
  });

  // Test 14
  it("getById returns undefined for a non-existing id", () => {
    const result = service.getById(9999);
    expect(result).toBeUndefined();
  });

  // Test 15
  it("create inserts a new record and returns it with an id", async () => {
    const data: CreateLancamentoData = {
      descricao: "Novo lançamento",
      data_lancamento: "2026-04-01",
      valor: 300,
      tipo_lancamento: "DESPESA",
    };
    const novo = await service.create(data);
    expect(novo.id).toBeDefined();
    expect(novo.descricao).toBe("Novo lançamento");
    expect(novo.situacao).toBe("ATIVO");
  });

  // Test 16
  it("update modifies an existing record and returns the updated version", async () => {
    const first = db.prepare("SELECT id FROM lancamento LIMIT 1").get() as {
      id: number;
    };
    const updated = await service.update(first.id, { valor: 9999 });
    expect(updated).not.toBeNull();
    expect(updated!.valor).toBe(9999);
  });

  // Test 17
  it("update returns null when record does not exist", async () => {
    const result = await service.update(9999, { valor: 100 });
    expect(result).toBeNull();
  });

  // Test 18
  it("delete removes the record and returns true", () => {
    const first = db.prepare("SELECT id FROM lancamento LIMIT 1").get() as {
      id: number;
    };
    const deleted = service.delete(first.id);
    expect(deleted).toBe(true);
    expect(service.getById(first.id)).toBeUndefined();
  });

  // Test 19
  it("delete returns false when record does not exist", () => {
    const result = service.delete(9999);
    expect(result).toBe(false);
  });
});

describe("LancamentoService – Filtering", () => {
  let db: Database.Database;
  let emailSvc: MockEmailService;
  let service: LancamentoService;

  beforeEach(() => {
    db = createTestDb();
    seedLancamentos(db);
    emailSvc = new MockEmailService();
    service = new LancamentoService(db, emailSvc);
  });

  afterEach(() => db.close());

  // Test 20
  it("filters by data_inicio only – returns records on or after that date", () => {
    const result = service.getAll({ data_inicio: "2026-02-01" });
    expect(
      result.every((r: LancamentoRow) => r.data_lancamento >= "2026-02-01"),
    ).toBe(true);
    expect(result).toHaveLength(2);
  });

  // Test 21
  it("filters by data_fim only – returns records on or before that date", () => {
    const result = service.getAll({ data_fim: "2026-01-31" });
    expect(
      result.every((r: LancamentoRow) => r.data_lancamento <= "2026-01-31"),
    ).toBe(true);
    expect(result).toHaveLength(2);
  });

  // Test 22
  it("filters by date range – returns records within the range", () => {
    const result = service.getAll({
      data_inicio: "2026-01-10",
      data_fim: "2026-02-28",
    });
    expect(result).toHaveLength(2);
    result.forEach((r: LancamentoRow) => {
      expect(r.data_lancamento >= "2026-01-10").toBe(true);
      expect(r.data_lancamento <= "2026-02-28").toBe(true);
    });
  });

  // Test 23
  it("filters by situacao=ATIVO only", () => {
    const result = service.getAll({ situacao: "ATIVO" });
    expect(result.every((r: LancamentoRow) => r.situacao === "ATIVO")).toBe(
      true,
    );
    expect(result).toHaveLength(3);
  });

  // Test 24
  it("filters by situacao=INATIVO only", () => {
    const result = service.getAll({ situacao: "INATIVO" });
    expect(result.every((r: LancamentoRow) => r.situacao === "INATIVO")).toBe(
      true,
    );
    expect(result).toHaveLength(1);
  });

  // Test 25
  it("combines date range and situacao filter", () => {
    const result = service.getAll({
      data_inicio: "2026-01-01",
      data_fim: "2026-02-28",
      situacao: "ATIVO",
    });
    result.forEach((r: LancamentoRow) => {
      expect(r.situacao).toBe("ATIVO");
      expect(r.data_lancamento >= "2026-01-01").toBe(true);
      expect(r.data_lancamento <= "2026-02-28").toBe(true);
    });
  });

  // Test 26
  it("returns empty array when date range matches no records", () => {
    const result = service.getAll({
      data_inicio: "2030-01-01",
      data_fim: "2030-12-31",
    });
    expect(result).toHaveLength(0);
  });

  // Test 27
  it("situcao=TODOS is treated as no status filter", () => {
    const total = service.getAll();
    const withTodos = service.getAll({ situacao: "TODOS" });
    expect(withTodos).toHaveLength(total.length);
  });
});

describe("LancamentoService – Email integration", () => {
  let db: Database.Database;
  let emailSvc: MockEmailService;
  let service: LancamentoService;

  beforeEach(() => {
    db = createTestDb();
    emailSvc = new MockEmailService();
    service = new LancamentoService(db, emailSvc);
  });

  afterEach(() => db.close());

  const baseData: CreateLancamentoData = {
    descricao: "Test",
    data_lancamento: "2026-04-01",
    valor: 100,
    tipo_lancamento: "RECEITA",
  };

  // Test 28
  it("calls email service exactly once with action=created on create", async () => {
    await service.create(baseData);
    expect(emailSvc.calls).toHaveLength(1);
    expect(emailSvc.calls[0].action).toBe("created");
  });

  // Test 29
  it("calls email service exactly once with action=updated on update", async () => {
    const novo = await service.create(baseData);
    emailSvc.calls = []; // reset after create
    await service.update(novo.id, { valor: 200 });
    expect(emailSvc.calls).toHaveLength(1);
    expect(emailSvc.calls[0].action).toBe("updated");
  });

  // Test 30
  it("does NOT call email service on delete", async () => {
    const novo = await service.create(baseData);
    emailSvc.calls = [];
    service.delete(novo.id);
    expect(emailSvc.calls).toHaveLength(0);
  });

  // Test 31
  it("throws when email service throws during create", async () => {
    emailSvc.shouldThrow = true;
    await expect(service.create(baseData)).rejects.toThrow(
      "Email service unavailable",
    );
  });
});
