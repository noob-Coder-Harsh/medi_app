# Architecture of the web product (as of 31 October 2026)

Source: `D:\code_files\nextjs\medsahayta`. The app should treat this as the live contract unless the web schema changes.

## Stack

| Layer | Choice |
| --- | --- |
| Web host | Next.js 16 on Vercel — HTML and **thin writes**. Catalog/search/nearby/POS seed must not sit on the Next CPU path |
| Database | Supabase Postgres. One paste: `schema.sql`. No numbered migrations |
| Owner auth | Supabase Auth email/password. `auth.uid()` → `store_users` → RLS |
| Customer auth | Firebase phone OTP. Next verifies session cookie (`firebase_session`, 5 days) and upserts `customers` |
| Listing | Browser → Supabase **intent RPCs**. Card payloads only |
| Owner writes | Authenticated table access under RLS until those paths become RPCs |
| Online checkout | Still Next + Firebase. Stock-reserve RPC is **not** in this bootstrap |
| State | Zustand (cart, workspace catalog cache) + TanStack Query (listing RPCs) |
| i18n | `en` / `hi` JSON, cookie `ms_locale` |
| Images | Public bucket `med-images` (5 MB, jpeg/png/webp/gif) |
| PWA | Install prompt after a successful order/bill, not on first visit |

Required env (see `web-source/env.example`):

- `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- Firebase public keys + `FIREBASE_SERVICE_ACCOUNT`

A Flutter client uses the **same** Supabase RPCs as the web browser (same names, args, `ListingCard`). It does not get a mobile-only RPC layer. Writes go through Next `/api/app` (Firebase bearer for customers, Supabase bearer for staff). Flutter does not INSERT/UPDATE/DELETE business tables. Full split: [DATA_PLANE.md](./DATA_PLANE.md).

**App shell (locked):** one Flutter binary. Public door is **location → nearest shop** (guest). Cart is local prefs. Firebase OTP only when writing. Long-press the **location-screen logo** opens staff email/password. Details: [APP_SHAPE.md](./APP_SHAPE.md), [BUILD_PLAN.md](./BUILD_PLAN.md).

## Data-plane rule

```
Anon     → GRANT EXECUTE on public listing RPCs only. No table SELECT.
Owner    → JWT. POS/inventory/dashboard listing RPCs.
         → Other staff lists: read-only SELECT under RLS until a shared list RPC exists.
Customer → Guest listing = anon RPCs. “My” rows (orders, addresses) = Next + Firebase.
Writes   → Next only (web actions today; /api/app for Flutter). Not from the Flutter client.
```

Middleware refreshes the owner session only on `/admin`, `/dashboard`, `/settings`, `/onboarding`, `/auth/store`.

## Auth flows

**Owner**

1. Email/password against Supabase.
2. `/api/store-user/ensure` ties `auth.uid()` to `store_users`.
3. Onboarding creates `stores` and copies system categories into `store_categories`.
4. `stores.owner_id` → `store_users.id` (circular FK resolved after both rows exist).

**Customer**

1. Firebase phone OTP on device.
2. `POST /api/customer/session` with Firebase `idToken` → httpOnly session cookie.
3. Server upserts `customers` by phone (`auth_user_id` is Firebase uid as text).
4. `store_customers` is the per-shop CRM + khata (`current_balance`, loyalty, totals).

Do not move owner auth to Firebase. Do not move customer auth to Supabase.

## Schema map

Full SQL: [`web-source/schema.sql`](./web-source/schema.sql). Typed contract: [`web-source/database.ts`](./web-source/database.ts).

```
store_users 1───1 stores (owner)     categories (system seeds)
     │              │                      │
     │              ├── store_categories ──┘
     │              ├── store_products ── master_products
     │              │         └── inventory_batches  (FEFO listing projection)
     │              ├── suppliers ── purchase_orders ── purchase_order_items
     │              ├── store_customers ── customers ── customer_addresses
     │              ├── prescriptions
     │              ├── orders ── order_items ── order_item_batches
     │              │         └── order_status_history
     │              ├── inventory_transactions
     │              ├── payments
     │              └── returns ── return_items
```

### Tables (21)

| Table | Role |
| --- | --- |
| `store_users` | Shop staff. `auth_user_id` unique. Role default `owner`. Types also name manager/staff/delivery — UI is owner-only |
| `stores` | Shop. Slug unique. Modules: `module_pos` (default true), `module_pickup`, `module_delivery`. Generated `accepts_online_orders` |
| `categories` | Platform catalogue. 12 system seeds (tablets, syrups, drops, …) |
| `store_categories` | Which of those the shop uses |
| `master_products` | Medicine identity (name, salt, pack metadata, schedule, GST). System or shop-created |
| `store_products` | Listing + inventory projection per shop. Unique `(store_id, product_id)` |
| `inventory_batches` | Warehouse. MRP, selling price, qty, expiry. Trigger refreshes listing FEFO fields on `store_products` |
| `customers` | Global, unique phone |
| `store_customers` | Per-shop CRM + udhaar balance |
| `suppliers` | Per-shop |
| `purchase_orders` / `purchase_order_items` | Stock in |
| `customer_addresses` | Delivery |
| `prescriptions` | File URL + review status (upload not fully shipped) |
| `orders` | POS / online / kiosk. Snapshots of customer, address, pricing |
| `order_items` | Line + product snapshot |
| `order_item_batches` | FEFO allocation |
| `order_status_history` | Append-only |
| `inventory_transactions` | Audit |
| `payments` | Inflow/outflow ledger (sale, purchase, refund, supplier) |
| `returns` / `return_items` | Customer/supplier/damage/expiry |

### Important store columns

- Identity: name, slug, phone, GST, drug licence, pharmacist, address, lat/lng, logo, banner, WhatsApp
- Hours: `opening_time`, `closing_time`, `is_open`, `is_active`
- Commerce: `service_radius_km` (default 5), `minimum_order_amount`, `delivery_charge`, `free_delivery_above`, `allow_cod`, `allow_manual_upi`, `allow_prescription_upload`, `upi_id`, `upi_qr_url`, `delivery_slots`
- `sale_policy`: `loose_allowed` (default) \| `pack_only` \| `whole_only`

### Master product vs store product

- Kind: `tablet_capsule` \| `liquid` \| `topical` \| `injectable` \| `device` \| `surgical` \| `fmcg`
- Schedule: `none` \| `otc` \| `h` \| `h1` \| `x` \| `c`
- Storage: `ambient` \| `refrigerated`
- Pack metadata: `base_unit`, `primary_pack_*`, `secondary_pack_*`
- `store_products.sale_policy` may be `inherit`
- Quantities: `on_hand_quantity`, `reserved_quantity`, generated `available_quantity`

### Orders

- `source`: `pos` \| `online` \| `kiosk`
- `status`: `draft` \| `pending` \| `confirmed` \| `processing` \| `ready` \| `out_for_delivery` \| `delivered` \| `cancelled` \| `refunded`
- `fulfillment_type`: `counter` \| `pickup` \| `delivery`
- `payment_method` default `cod`. POS also uses cash/upi/card/credit/mixed
- `order_number` is a bigint identity (not a formatted string)

## Listing RPCs (app can call these the same way)

Public (anon + authenticated):

| RPC | Use |
| --- | --- |
| `get_store_shell(slug \| id)` | Shop + categories. Status `ok` / `not_found` / `unavailable` |
| `get_store_home(slug)` | Shell + featured (12) + products (24). Hides schedule X |
| `search_store_catalog(store_id, query, category, limit)` | Shop search. Empty query+category → `[]` |
| `list_nearby_stores(lat, lng, limit)` | Within each shop’s `service_radius_km` |
| `list_system_categories()` | 12 seeds |
| `get_listing_cards(store_id, ids[])` | Hydrate cart lines |
| `get_store_product(store_id, slug)` | PDP card |
| `search_marketplace_products(store_ids[], query, …)` | Cross-shop search |

Owner (authenticated, uses `auth_store_id()`):

| RPC | Use |
| --- | --- |
| `get_pos_home(limit)` | ~50 POS seed cards |
| `search_pos_catalog(query)` | POS search; empty query = home |
| `list_store_inventory(...)` | Paginated inventory with filters |
| `get_store_dashboard_counts()` | Today + lifetime KPIs (IST dates) |

Card shape is `ListingCard` in [`web-source/listing.ts`](./web-source/listing.ts). View: `v_listing_cards` (not granted to clients; RPCs wrap it).

## Web module layout (domain services)

Under `src/modules/`:

`admin`, `categories`, `customers`, `orders`, `payments`, `pos`, `products`, `purchases`, `returns`, `storefront`, `stores` (store + users), `suppliers`

Pattern: `types` → `schema` (zod) → `mapper` → `repository` → `service` → `actions` (Next server actions for writes).

## Web screens the app will eventually cover

### Customer

| Web route | Screen |
| --- | --- |
| `/` | Marketplace home |
| `/{slug}` | Shop home |
| `/{slug}/category/{slug}` | Category listing |
| `/{slug}/product/{slug}` | Product detail |
| `/{slug}/info` | Shop info |
| `/cart` `/checkout` | Cart + checkout (drawer on web) |
| `/orders` `/orders/{id}` | Orders |
| `/account` `/account/addresses` | Account |
| `/prescription` | WhatsApp Rx job (upload later) |
| `/auth/customer` | Phone OTP |

Bottom nav: Home · Search · Cart · Orders · Account.

### Staff

| Web route | Screen |
| --- | --- |
| `/auth/store/login` `/signup` | Email/password |
| `/onboarding` | Create shop |
| `/admin/pos` | POS |
| `/dashboard` | Today |
| `/admin/medicines` | Catalogue |
| `/admin/orders` | Online + POS orders |
| `/admin/products` (+ new/edit/batches) | Inventory |
| `/admin/categories` | Categories |
| `/admin/purchases` `/payments` `/customers` `/suppliers` `/returns` | Books |
| `/settings/store` `/edit` `/settings/profile` | My store |

Primary tabs: **POS · Today · Medicines · Orders** + **More**.

## What is not ready on the web (app should not invent it)

- Stock-reserve RPC for online checkout
- Full prescription file upload (WhatsApp path is the current job)
- Razorpay / gateway pay
- FCM push
- Barcode scan / Bluetooth printer (explicit native later)
- Staff roles beyond owner
- GSTR / H1 register / kiosk
- Hindi search transliteration
- Fake “deals” rails — research says kill them; use featured / buy-again / need rails

## Brand identity (do not hardcode)

From [`web-source/brand.ts`](./web-source/brand.ts):

- App name: **MediSync**
- Operator: **IM7 Digital** (https://im7.in)
- Site: https://med.im7.in
- Theme: `#0f766e` on `#f7faf9`
- Contact currently in brand.ts: the operator email/phone in that file

Chrome copy: [`web-source/locales/en.json`](./web-source/locales/en.json) and [`hi.json`](./web-source/locales/hi.json).
