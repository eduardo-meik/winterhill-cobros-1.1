-- Allow ADMIN/ASIST to manage student-guardian associations (write policies)
begin;

create policy student_guardian_admin_asist_all on public.student_guardian
for all to authenticated
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

commit;