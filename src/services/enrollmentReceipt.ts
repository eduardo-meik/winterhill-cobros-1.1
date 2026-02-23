import { generatePDFFromHTML, downloadPDFBlob } from './pdfGenerator';
import { escapeHtml } from '../utils/html';
import { SCHOOL_INFO } from '../constants/school';

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
      const nivelLabel = s.nivel ? escapeHtml(s.nivel) : '—';
      const courseLabel = s.course ? escapeHtml(s.course) : '—';
      return `
        <tr>
          <td style="padding: 6px 10px; border: 1px solid #e5e7eb; text-align: center;">${idx + 1}</td>
          <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${escapeHtml(s.name)}</td>
          <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${nivelLabel}</td>
          <td style="padding: 6px 10px; border: 1px solid #e5e7eb;">${courseLabel}</td>
        </tr>`;
    })
    .join('');

  const createdLabel = formatDate(createdAt);

  return `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Comprobante de Matrícula</title>
  <style>
    @page {
      size: A4;
      margin: 2cm;
    }
    body {
      font-family: Arial, Helvetica, sans-serif;
      color: #111827;
      margin: 0;
      padding: 0;
      font-size: 10pt;
      line-height: 1.5;
    }
    .header { text-align: center; margin-bottom: 20px; }
    .header h2 { margin: 0 0 8px 0; font-size: 18pt; }
    .header p { margin: 0 0 4px 0; color: #374151; font-size: 10pt; }
    .header .sub { font-size: 9pt; color: #6b7280; margin-bottom: 12px; }
    
    table { width: 100%; border-collapse: collapse; margin-top: 6mm; font-size: 9pt; }
    td, th { padding: 6px 10px; border: 1px solid #e5e7eb; }
    .label-col { background: #f9fafb; font-weight: 600; width: 30%; }
    .header-row th { background: #f3f4f6; text-align: left; }
    .center { text-align: center; }
    
    .footer-note { margin-top: 10mm; font-size: 9pt; color: #6b7280; }
  </style>
</head>
<body>
  <div class="header">
    <h2>Comprobante de Matrícula</h2>
    <p>${SCHOOL_INFO.name}</p>
    <p class="sub">Este documento certifica la matrícula para el año académico ${escapeHtml(year)}.</p>
  </div>

  <table>
    <tr>
      <td class="label-col">Folio</td>
      <td>${escapeHtml(folio)}</td>
    </tr>
    <tr>
      <td class="label-col">Fecha y hora de emisión</td>
      <td>${escapeHtml(createdLabel)}</td>
    </tr>
    <tr>
      <td class="label-col">Apoderado</td>
      <td>${escapeHtml(guardianName)}</td>
    </tr>
    <tr>
      <td class="label-col">RUN</td>
      <td>${guardianRun ? escapeHtml(guardianRun) : '—'}</td>
    </tr>
    <tr>
      <td class="label-col">Correo de contacto</td>
      <td>${guardianEmail ? escapeHtml(guardianEmail) : '—'}</td>
    </tr>
    <tr>
      <td class="label-col">Año académico</td>
      <td>${escapeHtml(year)}</td>
    </tr>
  </table>

  <h3 style="margin-top: 10mm; margin-bottom: 4px; font-size: 11pt;">Estudiantes matriculados</h3>
  <table>
    <thead>
      <tr class="header-row">
        <th style="width: 8%;">#</th>
        <th>Nombre</th>
        <th style="width: 15%;">Nivel</th>
        <th style="width: 30%;">Curso</th>
      </tr>
    </thead>
    <tbody>
      ${studentRows || '<tr><td colspan="4" class="center" style="color:#6b7280;">Sin estudiantes asociados</td></tr>'}
    </tbody>
  </table>

  <p class="footer-note">Este comprobante se genera automáticamente y no requiere firma. Para fines de validación interna, imprima este documento o conserve el archivo PDF. Para cualquier consulta, contáctenos a ${SCHOOL_INFO.email}</p>
</body>
</html>`;
}

export async function generateEnrollmentReceiptPdf(data: EnrollmentReceiptData, action: 'download' | 'preview' = 'download') {
  const htmlContent = buildEnrollmentReceiptHtml(data);
  const blob = await generatePDFFromHTML({
    htmlContent,
    orientation: 'portrait',
    format: 'a4',
    margin: 0, // Dejamos que @page controle los márgenes
    includeHeader: false, // El HTML ya incluye el encabezado
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
    // Release the object URL after a reasonable delay to free memory
    setTimeout(() => URL.revokeObjectURL(url), 60_000);
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
