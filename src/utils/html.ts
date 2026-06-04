/**
 * Escapes HTML special characters to prevent XSS when interpolating
 * user-supplied values into HTML templates.
 */
const ESCAPE_MAP: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
};

const ESCAPE_RE = /[&<>"']/g;

export function escapeHtml(value: unknown): string {
  const str = value == null ? '' : String(value);
  return str.replace(ESCAPE_RE, (ch) => ESCAPE_MAP[ch] || ch);
}
