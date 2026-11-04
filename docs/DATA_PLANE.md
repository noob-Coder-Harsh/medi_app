# Data plane — same RPCs, no app fork

Checked against `schema.sql` and the web client on **31 October 2026**.

**The app uses the same Postgres RPCs the web uses.** Do not create a parallel “mobile RPC” set. Flutter calls `supabase.rpc('get_store_home', …)` with the same function names, args, and JSON card shape. Grants already allow it.

## Locked flow

```
READ  (catalog, search, nearby, PDP, cart hydrate, POS seed, inventory page, dashboard)
      Flutter  →  Supabase RPC  →  ListingCard JSON
      (anon key for customer listing; owner JWT for staff listing)

WRITE (orders, stock, purchases, customers, settings, addresses, …)
      Flutter  →  Next /api/app/*  →  existing services  →  Postgres
      Customer:  Authorization: Bearer <Firebase idToken>
      Staff:     Authorization: Bearer <Supabase access_token>

NEVER from the Flutter client: table INSERT / UPDATE / DELETE on business tables.
NEVER: service-role key in the app.
```

Customers have **Firebase**, not `auth.uid()`. Anon has **EXECUTE on listing RPCs only** and **zero table SELECT**. That is why guest browse can hit RPCs, and why “my orders” cannot.

## Same RPCs (reuse as-is)

### Customer / guest — `GRANT EXECUTE` to **anon + authenticated**

| RPC | What the app uses it for | Page / filter |
| --- | --- | --- |
| `list_nearby_stores(lat, lng, limit)` | Location → resolve nearest shop | limit capped **50**, no offset |
| `get_store_shell(slug \| id)` | Shop header + categories | one shot |
| `get_store_home(slug)` | Shop home rails | featured **12** + products **24** (not a pager) |
| `search_store_catalog(store_id, query, category_id, limit)` | Search + category listing | query **or** category required; limit **1–50**; **no offset** |
| `get_store_product(store_id, slug)` | PDP | one card |
| `get_listing_cards(store_id, ids[])` | Hydrate **local** cart lines | by id |
| `list_system_categories()` | Category names/icons | full seed (12) |
| `search_marketplace_products(store_ids[], query, category, limit)` | Optional shop-switcher search | limit 50, no offset |

Empty search with no category returns `[]` on purpose (does not dump the catalog). Schedule **X** is hidden on these public RPCs.

### Staff / owner — `GRANT EXECUTE` to **authenticated** only (`auth_store_id()`)

| RPC | What the app uses it for | Page / filter |
| --- | --- | --- |
| `get_pos_home(limit)` | POS seed ~50 | limit max **80**, no offset |
| `search_pos_catalog(query, limit)` | POS + purchase product typeahead | empty query = home; limit 50 |
| `list_store_inventory(query, category, status, rx, stock, sort, sort_dir, offset, limit)` | Inventory list | **This is the pagination template** |
| `get_store_dashboard_counts()` | Today tiles | one JSON object, IST dates |

`list_store_inventory` already does **search + sort + filter + offset/limit + total**:

- filters: `status` active/inactive, `rx` rx/otc, `stock` in/out/low
- sort: name / category / manufacturer / stock / updated
- `p_limit` max 50, `p_offset` for pages
- returns `{ items: ListingCard[], total }`

Card payload is the same `ListingCard` as the web (`docs/web-source/listing.ts`). Parse once in Dart; do not invent a second DTO.

## What is *not* an RPC today

These **reads** still go through Next table `SELECT` (staff, owner JWT) or the **admin client** (customer, Firebase):

| Screen | Web today | App should |
| --- | --- | --- |
| My orders / my addresses | Next + Firebase + service role | **Backend GET** (no Supabase JWT for the customer) |
| Staff orders, purchases, payments, customers, suppliers, returns | Owner `SELECT` under RLS | **Same:** owner JWT **read-only SELECT**, *or* add a **shared** list RPC in `schema.sql` when that screen needs search/sort/page |
| Medicines catalogue (master_products) | Owner `SELECT` | same |
| Store settings GET | Owner `SELECT` | same |
| Batches on one product | Owner `SELECT` | same |

Do **not** build “app-only” SQL. If a list needs pagination, add one function to `schema.sql` and point **web + app** at it (copy `list_store_inventory`).

## Pagination / search / sort — honest limits

| Job | RPC can page? | v1 app |
| --- | --- | --- |
| Shop home | No (fixed 12+24 window) | Call `get_store_home` only |
| Search / category | Limit 50, **no offset** | Same as web. If a shop outgrows 50, add shared `list_store_catalog(..., offset, limit)` returning `{items, total}` — not a mobile fork |
| Nearby shops | Limit 50 | Enough for radius |
| Cart hydrate | By ids | Local cart + `get_listing_cards` |
| Staff inventory | **Yes** | Use `list_store_inventory` |
| POS | Seed + search, no page | Same as web phone POS |
| My orders | No RPC | Backend, add `?offset&limit` on the API |
| Staff orders / purchases / … | No RPC yet | Owner SELECT or new shared RPC when we build that step |

## Writes (backend only)

Reuse existing Next **services** (`storefrontService.placeOnlineOrder`, `PosService.checkout`, product/purchase/…). Flutter never reimplements FEFO in the client.

Minimum `/api/app` surface (Bearer):

**Customer (Firebase idToken)**

- `POST /session`
- `POST /cart/revalidate` (read-validate prices/stock; still a backend call because it is checkout-adjacent)
- `GET|POST /addresses`
- `POST /orders` · `GET /orders` · `GET /orders/:id` · `POST /orders/:id/cancel`

**Staff (Supabase access_token)** — wrap the same server actions the web already has

- POS checkout, product create/update, purchase complete, payment, customer, supplier, return, store settings, onboarding

Cart **contents** stay on device until checkout. Revalidate + place order are writes/validate, not a dump of the catalog.

## Why the app does not need its own RPCs

1. Functions are `SECURITY DEFINER` with explicit `GRANT EXECUTE`. The caller is any client with the anon or user key — browser or Flutter is the same.
2. `v_listing_cards` is **revoked** from clients. Both web and app only see what RPCs return.
3. New pagination = **one more function in `schema.sql`**, granted the same way, used by both clients.

The only identity that **cannot** use these RPCs for “my” data is the **customer**, because `auth.uid()` is not Firebase. Those reads stay on the backend.
