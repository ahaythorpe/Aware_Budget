-- Migration: add public.profiles table
--
-- WHY:
--   SupabaseService.fetchFirstName() currently falls back to the email
--   local-part when user_metadata.full_name is missing. With Apple Sign-In
--   "Hide My Email", this prints opaque relay strings like "Xfbsmt9rs4"
--   as if they were the user's name. The profiles table gives us a proper
--   home for display_name + privacy toggles (hide_name / hide_email),
--   needed for App Store privacy disclosure (Guideline 5.1.1).
--
-- DESIGN:
--   - Primary key IS auth.users.id  → 1:1, no double-up possible.
--   - ON DELETE CASCADE              → deleting an auth user auto-cleans
--                                      the profile row.
--   - Auto-create trigger            → every new auth user gets a profile
--                                      at signup (no race conditions, no
--                                      missing-row edge cases).
--   - RLS uses (select auth.uid())   → per-query evaluation, not per-row
--                                      (matches the convention being
--                                      applied to all other tables in a
--                                      later migration).
--
-- ROLLBACK (run in order to fully revert):
--   DROP TRIGGER  IF EXISTS on_auth_user_created ON auth.users;
--   DROP FUNCTION IF EXISTS public.handle_new_user();
--   DROP TABLE    IF EXISTS public.profiles;

create table if not exists public.profiles (
    id              uuid        primary key references auth.users(id) on delete cascade,
    display_name    text,
    hide_name       boolean     not null default false,
    hide_email      boolean     not null default false,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

comment on table public.profiles is
    'User-editable display preferences. Primary key = auth.users.id (1:1, ON DELETE CASCADE). Auto-created via on_auth_user_created trigger.';

-- Row Level Security
alter table public.profiles enable row level security;

drop policy if exists "own profile read"   on public.profiles;
drop policy if exists "own profile update" on public.profiles;
drop policy if exists "own profile insert" on public.profiles;

create policy "own profile read"   on public.profiles
    for select using ((select auth.uid()) = id);

create policy "own profile update" on public.profiles
    for update
    using       ((select auth.uid()) = id)
    with check  ((select auth.uid()) = id);

create policy "own profile insert" on public.profiles
    for insert
    with check  ((select auth.uid()) = id);

-- Auto-create profile row whenever a new auth.users row appears
-- (email/password signup, Sign in with Apple first sign-in, etc.)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id)
    values (new.id)
    on conflict (id) do nothing;
    return new;
end;
$$;

comment on function public.handle_new_user() is
    'Auto-creates a public.profiles row for every new auth.users row. SECURITY DEFINER so the trigger can write to public.profiles regardless of caller perms; the on conflict do nothing clause makes it safe to re-run.';

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Backfill: create profile rows for users who already exist in auth.users
-- (so the new fetchFirstName() codepath has rows to read on day one).
insert into public.profiles (id)
select id from auth.users
on conflict (id) do nothing;

-- Trigger to keep updated_at fresh on every UPDATE
create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
    before update on public.profiles
    for each row execute function public.set_profiles_updated_at();
