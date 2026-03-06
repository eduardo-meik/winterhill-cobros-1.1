/**
 * Centralized color tokens for status badges, pills, and indicators.
 * Prevents hard-coded Tailwind color classes scattered across components.
 */

export const STATUS_COLORS = {
  // Enrollment / student statuses
  confirmed:      { bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-200' },
  completed:      { bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-200' },
  approved:       { bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-200' },
  signed:         { bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-200' },
  submitted:      { bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-200' },
  pre_matriculado:{ bg: 'bg-blue-100',  text: 'text-blue-800',  border: 'border-blue-200' },
  generated:      { bg: 'bg-blue-100',  text: 'text-blue-800',  border: 'border-blue-200' },
  pending:        { bg: 'bg-amber-100', text: 'text-amber-800', border: 'border-amber-200' },
  draft:          { bg: 'bg-amber-100', text: 'text-amber-800', border: 'border-amber-200' },
  rejected:       { bg: 'bg-red-100',   text: 'text-red-800',   border: 'border-red-200' },

  // Payment statuses
  paid:           { bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-200' },
  overdue:        { bg: 'bg-red-100',   text: 'text-red-800',   border: 'border-red-200' },
  partial:        { bg: 'bg-yellow-100',text: 'text-yellow-800',border: 'border-yellow-200' },
} as const;

/** Safe lookup — returns neutral gray for unknown statuses */
export function getStatusColor(status: string) {
  const key = status?.toLowerCase().replace(/[\s-]/g, '_');
  return (
    (STATUS_COLORS as Record<string, (typeof STATUS_COLORS)[keyof typeof STATUS_COLORS]>)[key] ?? {
      bg: 'bg-gray-100',
      text: 'text-gray-800',
      border: 'border-gray-200',
    }
  );
}

/** Returns a ready-to-use className string for a status badge */
export function statusBadgeClass(status: string) {
  const c = getStatusColor(status);
  return `${c.bg} ${c.text} ${c.border}`;
}
