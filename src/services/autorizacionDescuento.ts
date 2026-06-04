/**
 * Autorización de Descuento Generator
 * Generates HTML/PDF for discount authorization documents (alternative to Pagaré)
 */

import { escapeHtml } from '../utils/html';
import { SCHOOL_INFO } from '../constants/school';

interface DescuentoInfo {
  tipo?: string;
  porcentaje_descuento?: number;
  monto_total_descuento?: number;
  motivo?: string;
  condiciones?: string;
}

interface AutorizacionParams {
  guardian: any;
  year: number;
  students: any[];
  economic?: any;
  descuentoInfo?: DescuentoInfo;
}

/**
 * Build the authorization payload from guardian, students, and economic data
 */
export function buildAutorizacionPayload({ guardian, year, students, economic, descuentoInfo }: AutorizacionParams) {
  const today = new Date();
  const fechaActual = today.toLocaleDateString('es-CL', { 
    day: 'numeric', 
    month: 'long', 
    year: 'numeric' 
  });

  // Calculate student names list
  const studentNames = students.map(s => s.whole_name || `${s.first_name} ${s.last_name}`).join(', ');
  
  // Format amounts
  const formatCurrency = (amount: number | undefined) => {
    if (!amount) return '$0';
    return new Intl.NumberFormat('es-CL', { 
      style: 'currency', 
      currency: 'CLP',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  const montoMatricula = formatCurrency(economic?.monto_matricula || 0);
  const colegiaturaAnual = formatCurrency(economic?.colegiatura_anual || 0);
  const montoCuota = formatCurrency(economic?.monto_cuota || 0);
  const totalDescuento = formatCurrency(descuentoInfo?.monto_total_descuento || 0);
  const porcentajeDescuento = descuentoInfo?.porcentaje_descuento || 0;

  return {
    // Document metadata
    fecha_actual: fechaActual,
    anio_academico: year,
    
    // Guardian info
    guardian_full_name: `${guardian?.first_name || ''} ${guardian?.last_name || ''}`.trim(),
    guardian_run: guardian?.run || 'N/A',
    guardian_email: guardian?.email || 'N/A',
    guardian_phone: guardian?.phone || 'N/A',
    guardian_address: guardian?.address || 'N/A',
    
    // Students info
    student_names: studentNames,
    student_count: students.length,
    
    // Economic info
    monto_matricula: montoMatricula,
    colegiatura_anual: colegiaturaAnual,
    cantidad_cuotas: economic?.cantidad_cuotas || 10,
    monto_cuota: montoCuota,
    dia_vencimiento: economic?.dia_vencimiento || 5,
    
    // Discount info
    tipo_descuento: descuentoInfo?.tipo || 'Descuento por Planilla',
    porcentaje_descuento: porcentajeDescuento,
    monto_total_descuento: totalDescuento,
    motivo_descuento: descuentoInfo?.motivo || 'Beneficio laboral',
    condiciones: descuentoInfo?.condiciones || 'Descuento aplicable mientras se mantenga relación laboral',
  };
}

/**
 * Generate HTML for Autorización de Descuento
 */
export function generateAutorizacionHTML(payload: any) {
  return `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Autorización de Descuento por Planilla</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      max-width: 800px;
      margin: 0 auto;
      padding: 40px 20px;
      color: #333;
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
      border-bottom: 2px solid #003366;
      padding-bottom: 20px;
    }
    .logo-section {
      margin-bottom: 15px;
    }
    .school-name {
      font-size: 24px;
      font-weight: bold;
      color: #003366;
      margin: 10px 0;
    }
    .doc-title {
      font-size: 20px;
      font-weight: bold;
      color: #003366;
      margin: 20px 0 10px 0;
      text-transform: uppercase;
    }
    .doc-subtitle {
      font-size: 14px;
      color: #666;
      margin-bottom: 10px;
    }
    .section {
      margin: 25px 0;
    }
    .section-title {
      font-size: 16px;
      font-weight: bold;
      color: #003366;
      margin-bottom: 10px;
      border-bottom: 1px solid #ccc;
      padding-bottom: 5px;
    }
    .info-row {
      margin: 8px 0;
      display: flex;
      align-items: baseline;
    }
    .info-label {
      font-weight: bold;
      min-width: 180px;
      color: #555;
    }
    .info-value {
      flex: 1;
    }
    .highlight-box {
      background-color: #f0f8ff;
      border: 2px solid #003366;
      border-radius: 8px;
      padding: 20px;
      margin: 20px 0;
    }
    .terms {
      font-size: 13px;
      line-height: 1.8;
      margin: 20px 0;
      text-align: justify;
    }
    .signature-section {
      margin-top: 60px;
      page-break-inside: avoid;
    }
    .signature-box {
      border-top: 2px solid #333;
      padding-top: 10px;
      margin-top: 80px;
      width: 60%;
    }
    .signature-label {
      font-size: 12px;
      color: #666;
    }
    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid #ccc;
      font-size: 11px;
      color: #666;
      text-align: center;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 15px 0;
    }
    th, td {
      border: 1px solid #ddd;
      padding: 10px;
      text-align: left;
    }
    th {
      background-color: #003366;
      color: white;
      font-weight: bold;
    }
    .amount {
      font-weight: bold;
      color: #003366;
      font-size: 16px;
    }
    @media print {
      body {
        padding: 20px;
      }
      .signature-box {
        margin-top: 60px;
      }
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo-section">
      <!-- Logo would go here -->
    </div>
    <div class="school-name">CORPORACIÓN EDUCACIONAL WINTERHILL</div>
    <div class="doc-title">Autorización de Descuento por Planilla</div>
    <div class="doc-subtitle">Año Académico ${escapeHtml(payload.anio_academico)}</div>
    <div class="doc-subtitle">Fecha: ${escapeHtml(payload.fecha_actual)}</div>
  </div>

  <!-- Información del Apoderado -->
  <div class="section">
    <div class="section-title">📋 DATOS DEL APODERADO</div>
    <div class="info-row">
      <span class="info-label">Nombre Completo:</span>
      <span class="info-value">${escapeHtml(payload.guardian_full_name)}</span>
    </div>
    <div class="info-row">
      <span class="info-label">RUN:</span>
      <span class="info-value">${escapeHtml(payload.guardian_run)}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Email:</span>
      <span class="info-value">${escapeHtml(payload.guardian_email)}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Teléfono:</span>
      <span class="info-value">${escapeHtml(payload.guardian_phone)}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Dirección:</span>
      <span class="info-value">${escapeHtml(payload.guardian_address)}</span>
    </div>
  </div>

  <!-- Información de los Estudiantes -->
  <div class="section">
    <div class="section-title">👨‍🎓 ALUMNO(S) BENEFICIADO(S)</div>
    <div class="info-row">
      <span class="info-label">Nombre(s):</span>
      <span class="info-value">${escapeHtml(payload.student_names)}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Total de alumnos:</span>
      <span class="info-value">${escapeHtml(payload.student_count)}</span>
    </div>
  </div>

  <!-- Detalle del Descuento -->
  <div class="highlight-box">
    <div class="section-title">💰 DETALLE DEL DESCUENTO AUTORIZADO</div>
    
    <table>
      <tr>
        <th>Concepto</th>
        <th>Monto Original</th>
      </tr>
      <tr>
        <td>Matrícula</td>
        <td>${escapeHtml(payload.monto_matricula)}</td>
      </tr>
      <tr>
        <td>Colegiatura Anual</td>
        <td>${escapeHtml(payload.colegiatura_anual)}</td>
      </tr>
      <tr>
        <td>Monto por Cuota (${escapeHtml(payload.cantidad_cuotas)} cuotas)</td>
        <td>${escapeHtml(payload.monto_cuota)}</td>
      </tr>
    </table>

    <div class="info-row" style="margin-top: 20px;">
      <span class="info-label">Tipo de Descuento:</span>
      <span class="info-value">${escapeHtml(payload.tipo_descuento)}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Porcentaje de Descuento:</span>
      <span class="info-value amount">${escapeHtml(payload.porcentaje_descuento)}%</span>
    </div>
    <div class="info-row">
      <span class="info-label">Monto Total Descuento:</span>
      <span class="info-value amount">${escapeHtml(payload.monto_total_descuento)}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Motivo:</span>
      <span class="info-value">${escapeHtml(payload.motivo_descuento)}</span>
    </div>
  </div>

  <!-- Términos y Condiciones -->
  <div class="section">
    <div class="section-title">📜 TÉRMINOS Y CONDICIONES</div>
    <div class="terms">
      <p><strong>1. VIGENCIA:</strong> El descuento autorizado será aplicado a partir de la fecha de firma de este documento y tendrá vigencia durante el año académico ${escapeHtml(payload.anio_academico)}.</p>
      
      <p><strong>2. CONDICIONES:</strong> ${escapeHtml(payload.condiciones)}</p>
      
      <p><strong>3. FORMA DE APLICACIÓN:</strong> El descuento será aplicado mensualmente mediante descuento directo de planilla de remuneraciones del apoderado titular.</p>
      
      <p><strong>4. VENCIMIENTO:</strong> Las cuotas vencerán el día ${escapeHtml(payload.dia_vencimiento)} de cada mes.</p>
      
      <p><strong>5. TERMINACIÓN:</strong> El beneficio de descuento terminará automáticamente en caso de:</p>
      <ul>
        <li>Término de la relación laboral con la Corporación Educacional Winterhill</li>
        <li>Retiro voluntario del alumno del establecimiento</li>
        <li>Incumplimiento de las obligaciones contractuales</li>
      </ul>
      
      <p><strong>6. OBLIGACIONES:</strong> En caso de término anticipado del beneficio, el apoderado se compromete a regularizar los montos pendientes mediante pago directo al colegio dentro de los plazos establecidos.</p>
      
      <p><strong>7. DECLARACIÓN:</strong> El apoderado declara estar en conocimiento y conformidad con todos los términos y condiciones establecidos en este documento, y autoriza expresamente el descuento mensual de su remuneración.</p>
    </div>
  </div>

  <!-- Firma -->
  <div class="signature-section">
    <p style="margin-bottom: 40px;">
      En constancia de lo anterior, firma el apoderado:
    </p>
    
    <div class="signature-box">
      <div style="margin-bottom: 10px;">_______________________________________</div>
      <div><strong>${escapeHtml(payload.guardian_full_name)}</strong></div>
      <div class="signature-label">RUN: ${escapeHtml(payload.guardian_run)}</div>
      <div class="signature-label">Firma y Fecha</div>
    </div>
  </div>

  <!-- Footer -->
  <div class="footer">
    <p><strong>${SCHOOL_INFO.name}</strong></p>
    <p>Dirección: ${SCHOOL_INFO.address} | Teléfono: ${SCHOOL_INFO.phone} | Email: ${SCHOOL_INFO.email}</p>
    <p>Este documento es de carácter legal y debe ser conservado por el apoderado.</p>
  </div>
</body>
</html>
  `.trim();
}

/**
 * Helper to create simple text-based rendering (fallback)
 */
export function renderAutorizacionSimple(payload: any) {
  return `
AUTORIZACIÓN DE DESCUENTO POR PLANILLA
Corporación Educacional Winterhill
Año Académico ${payload.anio_academico}
Fecha: ${payload.fecha_actual}

APODERADO: ${payload.guardian_full_name}
RUN: ${payload.guardian_run}

ALUMNO(S): ${payload.student_names}

DESCUENTO AUTORIZADO:
- Tipo: ${payload.tipo_descuento}
- Porcentaje: ${payload.porcentaje_descuento}%
- Monto Total: ${payload.monto_total_descuento}
- Motivo: ${payload.motivo_descuento}

El apoderado autoriza el descuento mensual de planilla conforme a los términos establecidos.

_______________________
Firma del Apoderado
${payload.guardian_full_name}
RUN: ${payload.guardian_run}
  `.trim();
}
