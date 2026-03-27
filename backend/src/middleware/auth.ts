import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

export const JWT_SECRET = process.env.JWT_SECRET || "financas_jwt_secret_2026";

export interface AuthRequest extends Request {
  userId?: number;
  userLogin?: string;
}

export function authMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Token não fornecido" });
    return;
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as {
      userId: number;
      login: string;
    };
    req.userId = decoded.userId;
    req.userLogin = decoded.login;
    next();
  } catch {
    res.status(401).json({ error: "Token inválido ou expirado" });
  }
}
