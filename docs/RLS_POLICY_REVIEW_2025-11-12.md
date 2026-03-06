# RLS Policy & UDF Review (2025-11-12)

This note reviews two artifacts:
- `prompt/Row-level_Policy_Inspector.json`
- `prompt/User-defined_Functions_Inventory.json`

## Findings

1) Guardians table (public.guardians)
- RLS is enabled and the inspector highlights a gap: "Sin políticas diferenciadas para ADMIN/ASIST (solo owner)".
- In the inspector output, no policies are listed for `public.guardians`, which suggests either:
  - policies exist but weren't included in the dump, or
  - there is only an owner policy and no staff policy.
- Impact: Staff may be unable to read/edit guardians directly; auto-provision flows that need to link by email and then update `owner_id` may fail if not executed via a SECURITY DEFINER function.

Action: Added a safe, additive staff policy in `RLS_POLICY_FIXES_2025-11-12.sql` (see below) so ADMIN/ASIST can operate on `public.guardians` via their `profiles.role`.

2) Fee table guardian read predicate
- Inspector shows: `fee_guardian_read` uses `sg.guardian_id = auth.uid()` which mismatches types (guardian_id is a guardians.id; auth.uid() is an auth.users id).
- Impact: Guardians may be blocked from viewing their `fee` rows.

Action: Added a corrected, additive policy `fee_guardian_read_by_owner` that joins to `guardians` and filters by `g.owner_id = auth.uid()`.

3) Auth logs (public.auth_logs)
- RLS enabled, no policies listed. This explains client 401s when trying to write. We already disabled client writes; if logging is desired, route writes through a SECURITY DEFINER RPC.

4) UDFs inventory observations
- `ensure_guardian_for_user` exists (return uuid). The inventory doesn’t include SECURITY DEFINER flags.
- If this function is used for auto-provision/linking, ensure:
  - SECURITY DEFINER
  - Restricted: either validates `auth.uid()` equals the intended owner, and only updates/creates that owner’s row
  - Safe `search_path` (e.g., `SET search_path = public, pg_catalog`)
  - Explicit grants: `GRANT EXECUTE ON FUNCTION ensure_guardian_for_user(...) TO authenticated;`
- `guardian_portal_bootstrap` is not listed; code should fall back to client aggregation or use a staff-owned RPC.

## SQL patch (additive)

See `RLS_POLICY_FIXES_2025-11-12.sql` which:
- Adds `guardians_staff_all` policy to allow ADMIN/ASIST full access via `profiles.role`.
- Adds `fee_guardian_read_by_owner` policy to allow guardians to read `fee` via `g.owner_id = auth.uid()`.

Both are additive (no drops), minimizing risk.

## Recommended next checks

- Verify `public.guardians` still has a strict owner policy for non-staff, and optionally allow INSERT for owners:
  ```sql
  create policy if not exists guardians_owner_insert on public.guardians
  for insert to authenticated
  with check (owner_id = auth.uid());
  ```
  Note: PostgreSQL lacks `IF NOT EXISTS` for policies; use conditional DO blocks or create under a unique name.

- Ensure `ensure_guardian_for_user` is SECDEF and safe:
  ```sql
  alter function public.ensure_guardian_for_user(uuid, text)
    security definer;

  alter function public.ensure_guardian_for_user(uuid, text)
    set search_path = public, pg_catalog;

  grant execute on function public.ensure_guardian_for_user(uuid, text) to authenticated;
  ```
  Adjust the argument types to match the actual signature.

- If staff needs direct access to guardians in the UI, the new `guardians_staff_all` policy should cover it; otherwise, remove it and funnel access through staff-only RPCs.

## Why this matters

- New Google users should land in the guardian portal and see their data. That requires either:
  - client can insert/update `public.guardians` (owner policies must permit), or
  - a SECDEF RPC performs the create/link on their behalf, bypassing RLS safely.

- The incorrect `fee` predicate likely blocked guardians from viewing their fees even when other relations were correct.

## Rollout notes

- Apply `RLS_POLICY_FIXES_2025-11-12.sql` on the database (once per environment).
- Test with a brand-new Google account: verify guardian row exists/links, and `fee` rows are visible.
- Keep client remote logging disabled unless a SECDEF log writer is added.
