import { generatePDFFromHTML, previewPDFBlob, downloadPDFBlob } from './pdfGenerator';

export interface ReceiptData {
  feeId: string;
  studentName: string;
  courseName?: string | null;
  numeroCuota?: number | null;
  yearAcademico?: number | null;
  amount: number;
  paymentDate: string; // ISO or YYYY-MM-DD
  paymentMethod: string;
  movBancario?: string | null;
  notes?: string | null;
  cashierName?: string | null;
}

function formatCurrency(value: number, locale = 'es-CL', currency = 'CLP') {
  try {
    return new Intl.NumberFormat(locale, { style: 'currency', currency }).format(value);
  } catch {
    // Fallback without currency
    return `$${Number(value || 0).toLocaleString('es-CL')}`;
  }
}

function formatDate(value: string, locale = 'es-CL') {
  try {
    const d = new Date(value);
    return new Intl.DateTimeFormat(locale).format(d);
  } catch {
    return value;
  }
}

export function buildReceiptEmailHtml(data: ReceiptData): string {
  const {
    studentName,
    courseName,
    numeroCuota,
    yearAcademico,
    amount,
    paymentDate,
    paymentMethod,
    movBancario,
    notes,
    cashierName,
  } = data;

  const rows = [
    { label: 'Alumno', value: studentName },
    { label: 'Curso', value: courseName || 'No disponible' },
    { label: 'Cuota', value: numeroCuota != null ? `N° ${numeroCuota}` : 'No especificado' },
    { label: 'Año académico', value: yearAcademico != null ? String(yearAcademico) : 'No especificado' },
    { label: 'Monto pagado', value: formatCurrency(amount) },
    { label: 'Fecha de pago', value: formatDate(paymentDate) },
    { label: 'Método de pago', value: paymentMethod },
    { label: 'Movimiento bancario', value: movBancario || '—' },
    { label: 'Notas', value: notes || '—' },
    { label: 'Atendido por', value: cashierName || '—' },
  ];

  const tableRows = rows
    .map(
      (r) => `
        <tr>
          <td style="padding: 8px 12px; border: 1px solid #e5e7eb; background:#f9fafb; width: 40%; font-weight: 600;">${r.label}</td>
          <td style="padding: 8px 12px; border: 1px solid #e5e7eb;">${String(r.value)}</td>
        </tr>`
    )
    .join('');

  return `
  <div style="padding: 12mm; font-family: Arial, Helvetica, sans-serif; color: #000;">
    <h2 style="text-align:center; margin: 0 0 8px 0; font-size: 18pt;">Comprobante de Pago</h2>
    <p style="text-align:center; margin: 0 0 16px 0; font-size: 10pt; color: #374151;">Corporación Educacional Winterhill</p>
    <p style="text-align:center; margin: 0 0 16px 0; font-size: 9pt; color: #6b7280;">Estimad@ apoderad@, adjuntamos el comprobante de su pago.</p>

    <table style="width: 100%; border-collapse: collapse; margin-top: 6mm;">
      ${tableRows}
    </table>

    <p style="margin-top: 10mm; font-size: 9pt; color:#6b7280;">Este comprobante se genera automáticamente y no requiere firma. Para fines de validación interna, imprima este documento. Para cualquier consulta, contáctenos a secretariaadministrativa@winterhillenlinea.cl</p>
  </div>`;
}

export async function generateReceiptPdf(data: ReceiptData, action: 'preview' | 'download' = 'preview') {
  const htmlContent = buildReceiptEmailHtml(data);
  const blob = await generatePDFFromHTML({
    htmlContent,
    orientation: 'portrait',
    format: 'a4',
    includeHeader: true,
    includeSignatureSection: false,
    metadata: {
      title: 'Recibo de Pago',
      subject: 'Recibo de Pago - Winterhill',
      keywords: 'recibo, pago, winterhill',
    }
  });

  const filename = `recibo-${data.feeId || Date.now()}.pdf`;
  if (action === 'download') {
    downloadPDFBlob(blob, filename);
  } else {
    previewPDFBlob(blob);
  }
}
