import React, { createContext, useContext, useState, useCallback } from 'react';

const STORAGE_KEY = 'winterhill_academic_year';

/**
 * Get the default academic year.
 * Uses localStorage if available, otherwise defaults to current calendar year.
 */
function getDefaultYear() {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const parsed = parseInt(stored, 10);
      if (!isNaN(parsed) && parsed >= 2020 && parsed <= 2100) return parsed;
    }
  } catch { /* ignore */ }
  return new Date().getFullYear();
}

/**
 * Available academic years for the selector.
 * From 2024 up to current year + 1 (descending).
 */
function getAvailableYears() {
  const current = new Date().getFullYear();
  const years = [];
  for (let y = current + 1; y >= 2024; y--) {
    years.push(y);
  }
  return years;
}

const AcademicYearContext = createContext(undefined);

export function AcademicYearProvider({ children }) {
  const [academicYear, setAcademicYearState] = useState(getDefaultYear);

  const setAcademicYear = useCallback((year) => {
    const y = typeof year === 'string' ? parseInt(year, 10) : year;
    if (!isNaN(y) && y >= 2020 && y <= 2100) {
      setAcademicYearState(y);
      try {
        localStorage.setItem(STORAGE_KEY, String(y));
      } catch {
        // ignore storage errors
      }
    }
  }, []);

  const availableYears = getAvailableYears();

  return (
    <AcademicYearContext.Provider value={{ academicYear, setAcademicYear, availableYears }}>
      {children}
    </AcademicYearContext.Provider>
  );
}

/**
 * Hook to access the current academic year and setter.
 * @returns {{ academicYear: number, setAcademicYear: (year: number) => void, availableYears: number[] }}
 */
export function useAcademicYear() {
  const ctx = useContext(AcademicYearContext);
  if (!ctx) {
    throw new Error('useAcademicYear must be used within an AcademicYearProvider');
  }
  return ctx;
}
