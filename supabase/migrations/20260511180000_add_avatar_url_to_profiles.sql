-- Migration: Avatar photo upload
--
-- WHY:
--   Adds optional photo support to the user profile. Until now the
--   AvatarDisc shows the first letter of display_name; users with a
--   photo will see their uploaded image instead. Initial-letter
--   fallback stays for users who don't upload.
--
-- DESIGN:
--   - profiles.avatar_url: nullable public Storage URL.
--   - Storage bucket `avatars` (public read) with file size cap 2MB
--     and image/jpeg | image/png allowed.
--   - File path: avatars/<user_id>/avatar.jpg (one file per user).
--   - RLS on storage.objects: public read, own-folder write only.
--
-- ROLLBACK:
--   ALTER TABLE public.profiles DROP COLUMN IF EXISTS avatar_url;
--   DELETE FROM storage.buckets WHERE id = 'avatars';

alter table public.profiles
    add column if not exists avatar_url text;

comment on column public.profiles.avatar_url is
    'Public Supabase Storage URL for the user-uploaded avatar. Null = use initial letter fallback.';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png'])
on conflict (id) do nothing;

drop policy if exists "avatars public read"        on storage.objects;
drop policy if exists "avatars own folder write"   on storage.objects;
drop policy if exists "avatars own folder update"  on storage.objects;
drop policy if exists "avatars own folder delete"  on storage.objects;

create policy "avatars public read"
    on storage.objects for select
    using (bucket_id = 'avatars');

create policy "avatars own folder write"
    on storage.objects for insert
    with check (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = (select auth.uid())::text
    );

create policy "avatars own folder update"
    on storage.objects for update
    using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = (select auth.uid())::text
    );

create policy "avatars own folder delete"
    on storage.objects for delete
    using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = (select auth.uid())::text
    );
