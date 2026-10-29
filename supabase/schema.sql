-- Hiveday Gearbox Engineering
-- Supabase/PostgreSQL starter schema
-- Run this in a NEW Supabase project via SQL Editor after reviewing it.
-- This creates a private, owner-scoped engineering database.
-- Do not put service-role keys in the website or browser JavaScript.

create extension if not exists pgcrypto;

-- Vehicles can be reused across multiple repair cases.
create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  make text not null,
  model text not null,
  model_year integer,
  engine text,
  vin_last6 text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vehicles_year_check check (model_year is null or model_year between 1950 and 2100),
  constraint vehicles_vin_last6_check check (vin_last6 is null or char_length(vin_last6) <= 6)
);

create table if not exists public.repair_cases (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  case_number text,
  customer_label text,
  customer_phone text,
  transmission_make text,
  transmission_model text,
  gearbox_code text,
  mileage_km integer,
  customer_complaint text not null,
  operating_conditions text,
  dtc_codes text[] not null default '{}',
  fluid_condition text,
  initial_assessment text,
  confirmed_root_cause text,
  repair_status text not null default 'open'
    check (repair_status in ('open', 'diagnosing', 'awaiting_parts', 'repairing', 'completed', 'closed')),
  repair_outcome text,
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint repair_cases_mileage_check check (mileage_km is null or mileage_km >= 0)
);

create table if not exists public.diagnostic_tests (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  repair_case_id uuid not null references public.repair_cases(id) on delete cascade,
  test_name text not null,
  procedure_reference text,
  conditions text,
  expected_result text,
  actual_result text,
  measurements jsonb not null default '{}'::jsonb,
  interpretation text,
  performed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.repair_actions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  repair_case_id uuid not null references public.repair_cases(id) on delete cascade,
  action_type text not null default 'repair'
    check (action_type in ('inspection', 'repair', 'replacement', 'programming', 'adaptation', 'maintenance', 'road_test', 'other')),
  description text not null,
  parts_used text[] not null default '{}',
  performed_at timestamptz not null default now(),
  result text,
  created_at timestamptz not null default now()
);

create table if not exists public.technical_references (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  reference_type text not null default 'note'
    check (reference_type in ('note', 'manual', 'bulletin', 'wiring_diagram', 'specification', 'training_material', 'other')),
  vehicle_make text,
  vehicle_model text,
  transmission_model text,
  gearbox_code text,
  source_name text,
  source_date date,
  notes text,
  storage_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Helpful indexes for common searches.
create index if not exists vehicles_owner_idx on public.vehicles(owner_id);
create index if not exists vehicles_make_model_idx on public.vehicles(make, model);
create index if not exists repair_cases_owner_idx on public.repair_cases(owner_id);
create index if not exists repair_cases_vehicle_idx on public.repair_cases(vehicle_id);
create index if not exists repair_cases_gearbox_idx on public.repair_cases(gearbox_code);
create index if not exists repair_cases_status_idx on public.repair_cases(repair_status);
create index if not exists repair_cases_dtcs_idx on public.repair_cases using gin(dtc_codes);
create index if not exists diagnostic_tests_case_idx on public.diagnostic_tests(repair_case_id);
create index if not exists repair_actions_case_idx on public.repair_actions(repair_case_id);
create index if not exists technical_references_gearbox_idx on public.technical_references(gearbox_code);

-- Enable Row Level Security on every private table.
alter table public.vehicles enable row level security;
alter table public.repair_cases enable row level security;
alter table public.diagnostic_tests enable row level security;
alter table public.repair_actions enable row level security;
alter table public.technical_references enable row level security;

-- Owner-scoped policies. A signed-in user can only access rows they own.
drop policy if exists "Owners manage their vehicles" on public.vehicles;
create policy "Owners manage their vehicles"
on public.vehicles for all
to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

drop policy if exists "Owners manage their repair cases" on public.repair_cases;
create policy "Owners manage their repair cases"
on public.repair_cases for all
to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

drop policy if exists "Owners manage their diagnostic tests" on public.diagnostic_tests;
create policy "Owners manage their diagnostic tests"
on public.diagnostic_tests for all
to authenticated
using (
  owner_id = (select auth.uid())
  and exists (
    select 1 from public.repair_cases rc
    where rc.id = repair_case_id and rc.owner_id = (select auth.uid())
  )
)
with check (
  owner_id = (select auth.uid())
  and exists (
    select 1 from public.repair_cases rc
    where rc.id = repair_case_id and rc.owner_id = (select auth.uid())
  )
);

drop policy if exists "Owners manage their repair actions" on public.repair_actions;
create policy "Owners manage their repair actions"
on public.repair_actions for all
to authenticated
using (
  owner_id = (select auth.uid())
  and exists (
    select 1 from public.repair_cases rc
    where rc.id = repair_case_id and rc.owner_id = (select auth.uid())
  )
)
with check (
  owner_id = (select auth.uid())
  and exists (
    select 1 from public.repair_cases rc
    where rc.id = repair_case_id and rc.owner_id = (select auth.uid())
  )
);

drop policy if exists "Owners manage their technical references" on public.technical_references;
create policy "Owners manage their technical references"
on public.technical_references for all
to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

-- Keep browser-facing privileges limited to signed-in users.
revoke all on public.vehicles from anon, public;
revoke all on public.repair_cases from anon, public;
revoke all on public.diagnostic_tests from anon, public;
revoke all on public.repair_actions from anon, public;
revoke all on public.technical_references from anon, public;

grant select, insert, update, delete on public.vehicles to authenticated;
grant select, insert, update, delete on public.repair_cases to authenticated;
grant select, insert, update, delete on public.diagnostic_tests to authenticated;
grant select, insert, update, delete on public.repair_actions to authenticated;
grant select, insert, update, delete on public.technical_references to authenticated;

-- NOTE:
-- 1) Website contact forms should submit through a server-side Edge Function
--    with validation/rate limiting (and ideally CAPTCHA), not direct anonymous table writes.
-- 2) If you later add staff or multi-workshop accounts, replace the simple owner_id
--    model with a reviewed organization/membership permission model before launch.
-- 3) This schema does not configure storage buckets, email delivery, AI, backups,
--    or account recovery. Configure and test those separately.
