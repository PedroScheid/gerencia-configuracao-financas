import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import type { Lancamento } from "../types";

function formatCurrency(value: number): string {
  return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

function formatDate(dateStr: string): string {
  const [y, m, d] = dateStr.split("-");
  return `${d}/${m}/${y}`;
}

export interface PdfExportOptions {
  title?: string;
}

export function exportLancamentosToPdf(
  lancamentos: Lancamento[],
  options: PdfExportOptions = {},
): void {
  const title = options.title ?? "Relatório Financeiro";
  const exportDate = new Date().toLocaleDateString("pt-BR");

  const doc = new jsPDF();

  // Title
  doc.setFontSize(18);
  doc.setTextColor(26, 86, 219);
  doc.text(title, 14, 20);

  // Export date
  doc.setFontSize(10);
  doc.setTextColor(100, 100, 100);
  doc.text(`Exportado em: ${exportDate}`, 14, 28);

  // Summary line
  doc.setFontSize(10);
  doc.setTextColor(50, 50, 50);
  doc.text(`Total de registros: ${lancamentos.length}`, 14, 34);

  const tableBody = lancamentos.map((l) => [
    String(l.id),
    l.descricao,
    formatDate(l.data_lancamento),
    formatCurrency(l.valor),
    l.tipo_lancamento === "RECEITA" ? "Receita" : "Despesa",
    l.situacao,
  ]);

  autoTable(doc, {
    startY: 40,
    head: [["#", "Descrição", "Data", "Valor", "Tipo", "Situação"]],
    body: tableBody,
    styles: { fontSize: 9, cellPadding: 3 },
    headStyles: { fillColor: [26, 86, 219], textColor: 255, fontStyle: "bold" },
    alternateRowStyles: { fillColor: [249, 250, 251] },
    columnStyles: {
      0: { halign: "right", cellWidth: 12 },
      2: { halign: "center" },
      3: { halign: "right" },
      4: { halign: "center" },
      5: { halign: "center" },
    },
  });

  const filename = `relatorio-financeiro-${new Date().toISOString().slice(0, 10)}.pdf`;
  doc.save(filename);
}
