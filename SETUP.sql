-- ============================================================
-- SR5 Portfolio — راه‌اندازی بخش «عکس‌های من» (اسلایدشو)
-- این اسکریپت رو یک‌بار تو Supabase SQL Editor اجرا کن:
--   dashboard.supabase.com  →  پروژه‌ت  →  SQL Editor  →  New query
--   کل این فایل رو پیست کن و Run بزن.
-- اجرای دوباره‌ش هم مشکلی نداره (idempotent است).
-- ============================================================

-- 1) جدول عکس‌ها
create table if not exists public.gallery_photos (
  id bigint generated always as identity primary key,
  url text not null,
  path text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.gallery_photos enable row level security;

drop policy if exists "gallery_photos_public_read" on public.gallery_photos;
create policy "gallery_photos_public_read"
on public.gallery_photos for select
to anon, authenticated
using (true);

drop policy if exists "gallery_photos_auth_insert" on public.gallery_photos;
create policy "gallery_photos_auth_insert"
on public.gallery_photos for insert
to authenticated
with check (true);

drop policy if exists "gallery_photos_auth_update" on public.gallery_photos;
create policy "gallery_photos_auth_update"
on public.gallery_photos for update
to authenticated
using (true);

drop policy if exists "gallery_photos_auth_delete" on public.gallery_photos;
create policy "gallery_photos_auth_delete"
on public.gallery_photos for delete
to authenticated
using (true);

-- 2) باکت استوریج برای خود فایل‌های عکس
insert into storage.buckets (id, name, public)
values ('gallery', 'gallery', true)
on conflict (id) do nothing;

drop policy if exists "gallery_bucket_public_read" on storage.objects;
create policy "gallery_bucket_public_read"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'gallery');

drop policy if exists "gallery_bucket_auth_insert" on storage.objects;
create policy "gallery_bucket_auth_insert"
on storage.objects for insert
to authenticated
with check (bucket_id = 'gallery');

drop policy if exists "gallery_bucket_auth_delete" on storage.objects;
create policy "gallery_bucket_auth_delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'gallery');

-- ============================================================
-- موزیک پس‌زمینه سایت (یک فایل صوتی، پخش خودکار)
-- ============================================================
create table if not exists public.site_music (
  id int primary key default 1,
  url text,
  path text,
  updated_at timestamptz not null default now(),
  constraint site_music_single_row check (id = 1)
);

insert into public.site_music (id, url, path)
values (1, null, null)
on conflict (id) do nothing;

alter table public.site_music enable row level security;

drop policy if exists "site_music_public_read" on public.site_music;
create policy "site_music_public_read"
on public.site_music for select
to anon, authenticated
using (true);

drop policy if exists "site_music_auth_update" on public.site_music;
create policy "site_music_auth_update"
on public.site_music for update
to authenticated
using (true)
with check (true);

drop policy if exists "site_music_auth_insert" on public.site_music;
create policy "site_music_auth_insert"
on public.site_music for insert
to authenticated
with check (true);

-- باکت استوریج برای فایل موزیک
insert into storage.buckets (id, name, public)
values ('music', 'music', true)
on conflict (id) do nothing;

drop policy if exists "music_bucket_public_read" on storage.objects;
create policy "music_bucket_public_read"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'music');

drop policy if exists "music_bucket_auth_insert" on storage.objects;
create policy "music_bucket_auth_insert"
on storage.objects for insert
to authenticated
with check (bucket_id = 'music');

drop policy if exists "music_bucket_auth_delete" on storage.objects;
create policy "music_bucket_auth_delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'music');

-- ============================================================
-- چت آنلاین (گفتینوی خودمون) — مکالمات و پیام‌ها
-- ============================================================
create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  visitor_name text,
  visitor_phone text,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id bigint generated always as identity primary key,
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  sender text not null check (sender in ('visitor','admin')),
  msg_type text not null default 'text' check (msg_type in ('text','image','video','audio')),
  content text,
  media_url text,
  media_path text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;

-- مکالمه: بازدیدکننده (anon) هم باید بتونه بسازه و بخونه، ادمین هم همینطور
drop policy if exists "chat_conv_select" on public.chat_conversations;
create policy "chat_conv_select" on public.chat_conversations for select to anon, authenticated using (true);
drop policy if exists "chat_conv_insert" on public.chat_conversations;
create policy "chat_conv_insert" on public.chat_conversations for insert to anon, authenticated with check (true);
drop policy if exists "chat_conv_update" on public.chat_conversations;
create policy "chat_conv_update" on public.chat_conversations for update to anon, authenticated using (true) with check (true);

-- پیام‌ها: هم بازدیدکننده هم ادمین بتونن بنویسن و بخونن
drop policy if exists "chat_msg_select" on public.chat_messages;
create policy "chat_msg_select" on public.chat_messages for select to anon, authenticated using (true);
drop policy if exists "chat_msg_insert" on public.chat_messages;
create policy "chat_msg_insert" on public.chat_messages for insert to anon, authenticated with check (true);
drop policy if exists "chat_msg_update" on public.chat_messages;
create policy "chat_msg_update" on public.chat_messages for update to anon, authenticated using (true) with check (true);

-- باکت استوریج برای عکس/ویدیو/ویس چت
insert into storage.buckets (id, name, public)
values ('chat-media', 'chat-media', true)
on conflict (id) do nothing;

drop policy if exists "chat_media_public_read" on storage.objects;
create policy "chat_media_public_read"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'chat-media');

drop policy if exists "chat_media_public_insert" on storage.objects;
create policy "chat_media_public_insert"
on storage.objects for insert
to anon, authenticated
with check (bucket_id = 'chat-media');

-- فعال‌سازی Realtime برای جدول پیام‌های چت (بدون این، پیام‌ها زنده نمایش داده نمی‌شن)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end $$;

-- قابلیت ریپلای (پاسخ به یک پیام خاص)
alter table public.chat_messages add column if not exists reply_to_id bigint references public.chat_messages(id);
alter table public.chat_messages add column if not exists reply_to_snippet text;

-- انیمیشن ورود عناصر هنگام اسکرول
alter table public.site_settings add column if not exists scroll_anim text default 'fade-up';
