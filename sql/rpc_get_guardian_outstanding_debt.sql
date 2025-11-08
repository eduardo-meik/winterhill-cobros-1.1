-- Creates the RPC get_guardian_outstanding_debt used by the UI
-- Safe to run multiple times (CREATE OR REPLACE)
-- Aggregates pending/overdue fees for a guardian by either fee.guardian_id
-- or via student_guardian linkage.

-- Usage: select * from get_guardian_outstanding_debt('<guardian_uuid>');

create or replace function public.get_guardian_outstanding_debt(guardian_id uuid)
returns jsonb
language sql
security definer
set search_path = public
as $$
with direct as (
  select id, student_id, guardian_id, amount, due_date, status, year_academico, numero_cuota
  from fee
  where guardian_id = get_guardian_outstanding_debt.guardian_id
    and status in ('pending','overdue')
),
sg as (
  select student_id from student_guardian where guardian_id = get_guardian_outstanding_debt.guardian_id
),
by_students as (
  select f.id, f.student_id, f.guardian_id, f.amount, f.due_date, f.status, f.year_academico, f.numero_cuota
  from fee f
  join sg on sg.student_id = f.student_id
  where f.status in ('pending','overdue')
),
all_fees as (
  select * from direct
  union
  select * from by_students
)
select jsonb_build_object(
  'total', coalesce(sum(amount),0),
  'items', coalesce(jsonb_agg(jsonb_build_object(
    'id', id,
    'student_id', student_id,
    'guardian_id', guardian_id,
    'amount', amount,
    'due_date', due_date,
    'status', status,
    'year_academico', year_academico,
    'numero_cuota', numero_cuota
  )), '[]'::jsonb)
)
from all_fees;
$$;

-- Permissions (adjust roles to your project):
do $$ begin
  grant execute on function public.get_guardian_outstanding_debt(uuid) to anon;
  grant execute on function public.get_guardian_outstanding_debt(uuid) to authenticated;
  grant execute on function public.get_guardian_outstanding_debt(uuid) to service_role;
exception when others then null; end $$;

-- RLS hint: ensure the invoking role can select from fee and student_guardian as appropriate.
-- If RLS is enabled, you may need suitable policies for this function (or narrower SECURITY DEFINER with controlled logic).
