import { FormEvent, useState, useEffect } from "react";
import {
  Lancamento,
  LancamentoFormData,
  TipoLancamento,
  Situacao,
} from "../types";

interface Props {
  lancamento?: Lancamento | null;
  onSave: (data: LancamentoFormData) => Promise<void>;
  onClose: () => void;
}

const EMPTY_FORM: LancamentoFormData = {
  descricao: "",
  data_lancamento: new Date().toISOString().slice(0, 10),
  valor: "",
  tipo_lancamento: "RECEITA",
  situacao: "ATIVO",
};

export default function LancamentoForm({ lancamento, onSave, onClose }: Props) {
  const [form, setForm] = useState<LancamentoFormData>(EMPTY_FORM);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (lancamento) {
      setForm({
        descricao: lancamento.descricao,
        data_lancamento: lancamento.data_lancamento,
        valor: String(lancamento.valor),
        tipo_lancamento: lancamento.tipo_lancamento,
        situacao: lancamento.situacao,
      });
    } else {
      setForm(EMPTY_FORM);
    }
  }, [lancamento]);

  function handleChange(
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>,
  ) {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");

    if (!form.descricao.trim()) {
      setError("Descrição é obrigatória.");
      return;
    }
    if (!form.valor || isNaN(Number(form.valor)) || Number(form.valor) <= 0) {
      setError("Informe um valor válido maior que zero.");
      return;
    }

    setLoading(true);
    try {
      await onSave(form);
      onClose();
    } catch {
      setError("Erro ao salvar lançamento. Tente novamente.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="modal"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-label="Formulário de lançamento"
      >
        <div className="modal__header">
          <h2 className="modal__title">
            {lancamento ? "Editar Lançamento" : "Novo Lançamento"}
          </h2>
          <button
            className="modal__close"
            onClick={onClose}
            aria-label="Fechar"
          >
            ✕
          </button>
        </div>

        <form onSubmit={handleSubmit} noValidate>
          {error && <div className="alert alert--error">{error}</div>}

          <div className="form-group">
            <label htmlFor="descricao" className="form-label">
              Descrição *
            </label>
            <input
              id="descricao"
              name="descricao"
              type="text"
              className="form-input"
              placeholder="Ex: Salário, Aluguel..."
              value={form.descricao}
              onChange={handleChange}
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="data_lancamento" className="form-label">
                Data *
              </label>
              <input
                id="data_lancamento"
                name="data_lancamento"
                type="date"
                className="form-input"
                value={form.data_lancamento}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="valor" className="form-label">
                Valor (R$) *
              </label>
              <input
                id="valor"
                name="valor"
                type="number"
                className="form-input"
                placeholder="0,00"
                min="0.01"
                step="0.01"
                value={form.valor}
                onChange={handleChange}
                required
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label className="form-label">Tipo *</label>
              <div className="radio-group">
                {(["RECEITA", "DESPESA"] as TipoLancamento[]).map((tipo) => (
                  <label key={tipo} className="radio-label">
                    <input
                      type="radio"
                      name="tipo_lancamento"
                      value={tipo}
                      checked={form.tipo_lancamento === tipo}
                      onChange={handleChange}
                    />
                    <span
                      className={`badge badge--${tipo === "RECEITA" ? "receita" : "despesa"}`}
                    >
                      {tipo === "RECEITA" ? "↑ Receita" : "↓ Despesa"}
                    </span>
                  </label>
                ))}
              </div>
            </div>

            <div className="form-group">
              <label htmlFor="situacao" className="form-label">
                Situação
              </label>
              <select
                id="situacao"
                name="situacao"
                className="form-input"
                value={form.situacao}
                onChange={handleChange}
              >
                {(["ATIVO", "INATIVO"] as Situacao[]).map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="modal__footer">
            <button
              type="button"
              className="btn btn--secondary"
              onClick={onClose}
              disabled={loading}
            >
              Cancelar
            </button>
            <button
              type="submit"
              className="btn btn--primary"
              disabled={loading}
            >
              {loading ? "Salvando..." : "Salvar"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
