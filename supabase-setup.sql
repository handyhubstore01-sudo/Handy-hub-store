-- HANDY HUB: Supabase setup (run in Supabase Dashboard > SQL Editor)
-- Uses dedicated hh_* tables. It does not alter the legacy products table.

create extension if not exists pgcrypto;

create table if not exists public.hh_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.hh_products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  price numeric(12,2) not null check (price >= 0),
  old_price numeric(12,2) check (old_price is null or old_price >= 0),
  description text not null default '',
  status text not null default 'available' check (status in ('available','out')),
  badge text check (badge is null or badge in ('trending','new')),
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.hh_admins enable row level security;
alter table public.hh_products enable row level security;

create or replace function public.hh_is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.hh_admins
    where user_id = auth.uid()
  );
$$;

revoke all on function public.hh_is_admin() from public;
grant execute on function public.hh_is_admin() to anon, authenticated;

drop policy if exists "Admins can read their own admin record" on public.hh_admins;
create policy "Admins can read their own admin record"
  on public.hh_admins for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "Public can read available Handy Hub products" on public.hh_products;
create policy "Public can read available Handy Hub products"
  on public.hh_products for select to anon, authenticated
  using (status = 'available' or public.hh_is_admin());

drop policy if exists "Admins can insert Handy Hub products" on public.hh_products;
create policy "Admins can insert Handy Hub products"
  on public.hh_products for insert to authenticated
  with check (public.hh_is_admin());

drop policy if exists "Admins can update Handy Hub products" on public.hh_products;
create policy "Admins can update Handy Hub products"
  on public.hh_products for update to authenticated
  using (public.hh_is_admin()) with check (public.hh_is_admin());

drop policy if exists "Admins can delete Handy Hub products" on public.hh_products;
create policy "Admins can delete Handy Hub products"
  on public.hh_products for delete to authenticated
  using (public.hh_is_admin());

revoke all on table public.hh_admins from anon, authenticated;
grant select on table public.hh_admins to authenticated;
revoke all on table public.hh_products from anon, authenticated;
grant select on table public.hh_products to anon, authenticated;
grant insert, update, delete on table public.hh_products to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('hh-products', 'hh-products', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public = true,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Public can view Handy Hub product images" on storage.objects;
create policy "Public can view Handy Hub product images"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'hh-products');

drop policy if exists "Admins can upload Handy Hub product images" on storage.objects;
create policy "Admins can upload Handy Hub product images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'hh-products' and public.hh_is_admin());

drop policy if exists "Admins can update Handy Hub product images" on storage.objects;
create policy "Admins can update Handy Hub product images"
  on storage.objects for update to authenticated
  using (bucket_id = 'hh-products' and public.hh_is_admin())
  with check (bucket_id = 'hh-products' and public.hh_is_admin());

drop policy if exists "Admins can delete Handy Hub product images" on storage.objects;
create policy "Admins can delete Handy Hub product images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'hh-products' and public.hh_is_admin());

-- After creating the Auth user, run this grant separately:
-- insert into public.hh_admins (user_id)
-- select id from auth.users
-- where lower(email) = lower('handyhubstore01@gmail.com')
-- on conflict (user_id) do nothing;
