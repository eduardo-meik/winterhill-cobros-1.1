const MIN_ACADEMIC_YEAR = 2020;
const MAX_ACADEMIC_YEAR = 2100;

function normalizeYear(value) {
  const parsed = Number.parseInt(String(value).trim(), 10);
  if (!Number.isInteger(parsed)) return null;
  if (parsed < MIN_ACADEMIC_YEAR || parsed > MAX_ACADEMIC_YEAR) return null;
  return parsed;
}

export function getCurrentCalendarYear() {
  return new Date().getFullYear();
}

function parseConfiguredYears(value) {
  if (!value || typeof value !== 'string') return [];

  return Array.from(
    new Set(
      value
        .split(',')
        .map((entry) => normalizeYear(entry))
        .filter((year) => year !== null)
    )
  ).sort((left, right) => right - left);
}

export function getConfiguredActiveAcademicYears() {
  const rawValue = typeof import.meta !== 'undefined'
    ? import.meta.env?.VITE_ACTIVE_ACADEMIC_YEARS
    : undefined;

  return parseConfiguredYears(rawValue);
}

export function getDefaultActiveAcademicYears() {
  const currentYear = getCurrentCalendarYear();
  return [currentYear + 1, currentYear];
}

export function getActiveAcademicYears() {
  const configuredYears = getConfiguredActiveAcademicYears();
  return configuredYears.length ? configuredYears : getDefaultActiveAcademicYears();
}

export function isAcademicYearActive(year) {
  const normalizedYear = normalizeYear(year);
  if (normalizedYear === null) return false;
  return getActiveAcademicYears().includes(normalizedYear);
}

export function getAvailableAcademicYears() {
  const currentYear = getCurrentCalendarYear();
  const years = new Set(getActiveAcademicYears());

  for (let year = currentYear + 1; year >= 2024; year -= 1) {
    years.add(year);
  }

  return Array.from(years).sort((left, right) => right - left);
}