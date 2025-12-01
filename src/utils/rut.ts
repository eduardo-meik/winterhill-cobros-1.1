// RUT / RUN utilities centralized
export const cleanRut = (run: string) => typeof run === 'string' ? run.replace(/[^0-9kK]/g, '').toUpperCase() : '';
export const normalizeRun = cleanRut;

export const computeDv = (body: string) => {
  let sum = 0; let multiplier = 2;
  for (let i = body.length - 1; i >= 0; i--) {
    sum += parseInt(body[i], 10) * multiplier;
    multiplier = multiplier === 7 ? 2 : multiplier + 1;
  }
  const r = 11 - (sum % 11);
  if (r === 11) return '0';
  if (r === 10) return 'K';
  return String(r);
};

export const validateRun = (raw: string) => {
  const clean = cleanRut(raw);
  if (clean.length < 2) return { valid: false, clean };
  const body = clean.slice(0, -1);
  const dv = clean.slice(-1).toUpperCase();
  if (!/^[0-9]+$/.test(body)) return { valid: false, clean };
  const expected = computeDv(body);
  return { valid: dv === expected, clean, body, dv, expected };
};

export const validateRut = (rut: string) => {
    return validateRun(rut).valid;
};

export const formatRunDisplay = (raw: string) => {
  const clean = cleanRut(raw);
  if (clean.length < 2) return clean;
  const body = clean.slice(0, -1);
  const dv = clean.slice(-1);
  const bodyWithDots = body.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `${bodyWithDots}-${dv}`;
};

export const formatRut = formatRunDisplay;
