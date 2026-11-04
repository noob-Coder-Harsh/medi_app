-- ============================================================================
-- MEDISYNC SCHEMA — 28 October 2026
-- ============================================================================
-- Paste this entire file into the Supabase SQL Editor on a NEW project and
-- run it once. It creates tables, listing RPCs, RLS, seed categories, and
-- the public image bucket. This is the only database bootstrap.
-- ============================================================================

create extension if not exists pg_trgm with schema extensions;

-- ============================================================================
-- STORE USERS (created before stores — stores.owner_id references this table)
-- ============================================================================

create table store_users (
id uuid primary key default gen_random_uuid(),

store_id uuid,

auth_user_id uuid not null unique,

full_name text,
email text,
phone text,

role text not null default 'owner',

is_active boolean default true,

created_at timestamptz default now(),
updated_at timestamptz default now()

);

create index idx_store_users_auth on store_users(auth_user_id);

-- ============================================================================
-- STORES
-- ============================================================================

create table stores (
id uuid primary key default gen_random_uuid(),

owner_id uuid not null
references store_users(id)
on delete restrict,

name text not null,
slug text not null unique,

phone text,
email text,

description text,

gst_number text,
drug_license_number text,
pharmacist_name text,
pharmacist_registration_no text,

address text,
city text,
state text,
pincode text,

latitude double precision,
longitude double precision,

logo_url text,
banner_url text,

whatsapp_number text,

opening_time time,
closing_time time,

service_radius_km numeric(6,2) default 5,

minimum_order_amount integer default 0,

delivery_charge integer default 20,
free_delivery_above integer,

allow_cod boolean default true,
allow_manual_upi boolean default true,
allow_prescription_upload boolean default true,

module_pos boolean not null default true,
module_pickup boolean not null default false,
module_delivery boolean not null default false,

delivery_slots jsonb,

upi_id text,
upi_qr_url text,

is_open boolean default true,
is_active boolean default true,

accepts_online_orders boolean generated always as (module_pickup or module_delivery) stored,

-- Shop default. SKUs may inherit or override. Inventory stays in base units.
sale_policy text not null default 'loose_allowed'
  check (sale_policy in ('loose_allowed', 'pack_only', 'whole_only')),

onboarding_completed boolean default false,

created_at timestamptz default now(),
updated_at timestamptz default now()

);

alter table store_users
add constraint store_users_store_id_fkey
foreign key (store_id) references stores(id) on delete set null;

create index idx_stores_slug on stores(slug);
create index idx_stores_owner on stores(owner_id);
create index idx_stores_accepts_online_orders on stores(accepts_online_orders) where accepts_online_orders = true;
create index idx_store_users_store on store_users(store_id);

-- ============================================================================
-- CATEGORIES
-- ============================================================================

create table categories (
  id uuid primary key default gen_random_uuid(),

  name text not null,
  slug text not null unique,

  icon_url text,

  sort_order integer default 0,

  is_system boolean default true,
  is_active boolean default true,

  created_at timestamptz default now()
);

create index idx_categories_slug
on categories(slug);

insert into public.categories (name, slug, sort_order, is_system, is_active) values
  ('Tablets & Capsules', 'tablets-capsules', 10, true, true),
  ('Syrups & Liquids', 'syrups-liquids', 20, true, true),
  ('Drops', 'drops', 30, true, true),
  ('Injections', 'injections', 40, true, true),
  ('Creams & Ointments', 'creams-ointments', 50, true, true),
  ('Inhalers & Devices', 'inhalers-devices', 60, true, true),
  ('Surgical & Dressings', 'surgical', 70, true, true),
  ('Baby Care', 'baby-care', 80, true, true),
  ('Personal Care', 'personal-care', 90, true, true),
  ('Ayurvedic', 'ayurvedic', 100, true, true),
  ('OTC / FMCG', 'otc-fmcg', 110, true, true),
  ('Others', 'others', 120, true, true)
on conflict (slug) do nothing;

-- ============================================================================
-- STORE CATEGORY MAPPING
-- ============================================================================

create table store_categories (

  store_id uuid not null
  references stores(id)
  on delete cascade,

  category_id uuid not null
  references categories(id)
  on delete cascade,

  primary key(store_id, category_id)

);

-- ============================================================================
-- MASTER PRODUCTS
-- ============================================================================

create table master_products (

  id uuid primary key default gen_random_uuid(),

  category_id uuid
  references categories(id),

  name text not null,

  generic_name text,

  composition text,

  manufacturer text,

  strength text,

  dosage_form text,

  product_kind text not null default 'tablet_capsule'
    check (product_kind in ('tablet_capsule', 'liquid', 'topical', 'injectable', 'device', 'surgical', 'fmcg')),

  drug_schedule text not null default 'none'
    check (drug_schedule in ('none', 'otc', 'h', 'h1', 'x', 'c')),

  hsn_code text,

  gst_rate numeric(5,2) not null default 5.00,

  track_batch boolean not null default true,

  storage text not null default 'ambient'
    check (storage in ('ambient', 'refrigerated')),

  -- Packaging metadata only (inventory stays in smallest sellable unit)
  base_unit text,
  primary_pack_type text,
  primary_pack_quantity integer,
  secondary_pack_type text,
  secondary_pack_quantity integer,

  slug text not null,

  description text,

  image_url text,

  is_system boolean default true,

  approval_status text default 'approved',

  is_active boolean default true,

  created_at timestamptz default now(),
  updated_at timestamptz default now()

);

create index idx_master_products_category
on master_products(category_id);

create index idx_master_products_name
on master_products(name);

create index idx_master_products_name_trgm
on master_products using gin (name extensions.gin_trgm_ops);

create index idx_master_products_generic_trgm
on master_products using gin (generic_name extensions.gin_trgm_ops);

create index idx_master_products_composition_trgm
on master_products using gin (composition extensions.gin_trgm_ops);

-- ============================================================================
-- STORE PRODUCTS (listing + inventory projection)
-- ============================================================================

create table store_products (

  id uuid primary key default gen_random_uuid(),

  store_id uuid not null
  references stores(id)
  on delete cascade,

  product_id uuid not null
  references master_products(id),

  is_active boolean default true,

  is_featured boolean default false,

  sale_policy text not null default 'inherit'
    check (sale_policy in ('inherit', 'loose_allowed', 'pack_only', 'whole_only')),

  rack_location text,

  reorder_level integer not null default 0,

  on_hand_quantity integer not null default 0,

  reserved_quantity integer not null default 0,

  available_quantity integer generated always as (greatest(on_hand_quantity - reserved_quantity, 0)) stored,

  listing_mrp numeric(10,2),

  listing_selling_price numeric(10,2),

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique(store_id, product_id)

);

create index idx_store_products_store
on store_products(store_id);

create index idx_store_products_master
on store_products(product_id);

create index idx_store_products_store_active
on store_products(store_id)
where is_active = true;

-- ============================================================================
-- INVENTORY BATCHES
-- ============================================================================

create table inventory_batches (

  id uuid primary key default gen_random_uuid(),

  store_product_id uuid not null
  references store_products(id)
  on delete cascade,

  batch_no text,

  purchase_price numeric(10,2),

  mrp numeric(10,2) not null,

  selling_price numeric(10,2) not null,

  quantity integer not null,

  available_quantity integer not null,

  reserved_quantity integer not null default 0,

  manufactured_at date,

  expires_at date,

  created_at timestamptz default now(),

  check (available_quantity >= reserved_quantity),
  check (selling_price <= mrp)

);

create unique index idx_inventory_batches_store_product_batch_no
on inventory_batches (store_product_id, batch_no)
where batch_no is not null;

alter table store_products
add column listing_batch_id uuid references inventory_batches(id) on delete set null;

-- ============================================================================
-- CUSTOMERS (global; one record per phone across platform)
-- ============================================================================

create table customers (
  id uuid primary key default gen_random_uuid(),

  auth_user_id text,

  phone text not null unique,
  name text,

  email text,
  gender text,
  dob date,

  is_active boolean default true,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_customers_phone on customers(phone);
create index idx_customers_auth on customers(auth_user_id) where auth_user_id is not null;

-- ============================================================================
-- STORE CUSTOMERS (per-store CRM relationship + khata)
-- ============================================================================

create table store_customers (
  id uuid primary key default gen_random_uuid(),

  store_id uuid not null
  references stores(id)
  on delete cascade,

  customer_id uuid not null
  references customers(id)
  on delete cascade,

  notes text,

  loyalty_points integer default 0,
  total_orders integer default 0,
  total_spent numeric(10, 2) default 0,
  current_balance numeric(10,2) not null default 0,
  last_order_at timestamptz,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique(store_id, customer_id)
);

create index idx_store_customers_store on store_customers(store_id);
create index idx_store_customers_customer on store_customers(customer_id);

-- ============================================================================
-- SUPPLIERS
-- ============================================================================

create table suppliers (
  id uuid primary key default gen_random_uuid(),

  store_id uuid not null
  references stores(id)
  on delete cascade,

  name text not null,
  contact_person text,

  phone text,
  email text,

  gst_number text,
  drug_license_number text,

  address text,

  opening_balance numeric default 0,
  current_balance numeric default 0,
  payment_terms_days integer default 0,

  notes text,

  is_active boolean default true,

  last_purchase_at timestamptz,
  total_purchase_amount numeric default 0,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,

  unique(store_id, name)
);

create index idx_suppliers_store on suppliers(store_id);

-- ============================================================================
-- PURCHASE ORDERS
-- ============================================================================

create table purchase_orders (
  id uuid primary key default gen_random_uuid(),

  store_id uuid not null
  references stores(id)
  on delete cascade,

  supplier_id uuid not null
  references suppliers(id)
  on delete restrict,

  invoice_number text not null,
  invoice_date date not null default current_date,

  subtotal numeric(10,2) not null default 0,
  discount_amount numeric(10,2) not null default 0,
  tax_amount numeric(10,2) not null default 0,
  other_charges numeric(10,2) not null default 0,
  round_off_amount numeric(10,2) not null default 0,
  grand_total numeric(10,2) not null default 0,

  payment_status text not null default 'pending',
  payment_method text,
  paid_amount numeric(10,2) not null default 0,
  due_amount numeric(10,2) not null default 0,

  notes text,
  status text not null default 'draft',

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique(store_id, supplier_id, invoice_number)
);

create index idx_purchase_orders_store on purchase_orders(store_id);
create index idx_purchase_orders_supplier on purchase_orders(supplier_id);
create index idx_purchase_orders_status on purchase_orders(status);

-- ============================================================================
-- PURCHASE ORDER ITEMS
-- ============================================================================

create table purchase_order_items (
  id uuid primary key default gen_random_uuid(),

  purchase_order_id uuid not null
  references purchase_orders(id)
  on delete cascade,

  store_product_id uuid not null
  references store_products(id),

  batch_number text not null,
  quantity integer not null,

  purchase_price numeric(10,2) not null,
  mrp numeric(10,2) not null,
  selling_price numeric(10,2) not null,

  tax_percent numeric(5,2) default 0,
  discount_percent numeric(5,2) default 0,

  manufactured_at date,
  expires_at date,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_purchase_order_items_order on purchase_order_items(purchase_order_id);
create index idx_purchase_order_items_product on purchase_order_items(store_product_id);

-- ============================================================================
-- CUSTOMER ADDRESSES
-- ============================================================================

create table customer_addresses (
id uuid primary key default gen_random_uuid(),

customer_id uuid not null
references customers(id)
on delete cascade,

label text,

address_line_1 text not null,
address_line_2 text,

city text,
state text,
pincode text,

latitude double precision,
longitude double precision,

created_at timestamptz default now()

);

create index idx_customer_addresses_customer
on customer_addresses(customer_id);

-- ============================================================================
-- PRESCRIPTIONS
-- ============================================================================

create table prescriptions (
id uuid primary key default gen_random_uuid(),

customer_id uuid not null
references customers(id),

store_id uuid not null
references stores(id),

file_url text not null,

status text default 'pending',

pharmacist_user_id uuid
references store_users(id)
on delete set null,

reviewed_at timestamptz,

doctor_name text,
doctor_registration_no text,
patient_name text,
patient_address text,

created_at timestamptz default now()

);

-- ============================================================================
-- ORDERS
-- ============================================================================

create table orders (
id uuid primary key default gen_random_uuid(),

store_id uuid not null
references stores(id),

customer_id uuid not null
references customers(id),

prescription_id uuid
references prescriptions(id),

pharmacist_user_id uuid
references store_users(id)
on delete set null,

order_number bigint generated always as identity,

source text not null default 'pos'
  check (source in ('pos', 'online', 'kiosk')),

status text not null default 'pending',

payment_method text default 'cod',

payment_status text default 'pending',

fulfillment_type text
  check (fulfillment_type is null or fulfillment_type in ('counter', 'pickup', 'delivery')),

delivery_slot text,

estimated_delivery_at timestamptz,

actual_delivery_at timestamptz,

subtotal numeric(10,2) not null,

delivery_charge numeric(10,2) default 0,

discount_amount numeric(10,2) default 0,

total_amount numeric(10,2) not null,

customer_snapshot jsonb not null,

address_snapshot jsonb not null,

pricing_snapshot jsonb not null,

notes text,

placed_at timestamptz default now(),

created_at timestamptz default now(),
updated_at timestamptz default now()

);

create index idx_orders_store
on orders(store_id);

create index idx_orders_customer
on orders(customer_id);

create index idx_orders_status
on orders(status);

create index idx_orders_source
on orders(source);

create index idx_orders_placed_at
on orders(placed_at);

-- ============================================================================
-- ORDER ITEMS
-- ============================================================================

create table order_items (
id uuid primary key default gen_random_uuid(),

order_id uuid not null
references orders(id)
on delete cascade,

store_product_id uuid not null
references store_products(id),

quantity integer not null,

unit_price numeric(10,2) not null,

total_price numeric(10,2) not null,

product_snapshot jsonb not null,

fulfillment_snapshot jsonb,

created_at timestamptz default now()

);

create index idx_order_items_order
on order_items(order_id);

create index idx_order_items_store_product
on order_items(store_product_id);

-- ============================================================================
-- ORDER ITEM BATCHES
-- ============================================================================

create table order_item_batches (
id uuid primary key default gen_random_uuid(),

order_item_id uuid not null
references order_items(id)
on delete cascade,

batch_id uuid not null
references inventory_batches(id),

quantity integer not null,

created_at timestamptz default now()

);

create index idx_order_item_batches_item
on order_item_batches(order_item_id);

create index idx_order_item_batches_batch
on order_item_batches(batch_id);

-- ============================================================================
-- ORDER STATUS HISTORY (append-only)
-- ============================================================================

create table order_status_history (
id uuid primary key default gen_random_uuid(),

order_id uuid not null
references orders(id)
on delete cascade,

from_status text,

to_status text not null,

actor_id uuid,

notes text,

created_at timestamptz default now()

);

create index idx_order_status_history_order
on order_status_history(order_id);

create index idx_order_status_history_created
on order_status_history(created_at);

-- ============================================================================
-- INVENTORY TRANSACTIONS (audit log)
-- ============================================================================

create table inventory_transactions (
id uuid primary key default gen_random_uuid(),

store_id uuid not null
references stores(id)
on delete cascade,

store_product_id uuid not null
references store_products(id),

batch_id uuid
references inventory_batches(id),

type text not null,

quantity integer not null,

reference_type text not null,

reference_id uuid not null,

notes text,

created_at timestamptz default now()

);

create index idx_inventory_transactions_store
on inventory_transactions(store_id);

create index idx_inventory_transactions_product
on inventory_transactions(store_product_id);

create index idx_inventory_transactions_reference
on inventory_transactions(reference_type, reference_id);

-- ============================================================================
-- PAYMENTS (financial ledger)
-- ============================================================================

create table payments (
  id uuid primary key default gen_random_uuid(),

  store_id uuid not null
  references stores(id)
  on delete cascade,

  order_id uuid
  references orders(id)
  on delete set null,

  purchase_order_id uuid
  references purchase_orders(id)
  on delete set null,

  supplier_id uuid
  references suppliers(id)
  on delete set null,

  customer_id uuid
  references customers(id)
  on delete set null,

  payment_direction text not null,
  payment_type text not null,

  amount numeric(10,2) not null,

  method text not null,

  status text not null default 'pending',

  transaction_id text,
  reference_number text,

  paid_at timestamptz,

  notes text,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_payments_store on payments(store_id);
create index idx_payments_order on payments(order_id);
create index idx_payments_purchase on payments(purchase_order_id);
create index idx_payments_supplier on payments(supplier_id);
create index idx_payments_customer on payments(customer_id);
create index idx_payments_status on payments(status);

-- ============================================================================
-- RETURNS
-- ============================================================================

create table returns (
  id uuid primary key default gen_random_uuid(),

  store_id uuid not null
  references stores(id)
  on delete cascade,

  order_id uuid
  references orders(id)
  on delete set null,

  customer_id uuid
  references customers(id)
  on delete set null,

  return_type text not null default 'customer',

  status text not null default 'pending',

  reason text,
  notes text,

  subtotal numeric(10,2) not null default 0,
  refund_amount numeric(10,2) not null default 0,
  refund_status text not null default 'none',

  processed_by uuid
  references store_users(id)
  on delete set null,

  processed_at timestamptz,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table return_items (
  id uuid primary key default gen_random_uuid(),

  return_id uuid not null
  references returns(id)
  on delete cascade,

  order_item_id uuid
  references order_items(id)
  on delete set null,

  inventory_batch_id uuid
  references inventory_batches(id)
  on delete set null,

  quantity integer not null,

  unit_price numeric(10,2) not null default 0,
  refund_amount numeric(10,2) not null default 0,

  restock_action text not null default 'restock',
  condition text not null default 'sealed',

  created_at timestamptz default now()
);

create index idx_returns_store on returns(store_id);
create index idx_returns_order on returns(order_id);
create index idx_returns_customer on returns(customer_id);
create index idx_returns_status on returns(status);
create index idx_returns_refund_status on returns(refund_status);
create index idx_returns_created on returns(created_at);

create index idx_return_items_return on return_items(return_id);
create index idx_return_items_order_item on return_items(order_item_id);
create index idx_return_items_batch on return_items(inventory_batch_id);

-- ============================================================================
-- LISTING PROJECTION: keep store_products in sync with batches
-- ============================================================================

create or replace function refresh_store_product_listing()
returns trigger
language plpgsql
as $$
declare
  sp_id uuid;
  track boolean;
  fefo_id uuid;
  fefo_mrp numeric(10,2);
  fefo_price numeric(10,2);
  sum_on_hand integer;
  sum_reserved integer;
begin
  sp_id := coalesce(new.store_product_id, old.store_product_id);

  select mp.track_batch
    into track
  from store_products sp
  join master_products mp on mp.id = sp.product_id
  where sp.id = sp_id;

  if not coalesce(track, true) then
    return coalesce(new, old);
  end if;

  select
    coalesce(sum(ib.available_quantity), 0)::integer,
    coalesce(sum(ib.reserved_quantity), 0)::integer
  into sum_on_hand, sum_reserved
  from inventory_batches ib
  where ib.store_product_id = sp_id;

  select ib.id, ib.mrp, ib.selling_price
    into fefo_id, fefo_mrp, fefo_price
  from inventory_batches ib
  where ib.store_product_id = sp_id
    and (ib.available_quantity - ib.reserved_quantity) > 0
  order by ib.expires_at nulls last, ib.created_at
  limit 1;

  update store_products
  set
    on_hand_quantity = sum_on_hand,
    reserved_quantity = sum_reserved,
    listing_mrp = fefo_mrp,
    listing_selling_price = fefo_price,
    listing_batch_id = fefo_id,
    updated_at = now()
  where id = sp_id;

  return coalesce(new, old);
end;
$$;

create trigger trg_store_product_listing_from_batches
after insert or update or delete on inventory_batches
for each row
execute function refresh_store_product_listing();


-- ============================================================================
-- DATA PLANE: helpers, listing view, RLS, intent RPCs
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.auth_store_id()
returns uuid
language sql
stable
security definer
set search_path = public, extensions
as $$
  select su.store_id
  from public.store_users su
  where su.auth_user_id = auth.uid()
    and coalesce(su.is_active, true) = true
  limit 1;
$$;

create or replace function public.geo_distance_km(
  lat1 double precision,
  lng1 double precision,
  lat2 double precision,
  lng2 double precision
) returns double precision
language sql
immutable
parallel safe
as $$
  select case
    when lat1 is null or lng1 is null or lat2 is null or lng2 is null then null
    else 6371 * acos(least(1::double precision, greatest(-1::double precision,
      cos(radians(lat1)) * cos(radians(lat2)) * cos(radians(lng2) - radians(lng1))
      + sin(radians(lat1)) * sin(radians(lat2))
    )))
  end;
$$;

create or replace function public.listing_pack_label(
  p_base_unit text,
  p_pack_type text,
  p_pack_qty integer
) returns text
language plpgsql
immutable
as $$
declare
  qty integer := greatest(coalesce(p_pack_qty, 1), 1);
  pack text := nullif(btrim(coalesce(p_pack_type, '')), '');
  unit text := nullif(btrim(coalesce(p_base_unit, '')), '');
begin
  if pack is null and unit is null then
    return 'Unit';
  end if;
  if qty = 1 then
    if pack is not null and (unit is null or pack = unit) then
      return initcap(replace(pack, '_', ' '));
    end if;
    if pack is not null and unit is not null then
      return initcap(replace(pack, '_', ' ')) || ' of 1 ' || initcap(replace(unit, '_', ' '));
    end if;
    return initcap(replace(unit, '_', ' '));
  end if;
  if pack is not null then
    return initcap(replace(pack, '_', ' '))
      || ' of ' || qty || ' ' || initcap(replace(coalesce(unit, 'unit'), '_', ' '));
  end if;
  return qty::text || ' ' || initcap(replace(unit, '_', ' '));
end;
$$;

create or replace view public.v_listing_cards as
select
  sp.id,
  sp.store_id,
  sp.product_id,
  mp.slug,
  mp.name,
  mp.generic_name,
  mp.manufacturer,
  mp.composition,
  mp.description,
  mp.image_url as thumb,
  mp.image_url,
  public.listing_pack_label(mp.base_unit, mp.primary_pack_type, mp.primary_pack_quantity) as pack_label,
  mp.base_unit,
  mp.primary_pack_type,
  mp.primary_pack_quantity,
  mp.secondary_pack_type,
  mp.secondary_pack_quantity,
  mp.dosage_form,
  mp.strength,
  sp.listing_mrp as mrp,
  sp.listing_selling_price as selling_price,
  mp.base_unit as unit,
  (sp.available_quantity > 0) as in_stock,
  sp.available_quantity,
  sp.on_hand_quantity,
  sp.reserved_quantity,
  sp.reorder_level,
  sp.rack_location,
  sp.sale_policy,
  mp.drug_schedule as schedule,
  mp.product_kind as kind,
  mp.category_id,
  c.name as category_name,
  c.slug as category_slug,
  sp.is_featured,
  sp.is_active,
  (mp.drug_schedule in ('h', 'h1', 'x', 'c')) as requires_prescription,
  mp.gst_rate,
  mp.hsn_code,
  mp.track_batch,
  mp.storage,
  mp.is_system,
  sp.created_at,
  sp.updated_at
from public.store_products sp
join public.master_products mp on mp.id = sp.product_id
left join public.categories c on c.id = mp.category_id;

-- ---------------------------------------------------------------------------
-- RLS: deny anon (no policies). Authenticated owners keep table CRUD.
-- Privileges are locked down at the end of this file after all RPCs exist.
-- ---------------------------------------------------------------------------

grant usage on schema public to anon, authenticated, service_role;

do $$
declare
  t text;
begin
  foreach t in array array[
    'store_users',
    'stores',
    'categories',
    'store_categories',
    'master_products',
    'store_products',
    'inventory_batches',
    'customers',
    'store_customers',
    'suppliers',
    'purchase_orders',
    'purchase_order_items',
    'customer_addresses',
    'prescriptions',
    'orders',
    'order_items',
    'order_item_batches',
    'order_status_history',
    'inventory_transactions',
    'payments',
    'returns',
    'return_items'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end;
$$;

drop policy if exists store_users_select on public.store_users;
create policy store_users_select on public.store_users
  for select to authenticated
  using (auth_user_id = auth.uid() or store_id = public.auth_store_id());

drop policy if exists store_users_insert on public.store_users;
create policy store_users_insert on public.store_users
  for insert to authenticated
  with check (auth_user_id = auth.uid());

drop policy if exists store_users_update on public.store_users;
create policy store_users_update on public.store_users
  for update to authenticated
  using (auth_user_id = auth.uid() or store_id = public.auth_store_id())
  with check (auth_user_id = auth.uid() or store_id = public.auth_store_id());

drop policy if exists stores_select on public.stores;
create policy stores_select on public.stores
  for select to authenticated
  using (
    id = public.auth_store_id()
    or owner_id in (select su.id from public.store_users su where su.auth_user_id = auth.uid())
  );

drop policy if exists stores_insert on public.stores;
create policy stores_insert on public.stores
  for insert to authenticated
  with check (
    owner_id in (select su.id from public.store_users su where su.auth_user_id = auth.uid())
  );

drop policy if exists stores_update on public.stores;
create policy stores_update on public.stores
  for update to authenticated
  using (
    id = public.auth_store_id()
    or owner_id in (select su.id from public.store_users su where su.auth_user_id = auth.uid())
  )
  with check (
    id = public.auth_store_id()
    or owner_id in (select su.id from public.store_users su where su.auth_user_id = auth.uid())
  );

drop policy if exists categories_select on public.categories;
create policy categories_select on public.categories
  for select to authenticated
  using (true);

drop policy if exists categories_write on public.categories;
create policy categories_write on public.categories
  for all to authenticated
  using (true)
  with check (true);

drop policy if exists store_categories_member on public.store_categories;
create policy store_categories_member on public.store_categories
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists master_products_select on public.master_products;
create policy master_products_select on public.master_products
  for select to authenticated
  using (true);

drop policy if exists master_products_insert on public.master_products;
create policy master_products_insert on public.master_products
  for insert to authenticated
  with check (true);

drop policy if exists master_products_update on public.master_products;
create policy master_products_update on public.master_products
  for update to authenticated
  using (coalesce(is_system, false) = false)
  with check (coalesce(is_system, false) = false);

drop policy if exists store_products_member on public.store_products;
create policy store_products_member on public.store_products
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists inventory_batches_member on public.inventory_batches;
create policy inventory_batches_member on public.inventory_batches
  for all to authenticated
  using (
    exists (
      select 1 from public.store_products sp
      where sp.id = inventory_batches.store_product_id
        and sp.store_id = public.auth_store_id()
    )
  )
  with check (
    exists (
      select 1 from public.store_products sp
      where sp.id = inventory_batches.store_product_id
        and sp.store_id = public.auth_store_id()
    )
  );

drop policy if exists customers_authenticated on public.customers;
create policy customers_authenticated on public.customers
  for all to authenticated
  using (true)
  with check (true);

drop policy if exists store_customers_member on public.store_customers;
create policy store_customers_member on public.store_customers
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists suppliers_member on public.suppliers;
create policy suppliers_member on public.suppliers
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists purchase_orders_member on public.purchase_orders;
create policy purchase_orders_member on public.purchase_orders
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists purchase_order_items_member on public.purchase_order_items;
create policy purchase_order_items_member on public.purchase_order_items
  for all to authenticated
  using (
    exists (
      select 1 from public.purchase_orders po
      where po.id = purchase_order_items.purchase_order_id
        and po.store_id = public.auth_store_id()
    )
  )
  with check (
    exists (
      select 1 from public.purchase_orders po
      where po.id = purchase_order_items.purchase_order_id
        and po.store_id = public.auth_store_id()
    )
  );

drop policy if exists customer_addresses_authenticated on public.customer_addresses;
create policy customer_addresses_authenticated on public.customer_addresses
  for all to authenticated
  using (
    exists (
      select 1 from public.store_customers sc
      where sc.customer_id = customer_addresses.customer_id
        and sc.store_id = public.auth_store_id()
    )
  )
  with check (
    exists (
      select 1 from public.store_customers sc
      where sc.customer_id = customer_addresses.customer_id
        and sc.store_id = public.auth_store_id()
    )
  );

drop policy if exists prescriptions_member on public.prescriptions;
create policy prescriptions_member on public.prescriptions
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists orders_member on public.orders;
create policy orders_member on public.orders
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists order_items_member on public.order_items;
create policy order_items_member on public.order_items
  for all to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.store_id = public.auth_store_id()
    )
  )
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.store_id = public.auth_store_id()
    )
  );

drop policy if exists order_item_batches_member on public.order_item_batches;
create policy order_item_batches_member on public.order_item_batches
  for all to authenticated
  using (
    exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      where oi.id = order_item_batches.order_item_id
        and o.store_id = public.auth_store_id()
    )
  )
  with check (
    exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      where oi.id = order_item_batches.order_item_id
        and o.store_id = public.auth_store_id()
    )
  );

drop policy if exists order_status_history_member on public.order_status_history;
create policy order_status_history_member on public.order_status_history
  for all to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_status_history.order_id
        and o.store_id = public.auth_store_id()
    )
  )
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_status_history.order_id
        and o.store_id = public.auth_store_id()
    )
  );

drop policy if exists inventory_transactions_member on public.inventory_transactions;
create policy inventory_transactions_member on public.inventory_transactions
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists payments_member on public.payments;
create policy payments_member on public.payments
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists returns_member on public.returns;
create policy returns_member on public.returns
  for all to authenticated
  using (store_id = public.auth_store_id())
  with check (store_id = public.auth_store_id());

drop policy if exists return_items_member on public.return_items;
create policy return_items_member on public.return_items
  for all to authenticated
  using (
    exists (
      select 1 from public.returns r
      where r.id = return_items.return_id
        and r.store_id = public.auth_store_id()
    )
  )
  with check (
    exists (
      select 1 from public.returns r
      where r.id = return_items.return_id
        and r.store_id = public.auth_store_id()
    )
  );

-- ---------------------------------------------------------------------------
-- Intent RPCs (SECURITY DEFINER). Anon may execute public listing only.
-- ---------------------------------------------------------------------------

create or replace function public.public_store_json(s public.stores)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'id', s.id,
    'name', s.name,
    'slug', s.slug,
    'phone', s.phone,
    'description', s.description,
    'address', s.address,
    'city', s.city,
    'state', s.state,
    'pincode', s.pincode,
    'latitude', s.latitude,
    'longitude', s.longitude,
    'logo_url', s.logo_url,
    'banner_url', s.banner_url,
    'whatsapp_number', s.whatsapp_number,
    'opening_time', s.opening_time,
    'closing_time', s.closing_time,
    'service_radius_km', s.service_radius_km,
    'minimum_order_amount', s.minimum_order_amount,
    'delivery_charge', s.delivery_charge,
    'free_delivery_above', s.free_delivery_above,
    'allow_cod', s.allow_cod,
    'allow_manual_upi', s.allow_manual_upi,
    'allow_prescription_upload', s.allow_prescription_upload,
    'module_pickup', s.module_pickup,
    'module_delivery', s.module_delivery,
    'upi_id', s.upi_id,
    'upi_qr_url', s.upi_qr_url,
    'is_open', s.is_open,
    'accepts_online_orders', s.accepts_online_orders,
    'sale_policy', s.sale_policy
  );
$$;

create or replace function public.store_categories_json(p_store_id uuid)
returns jsonb
language sql
stable
as $$
  select coalesce(
    jsonb_agg(jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'slug', c.slug,
      'icon_url', c.icon_url,
      'sort_order', c.sort_order,
      'is_system', c.is_system,
      'is_active', c.is_active,
      'created_at', c.created_at
    ) order by c.sort_order, c.name),
    '[]'::jsonb
  )
  from public.store_categories sc
  join public.categories c on c.id = sc.category_id
  where sc.store_id = p_store_id
    and coalesce(c.is_active, true) = true;
$$;

create or replace function public.get_store_shell(
  p_slug text default null,
  p_store_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  s public.stores;
begin
  if p_store_id is not null then
    select * into s from public.stores where id = p_store_id;
  elsif p_slug is not null and btrim(p_slug) <> '' then
    select * into s from public.stores where slug = lower(btrim(p_slug));
  else
    return jsonb_build_object('status', 'not_found', 'store', null, 'categories', '[]'::jsonb);
  end if;

  if not found then
    return jsonb_build_object('status', 'not_found', 'store', null, 'categories', '[]'::jsonb);
  end if;

  if not coalesce(s.is_active, true) then
    return jsonb_build_object('status', 'not_found', 'store', null, 'categories', '[]'::jsonb);
  end if;

  if not coalesce(s.accepts_online_orders, false) then
    return jsonb_build_object(
      'status', 'unavailable',
      'store', public.public_store_json(s),
      'categories', '[]'::jsonb
    );
  end if;

  return jsonb_build_object(
    'status', 'ok',
    'store', public.public_store_json(s),
    'categories', public.store_categories_json(s.id)
  );
end;
$$;

create or replace function public.get_store_home(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  shell jsonb;
  store_id uuid;
  featured jsonb;
  products jsonb;
begin
  shell := public.get_store_shell(p_slug, null);
  if shell->>'status' is distinct from 'ok' then
    return shell;
  end if;

  store_id := (shell->'store'->>'id')::uuid;

  select coalesce(jsonb_agg(to_jsonb(v)), '[]'::jsonb)
    into featured
  from (
    select v.*
    from public.v_listing_cards v
    where v.store_id = store_id
      and v.is_active = true
      and v.is_featured = true
      and v.schedule is distinct from 'x'
    order by v.available_quantity desc, v.name
    limit 12
  ) v;

  select coalesce(jsonb_agg(to_jsonb(v)), '[]'::jsonb)
    into products
  from (
    select v.*
    from public.v_listing_cards v
    where v.store_id = store_id
      and v.is_active = true
      and v.schedule is distinct from 'x'
    order by v.in_stock desc, v.is_featured desc, v.available_quantity desc, v.name
    limit 24
  ) v;

  return shell || jsonb_build_object('featured', featured, 'products', products);
end;
$$;

create or replace function public.search_store_catalog(
  p_store_id uuid,
  p_query text default '',
  p_category_id uuid default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  s public.stores;
  term text := btrim(coalesce(p_query, ''));
  lim integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  result jsonb;
begin
  select * into s from public.stores where id = p_store_id;
  if not found or not coalesce(s.is_active, true) or not coalesce(s.accepts_online_orders, false) then
    return '[]'::jsonb;
  end if;

  if term = '' and p_category_id is null then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(to_jsonb(v)), '[]'::jsonb)
    into result
  from (
    select v.*
    from public.v_listing_cards v
    where v.store_id = p_store_id
      and v.is_active = true
      and v.schedule is distinct from 'x'
      and (p_category_id is null or v.category_id = p_category_id)
      and (
        term = ''
        or v.name ilike '%' || term || '%'
        or coalesce(v.generic_name, '') ilike '%' || term || '%'
        or coalesce(v.composition, '') ilike '%' || term || '%'
        or coalesce(v.manufacturer, '') ilike '%' || term || '%'
      )
    order by
      case when term <> '' then similarity(v.name, term) else 0 end desc,
      v.in_stock desc,
      v.name
    limit lim
  ) v;

  return result;
end;
$$;

create or replace function public.list_nearby_stores(
  p_lat double precision,
  p_lng double precision,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  lim integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  result jsonb;
begin
  if p_lat is null or p_lng is null then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(q.item), '[]'::jsonb)
    into result
  from (
    select public.public_store_json(s) || jsonb_build_object(
      'distance_km', round(public.geo_distance_km(p_lat, p_lng, s.latitude, s.longitude)::numeric, 2)
    ) as item
    from public.stores s
    where coalesce(s.is_active, true) = true
      and coalesce(s.accepts_online_orders, false) = true
      and s.latitude is not null
      and s.longitude is not null
      and public.geo_distance_km(p_lat, p_lng, s.latitude, s.longitude) <= coalesce(s.service_radius_km, 5)
    order by public.geo_distance_km(p_lat, p_lng, s.latitude, s.longitude)
    limit lim
  ) q;

  return result;
end;
$$;

create or replace function public.list_system_categories()
returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select coalesce(
    jsonb_agg(jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'slug', c.slug,
      'icon_url', c.icon_url,
      'sort_order', c.sort_order,
      'is_system', c.is_system,
      'is_active', c.is_active,
      'created_at', c.created_at
    ) order by c.sort_order, c.name),
    '[]'::jsonb
  )
  from public.categories c
  where coalesce(c.is_system, true) = true
    and coalesce(c.is_active, true) = true;
$$;

create or replace function public.get_listing_cards(
  p_store_id uuid,
  p_ids uuid[]
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  s public.stores;
  result jsonb;
begin
  select * into s from public.stores where id = p_store_id;
  if not found or not coalesce(s.accepts_online_orders, false) then
    return '[]'::jsonb;
  end if;
  if p_ids is null or array_length(p_ids, 1) is null then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(to_jsonb(v)), '[]'::jsonb)
    into result
  from public.v_listing_cards v
  where v.store_id = p_store_id
    and v.id = any (p_ids)
    and v.schedule is distinct from 'x';

  return result;
end;
$$;

create or replace function public.get_store_product(
  p_store_id uuid,
  p_slug text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  s public.stores;
  card jsonb;
begin
  select * into s from public.stores where id = p_store_id;
  if not found or not coalesce(s.is_active, true) or not coalesce(s.accepts_online_orders, false) then
    return null;
  end if;

  select to_jsonb(v)
    into card
  from public.v_listing_cards v
  where v.store_id = p_store_id
    and v.slug = p_slug
    and v.is_active = true
    and v.schedule is distinct from 'x'
  limit 1;

  return card;
end;
$$;

create or replace function public.search_marketplace_products(
  p_store_ids uuid[],
  p_query text default '',
  p_category_id uuid default null,
  p_limit integer default 30
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  term text := btrim(coalesce(p_query, ''));
  lim integer := least(greatest(coalesce(p_limit, 30), 1), 50);
  result jsonb;
begin
  if p_store_ids is null or array_length(p_store_ids, 1) is null then
    return '[]'::jsonb;
  end if;
  if term = '' and p_category_id is null then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(to_jsonb(v)), '[]'::jsonb)
    into result
  from (
    select
      v.*,
      st.name as store_name,
      st.slug as store_slug
    from public.v_listing_cards v
    join public.stores st on st.id = v.store_id
    where v.store_id = any (p_store_ids)
      and coalesce(st.is_active, true) = true
      and coalesce(st.accepts_online_orders, false) = true
      and v.is_active = true
      and v.schedule is distinct from 'x'
      and (p_category_id is null or v.category_id = p_category_id)
      and (
        term = ''
        or v.name ilike '%' || term || '%'
        or coalesce(v.generic_name, '') ilike '%' || term || '%'
        or coalesce(v.composition, '') ilike '%' || term || '%'
      )
    order by v.in_stock desc, v.name
    limit lim
  ) v;

  return result;
end;
$$;

create or replace function public.get_pos_home(p_limit integer default 50)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  sid uuid := public.auth_store_id();
  lim integer := least(greatest(coalesce(p_limit, 50), 1), 80);
  products jsonb;
begin
  if sid is null then
    raise exception 'Not authorized';
  end if;

  select coalesce(jsonb_agg(to_jsonb(v)), '[]'::jsonb)
    into products
  from (
    select v.*
    from public.v_listing_cards v
    where v.store_id = sid
      and v.is_active = true
    order by v.in_stock desc, v.is_featured desc, v.available_quantity desc, v.name
    limit lim
  ) v;

  return jsonb_build_object('products', products);
end;
$$;

create or replace function public.search_pos_catalog(
  p_query text,
  p_limit integer default 30
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  sid uuid := public.auth_store_id();
  term text := btrim(coalesce(p_query, ''));
  lim integer := least(greatest(coalesce(p_limit, 30), 1), 50);
  products jsonb;
begin
  if sid is null then
    raise exception 'Not authorized';
  end if;
  if term = '' then
    return public.get_pos_home(lim);
  end if;

  select coalesce(jsonb_agg(to_jsonb(v)), '[]'::jsonb)
    into products
  from (
    select v.*
    from public.v_listing_cards v
    where v.store_id = sid
      and v.is_active = true
      and (
        v.name ilike '%' || term || '%'
        or coalesce(v.generic_name, '') ilike '%' || term || '%'
        or coalesce(v.composition, '') ilike '%' || term || '%'
        or coalesce(v.manufacturer, '') ilike '%' || term || '%'
        or coalesce(v.category_name, '') ilike '%' || term || '%'
      )
    order by similarity(v.name, term) desc, v.in_stock desc, v.name
    limit lim
  ) v;

  return jsonb_build_object('products', products);
end;
$$;

create or replace function public.list_store_inventory(
  p_query text default '',
  p_category_id uuid default null,
  p_status text default 'all',
  p_rx text default 'all',
  p_stock text default 'all',
  p_sort text default 'name',
  p_sort_dir text default 'asc',
  p_offset integer default 0,
  p_limit integer default 25
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  sid uuid := public.auth_store_id();
  term text := btrim(coalesce(p_query, ''));
  lim integer := least(greatest(coalesce(p_limit, 25), 1), 50);
  off integer := greatest(coalesce(p_offset, 0), 0);
  sort_dir text := case when lower(coalesce(p_sort_dir, 'asc')) = 'desc' then 'desc' else 'asc' end;
  total integer;
  items jsonb;
begin
  if sid is null then
    raise exception 'Not authorized';
  end if;

  select
    coalesce(jsonb_agg(q.card), '[]'::jsonb),
    coalesce(max(q.full_count), 0)
  into items, total
  from (
    select
      to_jsonb(f) - 'full_count' as card,
      f.full_count
    from (
      select
        v.*,
        count(*) over() as full_count
      from public.v_listing_cards v
      where v.store_id = sid
        and (term = ''
          or v.name ilike '%' || term || '%'
          or coalesce(v.generic_name, '') ilike '%' || term || '%'
          or coalesce(v.manufacturer, '') ilike '%' || term || '%')
        and (p_category_id is null or v.category_id = p_category_id)
        and (
          coalesce(p_status, 'all') = 'all'
          or (p_status = 'active' and v.is_active)
          or (p_status = 'inactive' and not v.is_active)
        )
        and (
          coalesce(p_rx, 'all') = 'all'
          or (p_rx = 'rx' and v.requires_prescription)
          or (p_rx = 'otc' and not v.requires_prescription)
        )
        and (
          coalesce(p_stock, 'all') = 'all'
          or (p_stock = 'in_stock' and v.available_quantity > 0)
          or (p_stock = 'out_of_stock' and v.available_quantity <= 0)
          or (p_stock = 'low_stock' and v.available_quantity > 0 and v.available_quantity <= 5)
        )
      order by
        case when sort_dir = 'asc' then
          case coalesce(p_sort, 'name')
            when 'category' then v.category_name
            when 'manufacturer' then v.manufacturer
            else v.name
          end
        end asc nulls last,
        case when sort_dir = 'desc' then
          case coalesce(p_sort, 'name')
            when 'category' then v.category_name
            when 'manufacturer' then v.manufacturer
            else v.name
          end
        end desc nulls last,
        case when sort_dir = 'asc' and coalesce(p_sort, 'name') = 'stock' then v.available_quantity end asc,
        case when sort_dir = 'desc' and coalesce(p_sort, 'name') = 'stock' then v.available_quantity end desc,
        case when sort_dir = 'asc' and coalesce(p_sort, 'name') in ('updated', 'created') then v.updated_at end asc,
        case when sort_dir = 'desc' and coalesce(p_sort, 'name') in ('updated', 'created') then v.updated_at end desc,
        v.name
      offset off
      limit lim
    ) f
  ) q;

  return jsonb_build_object('items', coalesce(items, '[]'::jsonb), 'total', coalesce(total, 0));
end;
$$;

-- Additive replace. Re-run this function on an existing project after paste.
create or replace function public.get_store_dashboard_counts()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  sid uuid := public.auth_store_id();
begin
  if sid is null then
    raise exception 'Not authorized';
  end if;

  return jsonb_build_object(
    'products', (select count(*) from public.store_products sp where sp.store_id = sid),
    'categories', (select count(*) from public.store_categories sc where sc.store_id = sid),
    'customers', (select count(*) from public.store_customers sc where sc.store_id = sid),
    'orders', (select count(*) from public.orders o where o.store_id = sid),
    'inventory_units', (
      select coalesce(sum(sp.available_quantity), 0)
      from public.store_products sp
      where sp.store_id = sid
    ),
    'inventory_value', (
      select coalesce(sum(ib.available_quantity * ib.selling_price), 0)
      from public.inventory_batches ib
      join public.store_products sp on sp.id = ib.store_product_id
      where sp.store_id = sid
    ),
    'low_stock', (
      select count(*)
      from public.store_products sp
      where sp.store_id = sid
        and sp.available_quantity > 0
        and sp.available_quantity <= 5
    ),
    'expiring_batches', (
      select count(*)
      from public.inventory_batches ib
      join public.store_products sp on sp.id = ib.store_product_id
      where sp.store_id = sid
        and ib.available_quantity > 0
        and ib.expires_at is not null
        and ib.expires_at <= (current_date + 30)
    ),
    'today_sales', (
      select coalesce(sum(o.total_amount), 0)
      from public.orders o
      where o.store_id = sid
        and o.status not in ('cancelled', 'draft', 'refunded')
        and (o.placed_at at time zone 'Asia/Kolkata')::date
            = (timezone('Asia/Kolkata', now()))::date
    ),
    'today_cash', (
      select coalesce(sum(o.total_amount), 0)
      from public.orders o
      where o.store_id = sid
        and o.status not in ('cancelled', 'draft', 'refunded')
        and o.payment_method = 'cash'
        and (o.placed_at at time zone 'Asia/Kolkata')::date
            = (timezone('Asia/Kolkata', now()))::date
    ),
    'today_order_count', (
      select count(*)
      from public.orders o
      where o.store_id = sid
        and o.status not in ('cancelled', 'draft', 'refunded')
        and (o.placed_at at time zone 'Asia/Kolkata')::date
            = (timezone('Asia/Kolkata', now()))::date
    ),
    'pending_online_orders', (
      select count(*)
      from public.orders o
      where o.store_id = sid
        and o.source = 'online'
        and o.status in ('pending', 'confirmed', 'processing', 'ready')
    )
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges: merchant table CRUD, anon listing RPCs only
-- ---------------------------------------------------------------------------

grant all on all tables in schema public to postgres, authenticated, service_role;
grant all on all sequences in schema public to postgres, authenticated, service_role;

revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
revoke all on public.v_listing_cards from anon, authenticated, public;

revoke all on all functions in schema public from public;
revoke all on all functions in schema public from anon;

grant execute on function public.auth_store_id() to authenticated;
grant execute on function public.geo_distance_km(double precision, double precision, double precision, double precision) to anon, authenticated;
grant execute on function public.get_store_shell(text, uuid) to anon, authenticated;
grant execute on function public.get_store_home(text) to anon, authenticated;
grant execute on function public.search_store_catalog(uuid, text, uuid, integer) to anon, authenticated;
grant execute on function public.list_nearby_stores(double precision, double precision, integer) to anon, authenticated;
grant execute on function public.list_system_categories() to anon, authenticated;
grant execute on function public.get_listing_cards(uuid, uuid[]) to anon, authenticated;
grant execute on function public.get_store_product(uuid, text) to anon, authenticated;
grant execute on function public.search_marketplace_products(uuid[], text, uuid, integer) to anon, authenticated;
grant execute on function public.get_pos_home(integer) to authenticated;
grant execute on function public.search_pos_catalog(text, integer) to authenticated;
grant execute on function public.list_store_inventory(text, uuid, text, text, text, text, text, integer, integer) to authenticated;
grant execute on function public.get_store_dashboard_counts() to authenticated;

-- ---------------------------------------------------------------------------
-- Storage: public image bucket used by store logos / banners / UPI QR
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'med-images',
  'med-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
)
on conflict (id) do nothing;

drop policy if exists "Public read med-images" on storage.objects;
create policy "Public read med-images"
on storage.objects
for select
to public
using (bucket_id = 'med-images');

drop policy if exists "Service role write med-images" on storage.objects;
create policy "Service role write med-images"
on storage.objects
for all
to service_role
using (bucket_id = 'med-images')
with check (bucket_id = 'med-images');
