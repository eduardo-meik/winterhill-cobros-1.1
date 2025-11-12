# ADMIN cannot register a new student — Checklist

Use this to verify DB permissions (RLS) and environment setup, and to collect actionable evidence.

## 1) Verify ADMIN role in DB

- Ensure the admin user has a row in `public.profiles` with `role = 'ADMIN'`.

```sql
-- Replace :admin_user_id with the UUID of the admin
select id, role from public.profiles where id = :admin_user_id;

-- If missing or wrong role, fix:
insert into public.profiles(id, role, full_name)
values (:admin_user_id, 'ADMIN', 'Admin')
on conflict (id) do update set role = excluded.role;
```

## 2) Confirm `get_current_user_role()` behavior

- The RLS policy for `public.students` uses `get_current_user_role() = 'ADMIN'`.
- Make sure the function returns exactly `ADMIN` (uppercase) when called as the admin user.

```sql
-- Run this while authenticated as the admin (e.g., via SQL editor impersonation)
select public.get_current_user_role() as current_role;
```

If it returns something else (e.g., lowercase or null), adjust the function to normalize to uppercase or map properly from `public.profiles`.

## 3) RLS policies on `public.students`

- Inspector shows:
  - `students_admin_access` for ALL with `with check = get_current_user_role() = 'ADMIN'`.
  - This should permit INSERT/UPDATE/DELETE/SELECT for ADMIN.
- If inserts still fail with RLS, capture the exact error code/message:
  - `42501` indicates RLS/privilege denial.

Optional additive policy (if needed temporarily to unblock):
```sql
-- Allow ADMIN by profile role directly (redundant but explicit)
create policy students_staff_all on public.students
for all to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'ADMIN'))
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'ADMIN'));
```

## 4) Constraints and FKs

- Common errors:
  - `23503` foreign key violation: invalid `curso` id.
  - `23502` not-null violation: missing required field.
  - `23505` unique violation: duplicate `run` (the UI checks this beforehand, but race conditions can still occur).

Verify `curso` exists:
```sql
select id, nom_curso from public.cursos where id = :curso_id;
```

## 5) Client environment

- Ensure Production is connected to the same Supabase project where RLS/roles were applied:
  - `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` match the environment you patched.
- After DB changes, redeploy with cache clear on Vercel to avoid stale bundles.

## 6) Evidence to collect

- Screenshot of `profiles` row for the admin showing `role = ADMIN` (mask UUID).
- Result of `select public.get_current_user_role()` as admin.
- Exact error payload from the UI (code, message, details) when inserting a student.
- `cursos` row existence for the selected `curso` id.

## 7) UI improvements (already applied)

- Student registration modal now shows more precise errors for:
  - Foreign key (curso inválido)
  - Not null (faltan campos)
  - Unique (RUN duplicado)
  - RLS (Permisos insuficientes)

If you still hit RLS errors as ADMIN after confirming the above, share the error code and we’ll adjust the RLS or the role function accordingly.