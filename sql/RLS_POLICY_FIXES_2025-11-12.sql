-- RLS policy fixes and additions (safe, additive) - 2025-11-12
-- Context: Ensure guardians can be accessed by staff and guardians can read fee rows via correct ownership linkage.

begin;

-- 1) Guardians: Staff (ADMIN/ASIST) full access via profiles.role
-- Additive policy; doesn't drop or replace existing owner policies.
create policy guardians_staff_all on public.guardians
for all
to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role in ('ADMIN','ASIST')
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role in ('ADMIN','ASIST')
  )
);

-- 2) Fee: Guardian read via guardians.owner_id, not guardian_id = auth.uid()
-- Additive policy; allows correct access even if an older incorrect policy exists.
create policy fee_guardian_read_by_owner on public.fee
for select
to authenticated
using (
  exists (
    select 1
    from public.student_guardian sg
    join public.guardians g on g.id = sg.guardian_id
    where sg.student_id = fee.student_id
      and g.owner_id = auth.uid()
  )
);

commit;