export type StatusKey =
  | 'draft'
  | 'submitted'
  | 'approved'
  | 'rejected'
  | 'signed'
  | 'pending';

const STATUS_LABELS: Record<StatusKey, string> = {
  draft: 'Borrador',
  submitted: 'Enviado',
  approved: 'Aprobado',
  rejected: 'Rechazado',
  signed: 'Firmado',
  pending: 'Pendiente',
};

export function getStatusLabel(status: StatusKey | string): string {
  const key = status as StatusKey;
  if (key in STATUS_LABELS) return STATUS_LABELS[key];
  return status;
}
