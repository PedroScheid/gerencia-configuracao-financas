import type Database from "better-sqlite3";
import type { IEmailService, LancamentoEmailData } from "./emailService";

export interface LancamentoRow {
  id: number;
  descricao: string;
  data_lancamento: string;
  valor: number;
  tipo_lancamento: string;
  situacao: string;
}

export interface CreateLancamentoData {
  descricao: string;
  data_lancamento: string;
  valor: number;
  tipo_lancamento: string;
  situacao?: string;
}

export interface LancamentoFilters {
  data_inicio?: string;
  data_fim?: string;
  situacao?: string;
}

export class LancamentoService {
  constructor(
    private readonly db: Database.Database,
    private readonly emailService: IEmailService,
  ) {}

  getAll(filters: LancamentoFilters = {}): LancamentoRow[] {
    const conditions: string[] = [];
    const params: (string | number)[] = [];

    if (filters.data_inicio) {
      conditions.push("data_lancamento >= ?");
      params.push(filters.data_inicio);
    }
    if (filters.data_fim) {
      conditions.push("data_lancamento <= ?");
      params.push(filters.data_fim);
    }
    if (filters.situacao && filters.situacao !== "TODOS") {
      conditions.push("situacao = ?");
      params.push(filters.situacao);
    }

    const where =
      conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";
    const sql = `SELECT * FROM lancamento ${where} ORDER BY data_lancamento DESC, id DESC`;

    return this.db.prepare(sql).all(...params) as LancamentoRow[];
  }

  getById(id: number): LancamentoRow | undefined {
    return this.db.prepare("SELECT * FROM lancamento WHERE id = ?").get(id) as
      | LancamentoRow
      | undefined;
  }

  async create(
    data: CreateLancamentoData,
    notificationEmail?: string,
  ): Promise<LancamentoRow> {
    const result = this.db
      .prepare(
        "INSERT INTO lancamento (descricao, data_lancamento, valor, tipo_lancamento, situacao) VALUES (?, ?, ?, ?, ?)",
      )
      .run(
        data.descricao,
        data.data_lancamento,
        data.valor,
        data.tipo_lancamento,
        data.situacao ?? "ATIVO",
      );

    const novo = this.db
      .prepare("SELECT * FROM lancamento WHERE id = ?")
      .get(result.lastInsertRowid) as LancamentoRow;

    this.emailService
      .sendLancamentoNotification(
        novo as LancamentoEmailData,
        "created",
        notificationEmail,
      )
      .catch((err) =>
        console.error(
          "[LancamentoService] Falha ao enviar e-mail (create):",
          err,
        ),
      );

    return novo;
  }

  async update(
    id: number,
    data: Partial<CreateLancamentoData>,
    notificationEmail?: string,
  ): Promise<LancamentoRow | null> {
    const existing = this.getById(id);
    if (!existing) return null;

    this.db
      .prepare(
        "UPDATE lancamento SET descricao=?, data_lancamento=?, valor=?, tipo_lancamento=?, situacao=? WHERE id=?",
      )
      .run(
        data.descricao ?? existing.descricao,
        data.data_lancamento ?? existing.data_lancamento,
        data.valor ?? existing.valor,
        data.tipo_lancamento ?? existing.tipo_lancamento,
        data.situacao ?? existing.situacao,
        id,
      );

    const updated = this.getById(id) as LancamentoRow;

    this.emailService
      .sendLancamentoNotification(
        updated as LancamentoEmailData,
        "updated",
        notificationEmail,
      )
      .catch((err) =>
        console.error(
          "[LancamentoService] Falha ao enviar e-mail (update):",
          err,
        ),
      );

    return updated;
  }

  delete(id: number): boolean {
    const existing = this.getById(id);
    if (!existing) return false;

    this.db.prepare("DELETE FROM lancamento WHERE id = ?").run(id);
    return true;
  }
}
