import { Router, Response } from "express";
import { getDb } from "../database/db";
import { authMiddleware, AuthRequest } from "../middleware/auth";
import {
  LancamentoService,
  LancamentoFilters,
} from "../services/lancamentoService";
import { NodemailerEmailService } from "../services/emailService";
import type { IEmailService } from "../services/emailService";

const router = Router();

// All routes require authentication
router.use(authMiddleware);

/** Factory – allows tests to inject a mock email service */
export function createLancamentoService(
  emailService: IEmailService = new NodemailerEmailService(),
): LancamentoService {
  return new LancamentoService(getDb(), emailService);
}

// GET /api/lancamentos?data_inicio=YYYY-MM-DD&data_fim=YYYY-MM-DD&situacao=ATIVO
router.get("/", (_req: AuthRequest, res: Response): void => {
  const { data_inicio, data_fim, situacao } = _req.query as Record<
    string,
    string | undefined
  >;

  const filters: LancamentoFilters = {
    data_inicio: data_inicio || undefined,
    data_fim: data_fim || undefined,
    situacao: situacao || undefined,
  };

  const service = createLancamentoService();
  const lancamentos = service.getAll(filters);
  res.json(lancamentos);
});

// GET /api/lancamentos/:id
router.get("/:id", (req: AuthRequest, res: Response): void => {
  const id = Number(req.params.id);
  const service = createLancamentoService();
  const lancamento = service.getById(id);

  if (!lancamento) {
    res.status(404).json({ error: "Lançamento não encontrado" });
    return;
  }
  res.json(lancamento);
});

// POST /api/lancamentos
router.post("/", async (req: AuthRequest, res: Response): Promise<void> => {
  const { descricao, data_lancamento, valor, tipo_lancamento, situacao } =
    req.body as Partial<{
      descricao: string;
      data_lancamento: string;
      valor: number;
      tipo_lancamento: string;
      situacao: string;
    }>;

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

  try {
    const service = createLancamentoService();
    const novo = await service.create({
      descricao,
      data_lancamento,
      valor: Number(valor),
      tipo_lancamento,
      situacao,
    });
    res.status(201).json(novo);
  } catch (err) {
    console.error("[POST /lancamentos]", err);
    res.status(500).json({ error: "Erro interno ao criar lançamento" });
  }
});

// PUT /api/lancamentos/:id
router.put("/:id", async (req: AuthRequest, res: Response): Promise<void> => {
  const id = Number(req.params.id);

  try {
    const service = createLancamentoService();
    const updated = await service.update(id, req.body);

    if (!updated) {
      res.status(404).json({ error: "Lançamento não encontrado" });
      return;
    }

    res.json(updated);
  } catch (err) {
    console.error("[PUT /lancamentos/:id]", err);
    res.status(500).json({ error: "Erro interno ao atualizar lançamento" });
  }
});

// DELETE /api/lancamentos/:id
router.delete("/:id", (req: AuthRequest, res: Response): void => {
  const id = Number(req.params.id);
  const service = createLancamentoService();
  const deleted = service.delete(id);

  if (!deleted) {
    res.status(404).json({ error: "Lançamento não encontrado" });
    return;
  }

  res.status(204).send();
});

export default router;
