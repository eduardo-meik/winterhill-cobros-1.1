const EXCEL_EPOCH_UTC_MS = Date.UTC(1899, 11, 30);
const MS_PER_DAY = 24 * 60 * 60 * 1000;

export function excelSerialToDate(serial: number): Date {
  if (!Number.isFinite(serial)) {
    throw new Error('El serial de Excel debe ser un numero finito.');
  }

  const wholeDays = Math.trunc(serial);
  const fractionalDay = serial - wholeDays;
  const wholeMs = wholeDays * MS_PER_DAY;
  const fractionMs = Math.round(fractionalDay * MS_PER_DAY);

  return new Date(EXCEL_EPOCH_UTC_MS + wholeMs + fractionMs);
}
