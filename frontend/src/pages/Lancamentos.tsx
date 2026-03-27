import { useEffect, useState, useCallback } from "react";
import Header from "../components/Header";
import LancamentoForm from "./LancamentoForm";
import api from "../services/api";
import { Lancamento, LancamentoFormData } from "../types";

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

  const [showForm, setShowForm] = useState(false);
  const [editingLancamento, setEditingLancamento] = useState<Lancamento | null>(
    null,
  );

  const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);

  const fetchLancamentos = useCallback(async () => {
    try {
      setLoading(true);
      setError("");
      const { data } = await api.get<Lancamento[]>("/lancamentos");
      setLancamentos(data);
    } catch {
      setError("Erro ao carregar lançamentos.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchLancamentos();
  }, [fetchLancamentos]);

  async function handleSave(formData: LancamentoFormData) {
    const payload = { ...formData, valor: Number(formData.valor) };
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

  const filtered = lancamentos.filter((l) => {
    const matchSearch = l.descricao
      .toLowerCase()
      .includes(search.toLowerCase());
    const matchTipo =
      filterTipo === "TODOS" || l.tipo_lancamento === filterTipo;
    const matchSituacao =
      filterSituacao === "TODOS" || l.situacao === filterSituacao;
    return matchSearch && matchTipo && matchSituacao;
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
          </div>
          <button className="btn btn--primary" onClick={openNew}>
            + Novo Lançamento
          </button>
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
