-- Pet World database schema for Supabase (PostgreSQL)
-- Run this in Supabase SQL Editor.
-- RLS is enabled and no public write/read policies are created intentionally.
-- Add authenticated admin policies only after setting up Supabase Auth and an admin role.

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric(10,2) not null default 0 check (price >= 0),
  category text not null default '',
  barcode text unique,
  image_url text not null default '',
  description text not null default '',
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_category_idx on public.products(category);
create index if not exists products_name_idx on public.products using gin (to_tsvector('simple', name));

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,
  customer_name text not null,
  phone text not null,
  address text not null,
  payment_method text not null default '',
  notes text not null default '',
  items jsonb not null default '[]'::jsonb,
  total numeric(10,2) not null default 0 check (total >= 0),
  status text not null default 'طلب جديد',
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;
alter table public.orders enable row level security;

-- Intentionally no anon policies: secure policies should be added after
-- Supabase Auth/admin roles and a trusted order-submission flow are configured.
