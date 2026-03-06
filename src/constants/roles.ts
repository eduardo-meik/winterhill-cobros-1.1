/**
 * Centralized role & profile constants.
 *
 * `Role` — lowercase value stored in profiles.role  (DB / URL layer)
 * `Profile` — uppercase permission tier derived from the role (UI layer)
 */

// --- Roles (lowercase, from DB) ---
export const ROLE_ADMIN = 'admin' as const;
export const ROLE_ASIST = 'asist' as const;
export const ROLE_GUARDIAN = 'guardian' as const;

export const VALID_ROLES = [ROLE_ADMIN, ROLE_ASIST, ROLE_GUARDIAN] as const;
export type Role = (typeof VALID_ROLES)[number];

// --- Profiles (uppercase, derived) ---
export const PROFILE_ADMIN = 'ADMIN' as const;
export const PROFILE_ASIST = 'ASIST' as const;
export const PROFILE_READONLY = 'READONLY' as const;

export type Profile = typeof PROFILE_ADMIN | typeof PROFILE_ASIST | typeof PROFILE_READONLY;

/** True when the role is admin or asist (staff member). */
export function isStaffRole(role?: string | null): boolean {
  const r = (role ?? '').toLowerCase();
  return r === ROLE_ADMIN || r === ROLE_ASIST;
}

/** True when the role is guardian. */
export function isGuardianRole(role?: string | null): boolean {
  return (role ?? '').toLowerCase() === ROLE_GUARDIAN;
}

/** True when the profile is admin or asist (has staff privileges). */
export function isStaffProfile(profile?: string | null): boolean {
  return profile === PROFILE_ADMIN || profile === PROFILE_ASIST;
}
