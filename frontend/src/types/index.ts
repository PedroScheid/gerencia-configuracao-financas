export interface Usuario {
  id: number;
  nome: string;
  login: string;
  situacao?: string;
}

export type TipoLancamento = "RECEITA" | "DESPESA";
export type Situacao = "ATIVO" | "INATIVO";

export interface Lancamento {
  id: number;
  descricao: string;
  data_lancamento: string;
  valor: number;
  tipo_lancamento: TipoLancamento;
  situacao: Situacao;
}

export interface LancamentoFormData {
  descricao: string;
  data_lancamento: string;
  valor: string;
  tipo_lancamento: TipoLancamento;
  situacao: Situacao;
}

export interface AuthContextType {
  usuario: Usuario | null;
  token: string | null;
  login: (login: string, senha: string) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}
