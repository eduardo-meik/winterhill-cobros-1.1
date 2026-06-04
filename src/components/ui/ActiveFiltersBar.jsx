import React from 'react';
import clsx from 'clsx';

/**
 * Displays active (non-default) filters as removable chips.
 *
 * Props:
 *  - filters: Array<{ key: string, label: string, value: string, onRemove: () => void }>
 *  - onClearAll: () => void
 *  - className: string
 *  - yearLabel: string – always-visible read-only chip showing the active academic year
 */
export function ActiveFiltersBar({ filters = [], onClearAll, className = '', yearLabel }) {
  const active = filters.filter(f => f.value != null);
  if (!active.length && !yearLabel) return null;

  return (
    <div className={clsx('flex flex-wrap items-center gap-2 px-4 py-2 bg-gray-50 dark:bg-dark-hover/50 border-b border-gray-100 dark:border-gray-800', className)}>
      {yearLabel && (
        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-primary/10 text-primary dark:bg-primary/20 dark:text-primary-light">
          Año {yearLabel}
        </span>
      )}
      {active.map(f => (
        <span
          key={f.key}
          className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-200"
        >
          <span className="text-gray-500 dark:text-gray-400">{f.label}:</span> {f.value}
          <button
            onClick={f.onRemove}
            className="ml-0.5 hover:text-red-500 transition-colors"
            aria-label={`Quitar filtro ${f.label}`}
          >
            ×
          </button>
        </span>
      ))}
      {active.length > 0 && onClearAll && (
        <button
          onClick={onClearAll}
          className="text-xs text-gray-500 dark:text-gray-400 hover:text-primary transition-colors underline"
        >
          Limpiar filtros
        </button>
      )}
    </div>
  );
}
