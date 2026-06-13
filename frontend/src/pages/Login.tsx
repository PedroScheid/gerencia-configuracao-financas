import { useState, FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [loginInput, setLoginInput] = useState("");
  const [senha, setSenha] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await login(loginInput, senha);
      navigate("/");
    } catch {
      setError("Login ou senha inválidos. Tente novamente.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-card__header">
          <span className="login-card__icon">💰</span>
          <h1 className="login-card__title">FinançasPessoais</h1>
          <p className="login-card__subtitle">
            Gerência de Receitas e Despesas
          </p>
        </div>

        <form className="login-form" onSubmit={handleSubmit} noValidate>
          {error && <div className="alert alert--error">{error}</div>}

          <div className="form-group">
            <label htmlFor="login" className="form-label">
              Usuário
            </label>
            <input
              id="login"
              type="text"
              className="form-input"
              placeholder="Digite seu usuário"
              value={loginInput}
              onChange={(e) => setLoginInput(e.target.value)}
              autoComplete="username"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="senha" className="form-label">
              Senha
            </label>
            <input
              id="senha"
              type="password"
              className="form-input"
              placeholder="Digite sua senha"
              value={senha}
              onChange={(e) => setSenha(e.target.value)}
              autoComplete="current-password"
              required
            />
          </div>

          <button
            type="submit"
            className="btn btn--primary btn--full"
            disabled={loading}
          >
            {loading ? "Entrando..." : "Entrar"}
          </button>
        </form>

        <p className="login-card__hint">
          Usuário padrão: <strong>admin</strong> / Senha:{" "}
          <strong>admin123</strong>
        </p>
      </div>
    </div>
  );
}
