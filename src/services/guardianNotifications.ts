import { sendEmailViaFunction } from './email';
import type { GuardianRecord, GuardianLinkedStudent, EnrollmentRecord, EnrollmentDocumentRecord } from './matricula';

interface SendGuardianCompletionEmailOptions {
  guardian: GuardianRecord | null;
  students: GuardianLinkedStudent[];
  enrollment?: EnrollmentRecord | null;
  documents?: EnrollmentDocumentRecord[];
  year?: number | string | null;
  portalUrl?: string;
}

export async function sendGuardianCompletionEmail(options: SendGuardianCompletionEmailOptions) {
  const { guardian, students, enrollment, documents, year, portalUrl } = options;

  if (!guardian?.email) {
    throw new Error('No hay un correo electrónico registrado para el apoderado.');
  }

  const guardianName = guardian.first_name || guardian.last_name || guardian.run || 'Apoderado';
  const listItems = (students || [])
    .filter((student) => Boolean(student))
    .map((student) => {
      const displayName = student.whole_name || [student.first_name, student.last_name].filter(Boolean).join(' ').trim() || 'Estudiante sin nombre';
      const course = student.curso_label || student.grade || '';
      return `<li>${displayName}${course ? ` — ${course}` : ''}</li>`;
    })
    .join('');

  const yearLabel = year ?? enrollment?.year ?? new Date().getFullYear();
  const documentCount = documents?.length ?? 0;
  const portalLink = portalUrl || (typeof window !== 'undefined' ? `${window.location.origin}/apoderado/matricula` : undefined);

  const summary = [
    listItems ? `<p>Quedaron registrados los siguientes estudiantes:</p><ul>${listItems}</ul>` : '',
    documentCount
      ? `<p>Se generaron ${documentCount} documento(s) en el portal. Puedes descargarlos o revisarlos cuando lo necesites.</p>`
      : '<p>Ya puedes ingresar al Portal de Apoderados para revisar tus documentos y pagos.</p>',
    portalLink
      ? `<p>Accede directamente desde <a href="${portalLink}" target="_blank" rel="noopener noreferrer">este enlace</a>.</p>`
      : '',
  ]
    .filter(Boolean)
    .join('\n');

  const html = `
    <p>Hola ${guardianName},</p>
    <p>Confirmamos que tu proceso de matrícula ${yearLabel} está finalizado con éxito.</p>
    ${summary}
    <p>Si necesitas apoyo adicional puedes escribirnos a secretaria@winterhill.cl o contactarte con el equipo de admisión.</p>
    <p>Saludos cordiales,<br />Corporación Educacional Winterhill</p>
  `;

  const subject = `Confirmación de matrícula ${yearLabel} - Winterhill`;

  return sendEmailViaFunction({
    to: guardian.email,
    subject,
    html,
    type: 'other',
    related_id: enrollment?.id,
  });
}
