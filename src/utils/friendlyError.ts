/**
 * Maps raw Supabase / JS error messages to user-friendly Spanish strings.
 * Falls back to a generic message when the pattern is unknown.
 */

const PATTERNS: Array<[RegExp, string]> = [
  // Auth
  [/invalid login credentials/i, 'Correo o contraseña incorrectos.'],
  [/email not confirmed/i, 'Debe confirmar su correo electrónico antes de iniciar sesión.'],
  [/user already registered/i, 'Ya existe una cuenta con este correo.'],
  [/jwt expired/i, 'Su sesión ha expirado. Por favor inicie sesión nuevamente.'],
  [/jwt claim is invalid/i, 'Su sesión no es válida. Por favor inicie sesión nuevamente.'],
  [/email rate limit exceeded/i, 'Demasiados intentos. Intente de nuevo en unos minutos.'],
  [/signup is disabled/i, 'El registro de cuentas no está habilitado.'],

  // RLS / permissions
  [/row.level security/i, 'No tiene permisos para realizar esta acción.'],
  [/permission denied/i, 'No tiene permisos para realizar esta acción.'],

  // Constraints
  [/duplicate key.*unique constraint/i, 'Este registro ya existe.'],
  [/violates foreign key/i, 'El registro referenciado no existe.'],
  [/violates check constraint/i, 'Los datos ingresados no son válidos.'],
  [/not-null constraint/i, 'Faltan campos obligatorios.'],

  // PostgREST
  [/PGRST116|multiple.*rows returned|no rows returned/i, 'No se encontró el registro solicitado.'],
  [/does not exist/i, 'Recurso no disponible. Contacte al administrador.'],

  // Network / timeout
  [/statement timeout/i, 'La operación tardó demasiado. Intente de nuevo.'],
  [/request timeout/i, 'No se pudo conectar al servidor. Verifique su conexión.'],
  [/fetch.*failed|network/i, 'Error de conexión. Verifique su internet e intente de nuevo.'],
  [/edge function/i, 'Error en el servicio. Intente de nuevo más tarde.'],

  // PDF service
  [/remote pdf service/i, 'Error al generar el documento PDF. Intente de nuevo.'],
];

/**
 * Translate a raw error message into a user-friendly Spanish string.
 * @param error  — Error object, string, or anything with a `.message`
 * @param fallback — fallback message when no pattern matches
 */
export function friendlyError(
  error: unknown,
  fallback = 'Ha ocurrido un error inesperado. Intente de nuevo.',
): string {
  const raw =
    typeof error === 'string'
      ? error
      : error && typeof error === 'object' && 'message' in error
        ? String((error as { message: unknown }).message)
        : '';

  if (!raw) return fallback;

  for (const [pattern, friendly] of PATTERNS) {
    if (pattern.test(raw)) return friendly;
  }

  return fallback;
}
