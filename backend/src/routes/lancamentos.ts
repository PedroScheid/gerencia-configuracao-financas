import { Router, Response } from "express";
import { getDb } from "../database/db";
import { authMiddleware, AuthRequest } from "../middleware/auth";

const router = Router();

// Todas as rotas exigem autenticação
router.use(authMiddleware);

interface LancamentoRow {
  id: number;
  descricao: string;
  data_lancamento: string;
  valor: number;
  tipo_lancamento: string;
  situacao: string;
}

// GET /api/lancamentos
router.get("/", (_req: AuthRequest, res: Response): void => {
  const db = getDb();
  const lancamentos = db
    .prepare("SELECT * FROM lancamento ORDER BY data_lancamento DESC, id DESC")
    .all() as LancamentoRow[];
  res.json(lancamentos);
});

// GET /api/lancamentos/:id
router.get("/:id", (req: AuthRequest, res: Response): void => {
  const db = getDb();
  const lancamento = db
    .prepare("SELECT * FROM lancamento WHERE id = ?")
    .get(req.params.id) as LancamentoRow | undefined;

  if (!lancamento) {
    res.status(404).json({ error: "Lançamento não encontrado" });
    return;
  }
  res.json(lancamento);
});

// POST /api/lancamentos
router.post("/", (req: AuthRequest, res: Response): void => {
  const { descricao, data_lancamento, valor, tipo_lancamento, situacao } =
    req.body as Partial<LancamentoRow>;

  if (
    !descricao ||
    !data_lancamento ||
    valor === undefined ||
    !tipo_lancamento
  ) {
    res.status(400).json({ error: "Campos obrigatórios não preenchidos" });
    return;
  }

  if (!["RECEITA", "DESPESA"].includes(tipo_lancamento)) {
    res
      .status(400)
      .json({ error: "tipo_lancamento deve ser RECEITA ou DESPESA" });
    return;
  }

  if (situacao && !["ATIVO", "INATIVO"].includes(situacao)) {
    res.status(400).json({ error: "situacao deve ser ATIVO ou INATIVO" });
    return;
  }

  const db = getDb();
  const result = db
    .prepare(
      "INSERT INTO lancamento (descricao, data_lancamento, valor, tipo_lancamento, situacao) VALUES (?, ?, ?, ?, ?)",
    )
    .run(
      descricao,
      data_lancamento,
      valor,
      tipo_lancamento,
      situacao ?? "ATIVO",
    );

  const novo = db
    .prepare("SELECT * FROM lancamento WHERE id = ?")
    .get(result.lastInsertRowid) as LancamentoRow;

  res.status(201).json(novo);
});

// PUT /api/lancamentos/:id
router.put("/:id", (req: AuthRequest, res: Response): void => {
  const { id } = req.params;
  const db = getDb();

  const existing = db
    .prepare("SELECT * FROM lancamento WHERE id = ?")
    .get(id) as LancamentoRow | undefined;

  if (!existing) {
    res.status(404).json({ error: "Lançamento não encontrado" });
    return;
  }

  const { descricao, data_lancamento, valor, tipo_lancamento, situacao } =
    req.body as Partial<LancamentoRow>;

  db.prepare(
    "UPDATE lancamento SET descricao=?, data_lancamento=?, valor=?, tipo_lancamento=?, situacao=? WHERE id=?",
  ).run(
    descricao ?? existing.descricao,
    data_lancamento ?? existing.data_lancamento,
    valor ?? existing.valor,
    tipo_lancamento ?? existing.tipo_lancamento,
    situacao ?? existing.situacao,
    id,
  );

  const updated = db
    .prepare("SELECT * FROM lancamento WHERE id = ?")
    .get(id) as LancamentoRow;

  res.json(updated);
});

// DELETE /api/lancamentos/:id
router.delete("/:id", (req: AuthRequest, res: Response): void => {
  const { id } = req.params;
  const db = getDb();

  const existing = db
    .prepare("SELECT * FROM lancamento WHERE id = ?")
    .get(id) as LancamentoRow | undefined;

  if (!existing) {
    res.status(404).json({ error: "Lançamento não encontrado" });
    return;
  }

  db.prepare("DELETE FROM lancamento WHERE id = ?").run(id);
  res.status(204).send();
});

export default router;
