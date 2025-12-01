// RUT / RUN utilities centralized

// User requested function
export const cleanRut = (run: string) => run.replace(/[^0-9kK]/g, '').toUpperCase();

export const parseRut = (input: string): { body: string; dv: string } | null => {
  // Check for invalid characters strictly (only allow numbers, k, K, dots, hyphens, spaces)
  if (/[^0-9kK\.\-\s]/.test(input)) return null;

  const clean = cleanRut(input);
  if (clean.length < 2) return null;
  const body = clean.slice(0, -1);
  const dv = clean.slice(-1);
  if (!/^\d+$/.test(body)) return null;
  return { body, dv };
};

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

// User requested function: "Coloca puntos y guion en formato XX.XXX.XXX-Y"
export const normalizeRut = (input: string): string | null => {
  const parsed = parseRut(input);
  if (!parsed) return null;

  const { body, dv } = parsed;
  const bodyWithDots = body.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `${bodyWithDots}-${dv}`;
};

// User requested function: "isValidRut(input: string): boolean (usa normalizeRut + cálculo de DV)."
export const isValidRut = (input: string): boolean => {
  const parsed = parseRut(input);
  if (!parsed) return false;
  const { body, dv } = parsed;
  const expected = computeDv(body);
  return dv === expected;
};


// Backward compatibility
export const normalizeRun = (run: string) => cleanRut(run);

export const validateRun = (raw: string) => {
  const clean = cleanRut(raw);
  if (clean.length < 2) return { valid: false, clean };
  const body = clean.slice(0, -1);
  const dv = clean.slice(-1).toUpperCase();
  if (!/^[0-9]+$/.test(body)) return { valid: false, clean };
  const expected = computeDv(body);
  return { valid: dv === expected, clean, body, dv, expected };
};

export const formatRunDisplay = (raw: string) => {
  const norm = normalizeRut(raw);
  return norm || raw;
};
