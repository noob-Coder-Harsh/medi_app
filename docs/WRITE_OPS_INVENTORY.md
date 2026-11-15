# Write operations inventory

Map of **every write the Flutter app performs today**: entity → user action → mechanism → tables → client steps → failure modes → robustness notes.

**Goal:** decide what must stay on the critical path, what can run in parallel / background, what to cut, and how failures should surface (network down, bad values, DB reject).

Related: [WRITE_RPCS.md](./WRITE_RPCS.md) (RPC contracts), [DATA_PLANE.md](./DATA_PLANE.md) (read vs write planes).

---

## How to read this doc

| Column | Meaning |
| --- | --- |
| **Must succeed?** | If this fails, show error and do not claim success |
| **Critical path** | User waits for this before UI advances |
| **Background OK?** | Safe to fire-and-forget after success is known |
| **Parallel OK?** | Safe to start alongside another step (no dependency) |
| **Cut / defer?** | Not needed for v1 critical flows, or duplicate path |

**Planes**

| Plane | Client | Auth | Notes |
| --- | --- | --- | --- |
| A. Supabase write RPC | `StaffWriteRpc` | Owner JWT | Atomic multi-table; prefer this |
| B. Supabase Storage | `uploadProductImage` | Owner JWT + storage RLS | **Not** in same DB transaction as RPC |
| C. Direct table (RLS) | `stores` / `store_users` / `store_categories` | Owner JWT | Onboarding + auth only |
| D. Next staff HTTP | `DioStaffWriteApi` | Bearer Supabase token | Books modules; needs `API_BASE_URL` |
| E. Next customer HTTP | `DioAppWriteApi` | Firebase idToken | Online checkout |
| F. Local device | SharedPreferences / SecureStorage | — | Cart, session cache |

**Offline today:** no write outbox. Failure → show error. Local cart still mutates on device.

---

## Legend — suggested disposition

| Tag | Meaning |
| --- | --- |
| `KEEP` | Required; harden errors |
| `ATOMIC` | Already one Postgres function — keep as single RPC |
| `PREFETCH` | Start earlier (e.g. on blur) so charge is faster |
| `BG` | After success, refresh lists / invalidate in background |
| `PARALLEL` | Can run with another independent step |
| `CUT` | Dead / unused / duplicate — remove or don’t wire |
| `DEFER` | Not needed for counter POS / catalog v1 |
| `LATER-OUTBOX` | Needs offline queue for true “works every case” |

---

## 1. Quick matrix (all entities)

| Entity | Operation | Mechanism | Tables / bucket | Must succeed? | Disposition |
| --- | --- | --- | --- | --- | --- |
| **POS** | Charge sale | RPC `ensure_pos_customer` → `pos_checkout` | customers, store_customers, orders, order_status_history, order_items, inventory_batches*, order_item_batches*, inventory_transactions*, payments*, store_customers | Yes | `KEEP` `ATOMIC` checkout; `PREFETCH` customer; `BG` catalog refresh |
| **Product** | Create custom + image | Storage upload → RPC `create_custom_product` | med-images; master_products, store_products, inventory_batches*, inventory_transactions* | Yes (RPC); image optional | `KEEP`; upload before RPC; orphan image if RPC fails |
| **Product** | Add system SKU | RPC `add_system_product_to_store` | store_products | Yes | `KEEP` `ATOMIC` |
| **Product** | Update listing / toggle active | Optional upload → RPC `update_store_listing` | master_products* (custom), store_products | Yes | `KEEP` |
| **Inventory** | Adjust / opening batch | RPC `adjust_stock` | inventory_batches, inventory_transactions | Yes | `KEEP` `ATOMIC` |
| **Store** | Save settings | RPC `update_store` | stores | Yes | `KEEP`; logo upload `CUT` unused HTTP |
| **Onboarding** | Create store | Direct insert/update/upsert | stores, store_users, store_categories | Yes | `KEEP`; consider one RPC later |
| **Auth** | Sign up / in / out / ensure user | Supabase Auth + `store_users` | auth + store_users | Yes | `KEEP` |
| **Orders (staff)** | Change status | HTTP `…/orders/{id}/status` | orders, order_status_history (server) | Yes | `KEEP` if online-orders; else `DEFER` |
| **Returns** | Create / approve / reject | HTTP `…/returns*` | returns (+ lines) server | Yes for books | `DEFER` for POS-first |
| **Purchases** | Complete purchase | HTTP `…/purchases` | purchase_* server → stock | Yes for books | Overlaps `adjust_stock`; clarify later |
| **Customers** | Ensure / notes / settle | HTTP customers + payments | customers, store_customers, payments | Partial | POS uses RPC; books HTTP |
| **Suppliers** | CRUD / settle | HTTP | suppliers, payments | Books only | `DEFER` for POS-first |
| **Categories** | Attach / custom | HTTP (onboarding: direct upsert) | store_categories, categories | Settings | OK; dual plane |
| **Profile** | Owner name/phone | HTTP `…/profile` | store_users | Nice | Low priority |
| **Customer online** | Place / cancel order | HTTP `/api/app/orders*` | orders… via Next | Yes for storefront | Separate from POS |
| **Local** | Cart / prefs | SharedPreferences | device | N/A | Always local |

\* when `stores.track_stock = true` (or opening qty > 0).

---

## 2. Entity detail

### 2.1 POS

#### Charge sale (critical)

| | |
| --- | --- |
| **UI** | `pos_checkout_page.dart` → `_charge` |
| **Client steps** | 1. Validate cart / stock on device if `trackStock` 2. `ensure_pos_customer(phone)` 3. `pos_checkout(input)` 4. Clear cart + prepend recent sale (local) 5. `unawaited` POS catalog refresh |
| **RPC** | `ensure_pos_customer` then `pos_checkout` |
| **Tables in `pos_checkout`** | `orders` (insert, source=`pos`, status=`completed`) → `order_status_history` → per line `order_items` → if tracking: FEFO update `inventory_batches`, insert `order_item_batches`, insert `inventory_transactions` (type `sale`) → optional `payments` → update `store_customers` (orders/spent/balance) |
| **Tables in `ensure_pos_customer`** | upsert `customers` by phone; upsert `store_customers` |

**Errors to surface**

| Condition | Code / behavior |
| --- | --- |
| No JWT / no store | `STORE_REQUIRED` |
| Bad phone / empty cart / bad line | `VALIDATION_ERROR` |
| Customer not linked | `NOT_FOUND` (after ensure, rare) |
| Qty > available (`track_stock`) | `INSUFFICIENT_STOCK` |
| Network / timeout | Client exception — **do not clear cart** |
| Partial unknown (timeout after write) | Risk of double-charge on retry — need idempotency key later |

**Robustness plan**

| Step | Now | Better |
| --- | --- | --- |
| Client stock check | Sync before RPC | Keep as UX guard only; **server is source of truth** |
| `ensure_pos_customer` | On Charge | `PREFETCH` when phone is valid (blur / debounce) |
| `pos_checkout` | Critical path | Keep `ATOMIC`; never split FEFO to client |
| Catalog refresh | Already background | Keep `BG` |
| Recent sales prepend | Local only | OK; reconcile on next GET |
| Offline sale | Not supported | `LATER-OUTBOX` + idempotent `client_sale_id` |
| Double tap Charge | Rely on `busy` flag | Keep disabled until settle; optional RPC idempotency |

**Must succeed for “sale done”:** only `pos_checkout`. Customer ensure is required before it, but can be prefetched.

---

### 2.2 Product / catalog

#### Create custom product

| | |
| --- | --- |
| **UI** | `medicines_create_page.dart`, `catalog_master_sheet.dart` |
| **Controller** | `MedicinesController.createCustom` |
| **Steps** | 1. Optional `uploadProductImage` → `med-images/{storeId}/products/…` 2. RPC `create_custom_product` with `image_url` + optional `opening_batch` |
| **Tables** | `master_products` → `store_products` → if qty>0: `inventory_batches` + `inventory_transactions` (`opening_stock`) |

**Errors:** `VALIDATION_ERROR` (name/category/batch when tracking), `STORE_REQUIRED`, `IMAGE_UPLOAD_FAILED`, network.

**Robustness**

| Issue | Disposition |
| --- | --- |
| Upload then RPC fails | Orphan file in storage — accept for v1 or delete on failure |
| Image required for create? | No — skip upload if no bytes |
| Opening batch when `track_stock` | Required by RPC — validate on client first |
| Invalidate inventory list | `BG` after success |

#### Add system product

| | |
| --- | --- |
| **RPC** | `add_system_product_to_store` |
| **Tables** | `store_products` upsert `(store_id, product_id)` → set active |
| **Disposition** | `KEEP` `ATOMIC` — fast, single round-trip |

#### Update listing / edit / toggle active

| | |
| --- | --- |
| **RPC** | `update_store_listing` |
| **Tables** | custom: update `master_products` + `store_products`; system: `store_products` only (name edits → `SYSTEM_PRODUCT_READONLY`) |
| **Image** | Edit sheet may upload first, then pass `image_url` |
| **Toggle active** | Same RPC with `{ is_active }` only (`medicines_page`) |

**Pricing when tracking stock:** listing MRP/sell on `store_products` ignored when `track_stock`; prices live on batches — use `adjust_stock` / manage stock UI.

---

### 2.3 Inventory / stock

#### Adjust stock (add / reduce) + opening batch

| | |
| --- | --- |
| **UI** | `manage_stock_page.dart`, `add_batch_sheet.dart` |
| **RPC** | `adjust_stock` |
| **Add** | Insert or bump `inventory_batches` + `inventory_transactions` (purchase / opening / return_in / adjustment) |
| **Reduce** | FEFO decrement batches + txs (damage / expiry / theft / adjustment); `INSUFFICIENT_STOCK` if short |

**Disposition:** `KEEP` `ATOMIC`. Do not replace with client multi-update. Purchases HTTP may also add stock later — don’t double-write the same receipt without a design.

---

### 2.4 Store settings

| Operation | Mechanism | Tables | Notes |
| --- | --- | --- | --- |
| Save store | RPC `update_store` | `stores` (incl. `track_stock`) | `KEEP` |
| Logo / banner / UPI image | HTTP `uploadStoreImage` exists | Next → storage | **No Flutter caller** — form uses URL text → `CUT` or wire later |
| Categories attach/detach/custom | HTTP staff categories | `store_categories`, `categories` | Settings; onboarding seeds via direct upsert |

**`track_stock` flip:** changes POS oversell rules and create-product batch rules — treat as high-impact setting; confirm in UI.

---

### 2.5 Onboarding / auth

| Operation | Mechanism | Tables |
| --- | --- | --- |
| Sign up / sign in / reset / out | Supabase Auth | auth users |
| Ensure `store_users` row | Direct insert/update | `store_users` |
| Create store | Direct: insert `stores` (slug retry) → update `store_users.store_id` → upsert `store_categories` | 3 steps, **not one transaction** |
| Profile name/phone | HTTP PATCH profile | `store_users` |

**Robustness:** store create is multi-step — if step 3 fails, store exists without categories. Later: one `create_store` RPC. Slug `23505` retry already handled.

---

### 2.6 Orders (staff online fulfillment)

| Operation | Mechanism | Likely tables |
| --- | --- | --- |
| Change status | HTTP `POST …/staff/orders/{id}/status` | `orders`, `order_status_history` |

POS completed sales **do not** use this path (they finish inside `pos_checkout`).

**Disposition:** `KEEP` only if delivery/pickup module is in scope; else `DEFER`.

---

### 2.7 Returns

| Operation | HTTP |
| --- | --- |
| Create | `POST …/staff/returns` |
| Approve | `POST …/returns/{id}/approve` |
| Reject | `POST …/returns/{id}/reject` |

Stock restore should be **server-side** on approve (not a second client `adjust_stock`). Verify on Next before relying on it.

**Disposition:** books module — `DEFER` for counter-first hardening.

---

### 2.8 Purchases / suppliers / payments / customers (books)

| Entity | Writes | Plane |
| --- | --- | --- |
| Purchases | `createPurchase` completed | HTTP D |
| Suppliers | create/update/active/settle | HTTP D |
| Payments | customer + supplier settlement | HTTP D |
| Customers | ensure / notes / settle | HTTP D (POS ensure = RPC A) |

**Overlap risk:** purchase complete vs `adjust_stock` both add inventory. Prefer **one** path per business event.

**Disposition:** not on POS critical path — harden after catalog+POS.

---

### 2.9 Customer storefront (online)

| Operation | Mechanism |
| --- | --- |
| Session | `POST /api/app/session` |
| Revalidate cart | `POST /api/app/cart/revalidate` |
| Place order | `POST /api/app/orders` |
| Cancel | `POST /api/app/orders/{id}/cancel` |
| Cart lines | **Local only** until checkout |

**Disposition:** separate reliability track from staff POS. Cart local + place order atomic on server is the right shape.

---

## 3. Storage vs DB (important)

```
[Image bytes] --upload--> med-images (Storage) --public URL-->
                                                          \
[Product fields] --------------------RPC-------------------> Postgres (atomic)
```

- Storage upload is **outside** the RPC transaction.
- Fail upload → stop; don’t call RPC (current create flow).
- Fail RPC after upload → orphan image (harmless but messy).
- Store logo/banner/UPI: Next image API allows `logo|banner|upi_qr` only — **not** `product`.

---

## 4. Error taxonomy (what UI should say)

| Class | Examples | User message pattern |
| --- | --- | --- |
| Auth / store | No session, `STORE_REQUIRED` | Sign in again / complete onboarding |
| Validation | Bad phone, missing name, sell > mrp, empty cart | Fix field X |
| Business | `INSUFFICIENT_STOCK`, `SYSTEM_PRODUCT_READONLY` | Specific: not enough stock / system product locked |
| Missing RPC / schema | `RPC_MISSING:*`, `DB_MISSING_COLUMN:track_stock` | Ops: apply `schema.sql` write block |
| Network | timeout, offline, DNS | “No internet — try again”; **keep local state** |
| Unknown after write | timeout with no response | “Check Recent sales before charging again” (POS) |

Do **not** clear POS cart or product form until confirmed success.

---

## 5. Speed / robustness backlog (priority)

### P0 — POS charge must be correct and clear

1. Keep `pos_checkout` as single RPC (`ATOMIC`).
2. Prefetch `ensure_pos_customer` on valid phone (`PREFETCH`).
3. Disable Charge while in flight; on network error keep cart.
4. Map RPC codes to Hindi/EN strings (already partially in `StaffWriteRpcException`).
5. On timeout: warn to check recent sales before retry (`LATER`: idempotency key).

### P1 — Catalog create/edit

1. Client-validate opening batch when `track_stock` before upload.
2. Optional image: skip upload when no bytes.
3. After success: invalidate inventory/medicines providers in `BG`.
4. Don’t block UI on list refresh.

### P2 — Cut dead paths

| Item | Action |
| --- | --- |
| `lib/data/staff_write_api.dart` | Unused duplicate — `CUT` |
| HTTP catalog/POS helpers in `staff_api_client` (`checkout`, `createCustomCatalogProduct`, …) | Unused vs RPC — `CUT` or leave unused until deleted |
| `uploadStoreImage` | Unused — wire or `CUT` |

### P3 — Books / returns / purchases

1. Confirm Next approve-return restocks once.
2. Don’t call `adjust_stock` from app for the same purchase/return event.
3. `API_BASE_URL` missing → clear “server not configured” (not silent fail).

### P4 — Offline / outbox (later)

Only if counter must sell without net:

- Queue signed sale payloads locally.
- Replay with `client_sale_id` unique constraint inside `pos_checkout`.
- Until then: honest “needs internet” on Charge.

---

## 6. Flow sketches (critical path only)

### POS sale

```
phone valid ──PREFETCH──► ensure_pos_customer ──┐
                                                ▼
Charge tap ──busy──► pos_checkout (ATOMIC) ──success──► clear cart
                         │ fail / offline              └─BG─► refresh catalog
                         └─► keep cart, show error
```

### Create product

```
[optional] upload image ──url──┐
                               ▼
validate form ──► create_custom_product (ATOMIC) ──► BG invalidate lists
         upload fail ──► stop, no RPC
         RPC fail after upload ──► show error (orphan image OK for v1)
```

### Adjust stock

```
validate qty/reason ──► adjust_stock (ATOMIC) ──► refresh detail
```

---

## 7. RPC ↔ tables cheat sheet

| RPC | Writes |
| --- | --- |
| `create_custom_product` | `master_products`, `store_products`, optional `inventory_batches`, `inventory_transactions` |
| `add_system_product_to_store` | `store_products` |
| `update_store_listing` | `master_products` (custom), `store_products` |
| `adjust_stock` | `inventory_batches`, `inventory_transactions` |
| `update_store` | `stores` |
| `ensure_pos_customer` | `customers`, `store_customers` |
| `pos_checkout` | `orders`, `order_status_history`, `order_items`, optional batches/txs/`order_item_batches`, optional `payments`, `store_customers` |

Source of truth: `docs/web-source/schema.sql` WRITE RPCs section.

---

## 8. What “robust / fast” means for v1

| Principle | Practice |
| --- | --- |
| One business event → one server transaction | Prefer write RPC over client multi-table |
| User waits only for commit | Prefetch + background refresh |
| Fail loud, don’t lie | Keep cart/form; map codes |
| Don’t do extra work | Cut dead HTTP; skip optional image |
| Stock truth on server | Client checks are UX only |
| Books not on POS path | Harden POS/catalog first |

When changing a write: update this inventory (entity row + disposition) in the same PR.
