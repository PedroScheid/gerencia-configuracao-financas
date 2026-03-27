import { Router, Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { getDb } from "../database/db";
import { authMiddleware, AuthRequest, JWT_SECRET } from "../middleware/auth";

const router = Router();

interface UsuarioRow {
  id: number;
  nome: string;
  login: string;
  senha: string;
  situacao: string;
}

// POST /api/auth/login
router.post("/login", (req: Request, res: Response): void => {
  const { login, senha } = req.body as { login?: string; senha?: string };

  if (!login || !senha) {
    res.status(400).json({ error: "Login e senha são obrigatórios" });
    return;
  }

  const db = getDb();
  const usuario = db
    .prepare("SELECT * FROM usuario WHERE login = ? AND situacao = 'ATIVO'")
    .get(login) as UsuarioRow | undefined;

  if (!usuario || !bcrypt.compareSync(senha, usuario.senha)) {
    res.status(401).json({ error: "Login ou senha inválidos" });
    return;
  }

  const token = jwt.sign(
    { userId: usuario.id, login: usuario.login },
    JWT_SECRET,
    { expiresIn: "24h" },
  );

  res.json({
    token,
    usuario: { id: usuario.id, nome: usuario.nome, login: usuario.login },
  });
});

// GET /api/auth/me
router.get("/me", authMiddleware, (req: AuthRequest, res: Response): void => {
  const db = getDb();
  const usuario = db
    .prepare("SELECT id, nome, login, situacao FROM usuario WHERE id = ?")
    .get(req.userId) as Omit<UsuarioRow, "senha"> | undefined;

  if (!usuario) {
    res.status(404).json({ error: "Usuário não encontrado" });
    return;
  }

  res.json(usuario);
});

export default router;
