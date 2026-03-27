import { useAuth } from "../contexts/AuthContext";
import { useNavigate } from "react-router-dom";

export default function Header() {
  const { usuario, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate("/login");
  }

  return (
    <header className="header">
      <div className="header__brand">
        <span className="header__icon">💰</span>
        <span className="header__title">FinançasPessoais</span>
      </div>
      <div className="header__user">
        <span className="header__user-name">Olá, {usuario?.nome}</span>
        <button className="btn btn--outline-white" onClick={handleLogout}>
          Sair
        </button>
      </div>
    </header>
  );
}
