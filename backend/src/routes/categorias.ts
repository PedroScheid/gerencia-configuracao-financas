import { Router, Response } from "express";
import { getDb } from "../database/db";
import { authMiddleware, AuthRequest } from "../middleware/auth";

const router = Router();

// GET /api/categorias (público — sem auth para facilitar demo)
router.get("/", (_req: AuthRequest, res: Response): void => {
  const db = getDb();
  const categorias = db.prepare("SELECT * FROM categoria ORDER BY tipo, nome").all();
  res.json(categorias);
});

export default router;
