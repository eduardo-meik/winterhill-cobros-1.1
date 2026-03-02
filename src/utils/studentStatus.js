// DB values: PRE_MATRICULADO, CONFIRMADO, CURSANDO, RETIRADO
// These map directly to their meaning — no indirection needed.

const STATUS_NORMALIZATION = {
  PRE_MATRICULADO: 'PRE_MATRICULADO',
  CONFIRMADO: 'CONFIRMADO',
  CURSANDO: 'CURSANDO',
  RETIRADO: 'RETIRADO',
  // Legacy aliases (backward compat for any cached/stale data)
  MATRICULADO: 'CONFIRMADO',
  ACTIVO: 'CURSANDO',
  PENDIENTE: 'PRE_MATRICULADO',
  PENDING: 'PRE_MATRICULADO',
  ACTIVE: 'CURSANDO',
  RETIRED: 'RETIRADO'
};

const STATUS_LABELS = {
  PRE_MATRICULADO: 'Pre-Matriculado',
  CONFIRMADO: 'Confirmado',
  CURSANDO: 'Cursando',
  RETIRADO: 'Retirado'
};

const STATUS_BADGE_CLASSES = {
  PRE_MATRICULADO: 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-200',
  CONFIRMADO: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-200',
  CURSANDO: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-200',
  RETIRADO: 'bg-rose-100 text-rose-800 dark:bg-rose-900/30 dark:text-rose-200',
  DEFAULT: 'bg-gray-100 text-gray-600 dark:bg-gray-800/50 dark:text-gray-300'
};

const toKey = (value) => {
  if (!value) return null;
  return String(value).trim().toUpperCase();
};

export const resolveStudentStatus = (value, fallbackValue = null) => {
  const normalized = STATUS_NORMALIZATION[toKey(value)] || null;
  if (normalized) return normalized;
  if (fallbackValue !== null && fallbackValue !== undefined) {
    return STATUS_NORMALIZATION[toKey(fallbackValue)] || null;
  }
  return null;
};

export const getStudentStatusLabel = (value, fallbackValue = null) => {
  const resolved = resolveStudentStatus(value, fallbackValue);
  if (!resolved) return 'Sin estado';
  return STATUS_LABELS[resolved] || 'Sin estado';
};

export const getStudentStatusBadgeClass = (value, fallbackValue = null) => {
  const resolved = resolveStudentStatus(value, fallbackValue);
  if (!resolved) return STATUS_BADGE_CLASSES.DEFAULT;
  return STATUS_BADGE_CLASSES[resolved] || STATUS_BADGE_CLASSES.DEFAULT;
};

export const getStudentStatusOptions = () => ([
  { value: 'PRE_MATRICULADO', label: STATUS_LABELS.PRE_MATRICULADO },
  { value: 'CONFIRMADO', label: STATUS_LABELS.CONFIRMADO },
  { value: 'CURSANDO', label: STATUS_LABELS.CURSANDO },
  { value: 'RETIRADO', label: STATUS_LABELS.RETIRADO }
]);

export const deriveStudentStatusFromRecord = (student) => {
  if (!student) return null;
  if (student.fecha_retiro) return 'RETIRADO';
  return resolveStudentStatus(student.estado_std, 'PRE_MATRICULADO') || 'PRE_MATRICULADO';
};
