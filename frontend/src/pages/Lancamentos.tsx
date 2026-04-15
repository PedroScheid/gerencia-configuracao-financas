import { useEffect, useState, useCallback } from "react";
import Header from "../components/Header";
import LancamentoForm from "./LancamentoForm";
import api from "../services/api";
import { exportLancamentosToPdf } from "../services/pdfExportService";
import { Lancamento, LancamentoFormData } from "../types";

const DEFAULT_NOTIFICATION_EMAIL = "pedroscheid10@gmail.com";
const LS_KEY = "notification_email";

function formatCurrency(value: number) {
  return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

function formatDate(dateStr: string) {
  const [y, m, d] = dateStr.split("-");
  return `${d}/${m}/${y}`;
}

export default function Lancamentos() {
  const [lancamentos, setLancamentos] = useState<Lancamento[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [filterTipo, setFilterTipo] = useState<"TODOS" | "RECEITA" | "DESPESA">(
    "TODOS",
  );
  const [filterSituacao, setFilterSituacao] = useState<
    "TODOS" | "ATIVO" | "INATIVO"
  >("TODOS");
  const [filterDataInicio, setFilterDataInicio] = useState("");
  const [filterDataFim, setFilterDataFim] = useState("");

  const [showForm, setShowForm] = useState(false);
  const [editingLancamento, setEditingLancamento] = useState<Lancamento | null>(
    null,
  );

  const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);

  const [notificationEmail, setNotificationEmail] = useState<string>(
    () => localStorage.getItem(LS_KEY) ?? DEFAULT_NOTIFICATION_EMAIL,
  );

  const fetchLancamentos = useCallback(async () => {
    try {
      setLoading(true);
      setError("");
      const params: Record<string, string> = {};
      if (filterDataInicio) params.data_inicio = filterDataInicio;
      if (filterDataFim) params.data_fim = filterDataFim;
      if (filterSituacao !== "TODOS") params.situacao = filterSituacao;

      const { data } = await api.get<Lancamento[]>("/lancamentos", { params });
      setLancamentos(data);
    } catch {
      setError("Erro ao carregar lançamentos.");
    } finally {
      setLoading(false);
    }
  }, [filterDataInicio, filterDataFim, filterSituacao]);

  useEffect(() => {
    fetchLancamentos();
  }, [fetchLancamentos]);

  async function handleSave(formData: LancamentoFormData) {
    const payload = {
      ...formData,
      valor: Number(formData.valor),
      notification_email:
        notificationEmail.trim() || DEFAULT_NOTIFICATION_EMAIL,
    };
    if (editingLancamento) {
      await api.put(`/lancamentos/${editingLancamento.id}`, payload);
    } else {
      await api.post("/lancamentos", payload);
    }
    await fetchLancamentos();
    setEditingLancamento(null);
  }

  async function handleDelete(id: number) {
    await api.delete(`/lancamentos/${id}`);
    setConfirmDeleteId(null);
    await fetchLancamentos();
  }

  function openNew() {
    setEditingLancamento(null);
    setShowForm(true);
  }

  function openEdit(l: Lancamento) {
    setEditingLancamento(l);
    setShowForm(true);
  }

  function closeForm() {
    setShowForm(false);
    setEditingLancamento(null);
  }

  function clearFilters() {
    setFilterDataInicio("");
    setFilterDataFim("");
    setFilterSituacao("TODOS");
    setFilterTipo("TODOS");
    setSearch("");
  }

  function handleExportPdf() {
    exportLancamentosToPdf(filtered);
  }

  const filtered = lancamentos.filter((l) => {
    const matchSearch = l.descricao
      .toLowerCase()
      .includes(search.toLowerCase());
    const matchTipo =
      filterTipo === "TODOS" || l.tipo_lancamento === filterTipo;
    return matchSearch && matchTipo;
  });

  const totalReceitas = lancamentos
    .filter((l) => l.tipo_lancamento === "RECEITA" && l.situacao === "ATIVO")
    .reduce((sum, l) => sum + l.valor, 0);

  const totalDespesas = lancamentos
    .filter((l) => l.tipo_lancamento === "DESPESA" && l.situacao === "ATIVO")
    .reduce((sum, l) => sum + l.valor, 0);

  const saldo = totalReceitas - totalDespesas;

  return (
    <>
      <Header />
      <main className="main">
        {/* Cards resumo */}
        <section className="summary-cards">
          <div className="summary-card summary-card--receita">
            <span className="summary-card__label">Total Receitas</span>
            <span className="summary-card__value">
              {formatCurrency(totalReceitas)}
            </span>
          </div>
          <div className="summary-card summary-card--despesa">
            <span className="summary-card__label">Total Despesas</span>
            <span className="summary-card__value">
              {formatCurrency(totalDespesas)}
            </span>
          </div>
          <div
            className={`summary-card summary-card--saldo${saldo < 0 ? " summary-card--negativo" : ""}`}
          >
            <span className="summary-card__label">Saldo</span>
            <span className="summary-card__value">{formatCurrency(saldo)}</span>
          </div>
        </section>

        {/* Toolbar */}
        <div className="toolbar">
          <div className="toolbar__filters">
            <input
              type="search"
              className="form-input form-input--search"
              placeholder="🔍 Buscar por descrição..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
            <select
              className="form-input form-input--select"
              value={filterTipo}
              onChange={(e) =>
                setFilterTipo(e.target.value as typeof filterTipo)
              }
            >
              <option value="TODOS">Todos os tipos</option>
              <option value="RECEITA">Receitas</option>
              <option value="DESPESA">Despesas</option>
            </select>
            <select
              className="form-input form-input--select"
              value={filterSituacao}
              onChange={(e) =>
                setFilterSituacao(e.target.value as typeof filterSituacao)
              }
            >
              <option value="TODOS">Todas situações</option>
              <option value="ATIVO">Ativo</option>
              <option value="INATIVO">Inativo</option>
            </select>
            <label className="form-label" htmlFor="data-inicio">
              De:
            </label>
            <input
              id="data-inicio"
              type="date"
              className="form-input"
              value={filterDataInicio}
              onChange={(e) => setFilterDataInicio(e.target.value)}
            />
            <label className="form-label" htmlFor="data-fim">
              Até:
            </label>
            <input
              id="data-fim"
              type="date"
              className="form-input"
              value={filterDataFim}
              min={filterDataInicio || undefined}
              onChange={(e) => setFilterDataFim(e.target.value)}
            />
            {(filterDataInicio ||
              filterDataFim ||
              filterSituacao !== "TODOS" ||
              filterTipo !== "TODOS" ||
              search) && (
              <button
                className="btn btn--secondary btn--sm"
                onClick={clearFilters}
                title="Limpar filtros"
              >
                ✕ Limpar
              </button>
            )}
          </div>
          <div className="toolbar__actions">
            <div className="notification-email">
              <label
                htmlFor="notification-email"
                className="notification-email__label"
              >
                ✉️ Notificar:
              </label>
              <input
                id="notification-email"
                type="email"
                className="form-input notification-email__input"
                value={notificationEmail}
                onChange={(e) => {
                  setNotificationEmail(e.target.value);
                  localStorage.setItem(LS_KEY, e.target.value);
                }}
                placeholder={DEFAULT_NOTIFICATION_EMAIL}
                title="E-mail que receberá notificações de criação/edição de lançamentos"
              />
            </div>
            <button
              className="btn btn--secondary"
              onClick={handleExportPdf}
              title="Exportar para PDF"
            >
              📄 Exportar PDF
            </button>
            <button className="btn btn--primary" onClick={openNew}>
              + Novo Lançamento
            </button>
          </div>
        </div>

        {/* Tabela */}
        <div className="table-wrapper">
          {loading && <p className="table-message">Carregando...</p>}
          {!loading && error && (
            <div className="alert alert--error">{error}</div>
          )}
          {!loading && !error && (
            <table className="table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Descrição</th>
                  <th>Data</th>
                  <th>Valor</th>
                  <th>Tipo</th>
                  <th>Situação</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="table-message">
                      Nenhum lançamento encontrado.
                    </td>
                  </tr>
                ) : (
                  filtered.map((l) => (
                    <tr
                      key={l.id}
                      className={l.situacao === "INATIVO" ? "row--inativo" : ""}
                    >
                      <td>{l.id}</td>
                      <td>{l.descricao}</td>
                      <td>{formatDate(l.data_lancamento)}</td>
                      <td
                        className={
                          l.tipo_lancamento === "RECEITA"
                            ? "valor--receita"
                            : "valor--despesa"
                        }
                      >
                        {formatCurrency(l.valor)}
                      </td>
                      <td>
                        <span
                          className={`badge badge--${l.tipo_lancamento === "RECEITA" ? "receita" : "despesa"}`}
                        >
                          {l.tipo_lancamento === "RECEITA"
                            ? "↑ Receita"
                            : "↓ Despesa"}
                        </span>
                      </td>
                      <td>
                        <span
                          className={`badge badge--${l.situacao === "ATIVO" ? "ativo" : "inativo"}`}
                        >
                          {l.situacao}
                        </span>
                      </td>
                      <td>
                        <div className="action-buttons">
                          <button
                            className="btn btn--sm btn--secondary"
                            onClick={() => openEdit(l)}
                            title="Editar"
                          >
                            ✏️
                          </button>
                          <button
                            className="btn btn--sm btn--danger"
                            onClick={() => setConfirmDeleteId(l.id)}
                            title="Excluir"
                          >
                            🗑️
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          )}
          {!loading && !error && (
            <p className="table-footer">
              {filtered.length} registro(s) exibido(s) de {lancamentos.length}{" "}
              total
            </p>
          )}
        </div>
      </main>

      {/* Modal Formulário */}
      {showForm && (
        <LancamentoForm
          lancamento={editingLancamento}
          onSave={handleSave}
          onClose={closeForm}
        />
      )}

      {/* Modal Confirmação de Exclusão */}
      {confirmDeleteId !== null && (
        <div
          className="modal-backdrop"
          onClick={() => setConfirmDeleteId(null)}
        >
          <div
            className="modal modal--sm"
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
          >
            <div className="modal__header">
              <h2 className="modal__title">Confirmar Exclusão</h2>
            </div>
            <p className="modal__body">
              Tem certeza que deseja excluir este lançamento? Esta ação não pode
              ser desfeita.
            </p>
            <div className="modal__footer">
              <button
                className="btn btn--secondary"
                onClick={() => setConfirmDeleteId(null)}
              >
                Cancelar
              </button>
              <button
                className="btn btn--danger"
                onClick={() => handleDelete(confirmDeleteId)}
              >
                Excluir
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
