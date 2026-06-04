-- Create table to audit outbound emails (receipts, pagarés, etc.)
-- Simplicity-first: minimal fields, robust constraints, and RLS for read access.

-- Ensure pgcrypto for gen_random_uuid
create extension if not exists pgcrypto with schema public;

create table if not exists public.email_logs (
  id uuid primary key default gen_random_uuid(),
  type text not null default 'other',
  to_email text not null,
  related_id uuid null,
  user_id uuid null, -- who triggered the send (auth.uid())
  provider_message_id text null, -- provider-specific id
  status text not null default 'queued',
  error text null,
  created_at timestamptz not null default now(),
  constraint email_logs_status_check check (status in ('queued','sent','failed')),
  constraint email_logs_type_check check (type in ('receipt','pagare','other')),
  constraint email_logs_email_check check (to_email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$')
);

comment on table public.email_logs is 'Audit log of outbound emails (receipts, pagaré, etc.)';
comment on column public.email_logs.type is 'receipt | pagare | other';

create index if not exists email_logs_related_id_idx on public.email_logs(related_id);
create index if not exists email_logs_to_email_idx on public.email_logs(to_email);
create index if not exists email_logs_created_at_idx on public.email_logs(created_at desc);

alter table public.email_logs enable row level security;

-- Allow ADMIN and ASIST to read logs; inserts are performed by service role (bypasses RLS)
create policy email_logs_select_admin_asist on public.email_logs
for select to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and lower(p.role) in ('admin','asist')
  )
);
