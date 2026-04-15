import { Router, Response } from "express";
import { getDb } from "../database/db";
import { authMiddleware, AuthRequest } from "../middleware/auth";

const router = Router();

router.use(authMiddleware);

// GET /api/settings
router.get("/", (_req: AuthRequest, res: Response): void => {
  const db = getDb();
  const row = db
    .prepare("SELECT value FROM settings WHERE key = 'notification_email'")
    .get() as { value: string } | undefined;

  res.json({ notification_email: row?.value ?? "" });
});

// PUT /api/settings
router.put("/", (req: AuthRequest, res: Response): void => {
  const { notification_email } = req.body as {
    notification_email?: string;
  };

  if (notification_email === undefined) {
    res.status(400).json({ error: "Campo notification_email é obrigatório" });
    return;
  }

  // Basic email format validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (notification_email !== "" && !emailRegex.test(notification_email)) {
    res.status(400).json({ error: "Formato de e-mail inválido" });
    return;
  }

  const db = getDb();
  db.prepare(
    "INSERT INTO settings (key, value) VALUES ('notification_email', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
  ).run(notification_email);

  res.json({ notification_email });
});

export default router;
