import { generatePDFFromHTML, downloadPDFBlob } from './pdfGenerator';

export interface EnrollmentReceiptStudent {
  name: string;
  nivel?: string | null;
  course?: string | null;
}

export interface EnrollmentReceiptData {
  folio: string;
  guardianName: string;
  guardianRun?: string | null;
  guardianEmail?: string | null;
  year: number;
  createdAt: string; // ISO
  students: EnrollmentReceiptStudent[];
}

function formatDate(value: string, locale = 'es-CL') {
  try {
    const d = new Date(value);
    return new Intl.DateTimeFormat(locale, {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(d);
  } catch {
    return value;
  }
}

export function buildEnrollmentReceiptHtml(data: EnrollmentReceiptData): string {
  const { folio, guardianName, guardianRun, guardianEmail, year, createdAt, students } = data;

  const studentRows = (students || [])
    .map((s, idx) => {
      const nivelLabel = s.nivel ? String(s.nivel) : '—';
      const courseLabel = s.course || '—';
      return `
        <tr>
          <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${idx + 1}</td>
          <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${s.name}</td>
          <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${nivelLabel}</td>
          <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${courseLabel}</td>
        </tr>`;
    })
    .join('');

  const createdLabel = formatDate(createdAt);

  return `
  <div style="padding: 12mm; font-family: Arial, Helvetica, sans-serif; color: #111827;">
    <h2 style="text-align:center; margin: 0 0 8px 0; font-size: 18pt;">Comprobante de Matrícula</h2>
    <p style="text-align:center; margin: 0 0 4px 0; font-size: 10pt; color: #374151;">Corporación Educacional Winterhill</p>
    <p style="text-align:center; margin: 0 0 12px 0; font-size: 9pt; color: #6b7280;">Este documento certifica la matrícula para el año académico ${year}.</p>

    <table style="width: 100%; border-collapse: collapse; margin-top: 6mm; font-size: 9pt;">
      <tr>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f9fafb; width: 30%; font-weight: 600;">Folio</td>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${folio}</td>
      </tr>
      <tr>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f9fafb; font-weight: 600;">Fecha y hora de emisión</td>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${createdLabel}</td>
      </tr>
      <tr>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f9fafb; font-weight: 600;">Apoderado</td>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${guardianName}</td>
      </tr>
      <tr>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f9fafb; font-weight: 600;">RUN</td>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${guardianRun || '—'}</td>
      </tr>
      <tr>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f9fafb; font-weight: 600;">Correo de contacto</td>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${guardianEmail || '—'}</td>
      </tr>
      <tr>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f9fafb; font-weight: 600;">Año académico</td>
        <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${year}</td>
      </tr>
    </table>

    <h3 style="margin-top: 10mm; margin-bottom: 4px; font-size: 11pt;">Estudiantes matriculados</h3>
    <table style="width: 100%; border-collapse: collapse; font-size: 9pt;">
      <thead>
        <tr>
          <th style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f3f4f6; text-align:left; width: 8%;">#</th>
          <th style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f3f4f6; text-align:left;">Nombre</th>
          <th style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f3f4f6; text-align:left; width: 15%;">Nivel</th>
          <th style="padding: 6px 10px; border: 1px solid #e5e7eb; background:#f3f4f6; text-align:left; width: 30%;">Curso</th>
        </tr>
      </thead>
      <tbody>
        ${studentRows || '<tr><td colspan="4" style="padding: 6px 10px; border: 1px solid #e5e7eb; text-align:center; color:#6b7280;">Sin estudiantes asociados</td></tr>'}
      </tbody>
    </table>

    <p style="margin-top: 10mm; font-size: 9pt; color:#6b7280;">Este comprobante se genera automáticamente y no requiere firma. Para fines de validación interna, imprima este documento o conserve el archivo PDF. Para cualquier consulta, contáctenos a secretariaadministrativa@winterhillenlinea.cl</p>
  </div>`;
}

export async function generateEnrollmentReceiptPdf(data: EnrollmentReceiptData, action: 'download' | 'preview' = 'download') {
  const htmlContent = buildEnrollmentReceiptHtml(data);
  const blob = await generatePDFFromHTML({
    htmlContent,
    orientation: 'portrait',
    format: 'a4',
    includeHeader: true,
    includeSignatureSection: false,
    metadata: {
      title: 'Comprobante de Matrícula',
      subject: 'Comprobante de Matrícula - Winterhill',
      keywords: 'comprobante, matrícula, winterhill',
    },
  });

  const filename = `comprobante-matricula-${data.folio}.pdf`;
  if (action === 'download') {
    downloadPDFBlob(blob, filename);
  } else {
    // Reutilizamos previewPDFBlob indirectamente mediante una ventana nueva
    const url = URL.createObjectURL(blob);
    window.open(url, '_blank');
  }
}

export function buildEnrollmentFolio(opts: { timestamp?: Date; nivel?: string | null; curso?: string | null }): string {
  const ts = opts.timestamp ?? new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  const year = ts.getFullYear();
  const month = pad(ts.getMonth() + 1);
  const day = pad(ts.getDate());
  const hour = pad(ts.getHours());
  const minute = pad(ts.getMinutes());
  const second = pad(ts.getSeconds());
  const base = `${year}${month}${day}${hour}${minute}${second}`;

  const nivelPart = (opts.nivel || '').toString().trim() || '000';
  const cursoPartRaw = (opts.curso || '').toString().trim();
  const cursoPart = cursoPartRaw
    ? cursoPartRaw
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^A-Za-z0-9]/g, '')
        .slice(0, 6)
        .toUpperCase() || 'CURSO'
    : 'CURSO';

  return `${base}-${nivelPart}-${cursoPart}`;
}
