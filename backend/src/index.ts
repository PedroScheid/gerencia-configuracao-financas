const meu_teste = "Olá, mundo!";

import dotenv from "dotenv";
import path from "path";

// Carrega o .env sempre relativo ao próprio arquivo (funciona em dev e na VM)
dotenv.config({ path: path.join(__dirname, "..", ".env") });

import express from "express";
import cors from "cors";
import authRoutes from "./routes/auth";
import lancamentosRoutes from "./routes/lancamentos";
import categoriasRoutes from "./routes/categorias";
import { getDb } from "./database/db";

const app = express();
const PORT = Number(process.env.PORT) || 3000;

// Inicializa o banco de dados (cria tabelas e semeia dados)
getDb();

// Middlewares
app.use(cors());
app.use(express.json());

// Rotas da API
app.use("/api/auth", authRoutes);
app.use("/api/lancamentos", lancamentosRoutes);
app.use("/api/categorias", categoriasRoutes);

// Serve o frontend React em produção
const STATIC_PATH =
  process.env.STATIC_PATH ||
  path.join(__dirname, "..", "..", "frontend", "dist");

app.use(express.static(STATIC_PATH));

// Qualquer rota não-API retorna o index.html (SPA)
app.get(/^(?!\/api).*$/, (_req, res) => {
  res.sendFile(path.join(STATIC_PATH, "index.html"));
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor rodando em http://0.0.0.0:${PORT}`);
});

export default app;
