import React from 'react';
import { useAcademicYear } from '../../contexts/AcademicYearContext';
import clsx from 'clsx';

/**
 * Year selector dropdown.
 * Compact version for sidebar; can also be used inline in pages.
 *
 * Props:
 *  - compact: boolean  – renders a small version for collapsed sidebar
 *  - className: string – extra tailwind classes
 */
export function YearSelector({ compact = false, className = '' }) {
  const { academicYear, setAcademicYear, availableYears } = useAcademicYear();

  if (compact) {
    return (
      <div className={clsx('flex items-center justify-center', className)}>
        <button
          onClick={() => {
            const idx = availableYears.indexOf(academicYear);
            const next = availableYears[(idx + 1) % availableYears.length];
            setAcademicYear(next);
          }}
          className="w-10 h-10 flex items-center justify-center rounded-lg text-xs font-bold bg-primary/10 text-primary hover:bg-primary/20 dark:bg-primary/20 dark:text-primary-light dark:hover:bg-primary/30 transition-colors"
          title={`Año académico: ${academicYear}. Click para cambiar.`}
        >
          {String(academicYear).slice(-2)}
        </button>
      </div>
    );
  }

  return (
    <div className={clsx('flex items-center gap-2', className)}>
      <label
        htmlFor="year-selector"
        className="text-xs font-medium text-gray-500 dark:text-gray-400 whitespace-nowrap"
      >
        Año Académico
      </label>
      <select
        id="year-selector"
        value={academicYear}
        onChange={(e) => setAcademicYear(parseInt(e.target.value, 10))}
        className="flex-1 px-2 py-1.5 text-sm rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors"
      >
        {availableYears.map((y) => (
          <option key={y} value={y}>
            {y}
          </option>
        ))}
      </select>
    </div>
  );
}
