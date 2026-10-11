create extension if not exists pgcrypto;

create table if not exists public.user_roles(
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check(role='admin')
);
create table if not exists public.products(
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric(10,2) not null default 0 check(price>=0),
  category text not null default '',
  barcode text,
  image_url text not null default '',
  description text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.orders(
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  address text not null,
  payment_method text not null default 'كاش عند الاستلام',
  notes text not null default '',
  latitude double precision not null check(latitude between -90 and 90),
  longitude double precision not null check(longitude between -180 and 180),
  total numeric(10,2) not null check(total>=0),
  status text not null default 'طلب جديد',
  created_at timestamptz not null default now()
);
create table if not exists public.order_items(
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null check(quantity>0),
  unit_price numeric(10,2) not null check(unit_price>=0)
);
create index if not exists orders_created_at_idx on public.orders(created_at desc);
create index if not exists products_category_idx on public.products(category);

create or replace function public.is_petworld_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.user_roles where user_id=auth.uid() and role='admin');
$$;

alter table public.user_roles enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists "public reads active products" on public.products;
create policy "public reads active products" on public.products for select to anon,authenticated using (is_active=true or public.is_petworld_admin());
drop policy if exists "admin manages products" on public.products;
create policy "admin manages products" on public.products for all to authenticated using(public.is_petworld_admin()) with check(public.is_petworld_admin());
drop policy if exists "admin reads own role" on public.user_roles;
create policy "admin reads own role" on public.user_roles for select to authenticated using(user_id=auth.uid() or public.is_petworld_admin());
drop policy if exists "admin reads orders" on public.orders;
create policy "admin reads orders" on public.orders for select to authenticated using(public.is_petworld_admin());
drop policy if exists "admin updates orders" on public.orders;
create policy "admin updates orders" on public.orders for update to authenticated using(public.is_petworld_admin()) with check(public.is_petworld_admin());
drop policy if exists "admin deletes orders" on public.orders;
create policy "admin deletes orders" on public.orders for delete to authenticated using(public.is_petworld_admin());
drop policy if exists "admin reads order items" on public.order_items;
create policy "admin reads order items" on public.order_items for select to authenticated using(public.is_petworld_admin());
drop policy if exists "admin updates order items" on public.order_items;
create policy "admin updates order items" on public.order_items for update to authenticated using(public.is_petworld_admin()) with check(public.is_petworld_admin());
drop policy if exists "admin deletes order items" on public.order_items;
create policy "admin deletes order items" on public.order_items for delete to authenticated using(public.is_petworld_admin());

create or replace function public.create_public_order(
 p_customer_name text,p_phone text,p_address text,p_payment_method text,p_notes text,
 p_latitude double precision,p_longitude double precision,p_items jsonb
) returns table(order_id uuid)
language plpgsql security definer set search_path=public as $$
declare
 new_id uuid; total_amount numeric(10,2):=0; item jsonb; prod public.products%rowtype; qty integer;
begin
 if length(trim(coalesce(p_customer_name,'')))<2 or length(trim(p_customer_name))>120 then raise exception 'Invalid name'; end if;
 if length(trim(coalesce(p_phone,'')))<6 or length(trim(p_phone))>30 then raise exception 'Invalid phone'; end if;
 if length(trim(coalesce(p_address,'')))<3 or length(trim(p_address))>500 then raise exception 'Invalid address'; end if;
 if p_latitude is null or p_longitude is null or p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then raise exception 'Location required'; end if;
 if p_items is null or jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'Empty cart'; end if;
 for item in select value from jsonb_array_elements(p_items) loop
   qty:=(item->>'quantity')::integer;
   if qty<1 or qty>100 then raise exception 'Invalid quantity'; end if;
   select * into prod from public.products where id=(item->>'product_id')::uuid and is_active=true;
   if not found then raise exception 'Product unavailable'; end if;
   total_amount:=total_amount+prod.price*qty;
 end loop;
 insert into public.orders(customer_name,phone,address,payment_method,notes,latitude,longitude,total,status)
 values(trim(p_customer_name),trim(p_phone),trim(p_address),coalesce(p_payment_method,'كاش عند الاستلام'),coalesce(p_notes,''),p_latitude,p_longitude,total_amount,'طلب جديد')
 returning id into new_id;
 for item in select value from jsonb_array_elements(p_items) loop
   qty:=(item->>'quantity')::integer;
   select * into prod from public.products where id=(item->>'product_id')::uuid and is_active=true;
   insert into public.order_items(order_id,product_id,product_name,quantity,unit_price)
   values(new_id,prod.id,prod.name,qty,prod.price);
 end loop;
 return query select new_id;
end; $$;
revoke all on function public.create_public_order(text,text,text,text,text,double precision,double precision,jsonb) from public;
grant execute on function public.create_public_order(text,text,text,text,text,double precision,double precision,jsonb) to anon,authenticated;

-- Enable Realtime for new-order sound: Supabase Dashboard > Database > Publications > supabase_realtime > add table orders.
-- Create the admin account in Authentication > Users, then run:
-- insert into public.user_roles(user_id,role)
-- select id,'admin' from auth.users where email='YOUR_ADMIN_EMAIL'
-- on conflict(user_id) do update set role='admin';
