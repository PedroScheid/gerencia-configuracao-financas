import { describe, it, expect, vi, beforeEach } from "vitest";
import type { Lancamento } from "../types";

// ── Hoist mock functions so they're available inside vi.mock factories ────────

const { mockSave, mockText, mockSetFontSize, mockSetTextColor, mockAutoTable } =
  vi.hoisted(() => ({
    mockSave: vi.fn(),
    mockText: vi.fn(),
    mockSetFontSize: vi.fn(),
    mockSetTextColor: vi.fn(),
    mockAutoTable: vi.fn(),
  }));

// ── Mock jsPDF and jspdf-autotable ────────────────────────────────────────────

vi.mock("jspdf", () => {
  return {
    default: vi.fn().mockImplementation(() => ({
      setFontSize: mockSetFontSize,
      setTextColor: mockSetTextColor,
      text: mockText,
      save: mockSave,
    })),
  };
});

vi.mock("jspdf-autotable", () => ({
  default: mockAutoTable,
}));

// Import the service AFTER mocks are set up
import { exportLancamentosToPdf } from "../services/pdfExportService";

// ── Helpers ───────────────────────────────────────────────────────────────────

function makeLancamento(overrides: Partial<Lancamento> = {}): Lancamento {
  return {
    id: 1,
    descricao: "Salário",
    data_lancamento: "2026-01-05",
    valor: 5000,
    tipo_lancamento: "RECEITA",
    situacao: "ATIVO",
    ...overrides,
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("exportLancamentosToPdf", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // Test 32
  it("calls doc.save to generate the PDF file", () => {
    exportLancamentosToPdf([makeLancamento()]);
    expect(mockSave).toHaveBeenCalledTimes(1);
  });

  // Test 33
  it("saves the PDF with a filename containing the current date", () => {
    const today = new Date().toISOString().slice(0, 10);
    exportLancamentosToPdf([makeLancamento()]);
    const filename = mockSave.mock.calls[0][0] as string;
    expect(filename).toContain(today);
  });

  // Test 34
  it("calls autoTable with the correct header columns", () => {
    exportLancamentosToPdf([makeLancamento()]);
    const tableOptions = mockAutoTable.mock.calls[0][1] as {
      head: string[][];
      body: string[][];
    };
    expect(tableOptions.head[0]).toEqual([
      "#",
      "Descrição",
      "Data",
      "Valor",
      "Tipo",
      "Situação",
    ]);
  });

  // Test 35
  it("includes one row per lancamento in the PDF body", () => {
    const lancamentos = [
      makeLancamento(),
      makeLancamento({ id: 2, descricao: "Aluguel" }),
    ];
    exportLancamentosToPdf(lancamentos);
    const tableOptions = mockAutoTable.mock.calls[0][1] as {
      body: string[][];
    };
    expect(tableOptions.body).toHaveLength(2);
  });

  // Test 36
  it("uses the custom title passed via options", () => {
    exportLancamentosToPdf([makeLancamento()], { title: "Meu Relatório" });
    const textCalls = mockText.mock.calls.map((c) => c[0]);
    expect(textCalls).toContain("Meu Relatório");
  });

  // Test 37
  it("defaults to 'Relatório Financeiro' when no title is provided", () => {
    exportLancamentosToPdf([makeLancamento()]);
    const textCalls = mockText.mock.calls.map((c) => c[0]);
    expect(textCalls).toContain("Relatório Financeiro");
  });

  // Test 38
  it("works with an empty lancamentos array (generates PDF with no rows)", () => {
    exportLancamentosToPdf([]);
    expect(mockSave).toHaveBeenCalledTimes(1);
    const tableOptions = mockAutoTable.mock.calls[0][1] as { body: string[][] };
    expect(tableOptions.body).toHaveLength(0);
  });

  // Test 39
  it("maps RECEITA to 'Receita' in the table body", () => {
    exportLancamentosToPdf([makeLancamento({ tipo_lancamento: "RECEITA" })]);
    const tableOptions = mockAutoTable.mock.calls[0][1] as { body: string[][] };
    const firstRow = tableOptions.body[0];
    expect(firstRow[4]).toBe("Receita");
  });

  // Test 40
  it("maps DESPESA to 'Despesa' in the table body", () => {
    exportLancamentosToPdf([
      makeLancamento({ tipo_lancamento: "DESPESA", descricao: "Aluguel" }),
    ]);
    const tableOptions = mockAutoTable.mock.calls[0][1] as { body: string[][] };
    const firstRow = tableOptions.body[0];
    expect(firstRow[4]).toBe("Despesa");
  });
});
