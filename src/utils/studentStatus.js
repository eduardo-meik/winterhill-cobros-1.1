const STATUS_NORMALIZATION = {
  PENDIENTE: 'PENDIENTE',
  PENDING: 'PENDIENTE',
  MATRICULADO: 'PENDIENTE',
  ACTIVO: 'ACTIVO',
  ACTIVE: 'ACTIVO',
  RETIRADO: 'RETIRADO',
  RETIRED: 'RETIRADO'
};

const STATUS_LABELS = {
  PENDIENTE: 'Pre-Matriculado',
  ACTIVO: 'Confirmado',
  RETIRADO: 'Retirado'
};

const CANONICAL_TO_DB_VALUE = {
  PENDIENTE: 'MATRICULADO',
  ACTIVO: 'ACTIVO',
  RETIRADO: 'RETIRADO'
};

const STATUS_BADGE_CLASSES = {
  PENDIENTE: 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-200',
  ACTIVO: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-200',
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
  { value: CANONICAL_TO_DB_VALUE.PENDIENTE, label: STATUS_LABELS.PENDIENTE },
  { value: CANONICAL_TO_DB_VALUE.ACTIVO, label: STATUS_LABELS.ACTIVO },
  { value: CANONICAL_TO_DB_VALUE.RETIRADO, label: STATUS_LABELS.RETIRADO }
]);

export const deriveStudentStatusFromRecord = (student) => {
  if (!student) return null;
  if (student.fecha_retiro) return 'RETIRADO';
  return resolveStudentStatus(student.estado_std, CANONICAL_TO_DB_VALUE.PENDIENTE) || 'PENDIENTE';
};
