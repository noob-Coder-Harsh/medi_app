# Step 21 — Web todo (staff POS charge APIs)

**Repo to change:** `D:\code_files\nextjs\medsahayta` (not this Flutter project)  
**Depends:** medi_app Steps 18–20 (staff login + POS cart UI)  
**Unblocks:** Flutter Step 21 charge (and later staff writes)  
**Source of truth:** [BUILD_PLAN.md](./BUILD_PLAN.md) Step 21, [DATA_PLANE.md](./DATA_PLANE.md), existing `PosService` / `checkoutPosAction`

This file is a handoff checklist for the Next.js agent. Do **not** implement these routes in `medi_app`. Do **not** change listing RPCs.

---

## Goal

JSON APIs under `/api/app/staff/…` that verify a **Supabase access token** (`Authorization: Bearer …`), resolve the owner’s store via `store_users`, then call the **existing** POS / customer services the web dashboard already uses (`checkoutPosAction`, `getOrCreatePosCustomerAction`, `lookupPosCustomerAction`, `getRecentPosSalesAction`).

FEFO / stock movement stays on the server (`orderService.createOrder`). Flutter never inserts orders or batches.

---

## Auth contract

| Item | Rule |
| --- | --- |
| Header | `Authorization: Bearer <Supabase access_token>` |
| Cookie | **Not required** for the app |
| Identity | `supabase.auth.getUser(jwt)` → `store_users` by `auth_user_id` → `store_id` |
| Reject | Missing/invalid token → `401`; no `store_id` → `403` / `400` with clear JSON error |
| Web | Existing server actions + cookie session must keep working |

Prefer a shared “staff Bearer context” helper (user + storeUser + store) reused by all `/api/app/staff/*` routes.

---

## Routes to add

Base path: `/api/app/staff`.

| Method | Path | Body / query | Response (JSON) | Wrap |
| --- | --- | --- | --- | --- |
| `GET` | `/api/app/staff/pos/customers?phone=` | E.164 or 10-digit IN mobile | `PosCustomerCard \| null` | `lookupPosCustomerAction` |
| `POST` | `/api/app/staff/pos/customers` | `{ "phone": "+91…" }` | `PosCustomerCard` | `getOrCreatePosCustomerAction` |
| `POST` | `/api/app/staff/pos/checkout` | see payload below | `{ order: OrderDetail }` (or flatten `{ orderId, orderNumber, totalAmount, … }`) | `checkoutPosAction` / `PosService.checkout` |
| `GET` | `/api/app/staff/pos/recent` | — | `PosRecentSale[]` (same shape as web recent sales) | `getRecentPosSalesAction` |

Optional later (not required for Step 21 Done): allocation preview, get order by id (staff can reuse a generic staff order GET when Step 27 lands).

---

## Checkout request body

Match web `posCheckoutSchema` / `sanitizePosCheckoutPayload` (snake_case OK if you keep web parity; camelCase OK if you document it — **pick one and stick to it**). Flutter will send:

```json
{
  "customer_id": "uuid",
  "items": [
    {
      "store_product_id": "uuid",
      "quantity": 15,
      "unit_price": 2.0,
      "unit_mrp": 3.0
    }
  ],
  "payment_method": "cash",
  "paid_amount": 30.0,
  "discount_type": "none",
  "discount_value": 0,
  "tax_amount": 0,
  "notes": null
}
```

| Field | Notes |
| --- | --- |
| `customer_id` | From ensure/lookup; required UUID |
| `items[].quantity` | **Base units** (already pack-expanded on device) |
| `payment_method` | `cash` \| `upi` \| `card` \| `credit` \| `mixed` |
| `paid_amount` | Cash/UPI usually = bill; credit may be `0` |
| Prices | Server should re-validate stock/FEFO; do not trust client as sole authority if web already re-prices |

### Suggested response (minimum for app)

```json
{
  "orderId": "uuid",
  "orderNumber": 42,
  "totalAmount": 30,
  "paymentMethod": "cash",
  "customerPhone": "+9198…",
  "placedAt": "2026-…"
}
```

Full `OrderDetail` is fine too; Flutter will read the fields it needs.

### Customer card

```json
{
  "customerId": "uuid",
  "phone": "+91…",
  "name": "…",
  "totalOrders": 3,
  "loyaltyPoints": 0
}
```

(Accept snake_case equivalents if that matches existing mappers.)

### Recent sale row

Same as web `OrderListItem` / `PosRecentSale`: `id`, `order_number`, `customer_phone`, `customer_name`, `item_count`, `total_amount`, `placed_at`, `status`, `source`.

---

## Implementation checklist (web repo)

- [ ] Shared Supabase Bearer verifier for staff routes
- [ ] Shared resolve `{ user, storeUser, store }` (fail if no store)
- [ ] `GET /api/app/staff/pos/customers?phone=`
- [ ] `POST /api/app/staff/pos/customers`
- [ ] `POST /api/app/staff/pos/checkout` → existing `PosService.checkout` (FEFO unchanged)
- [ ] `GET /api/app/staff/pos/recent`
- [ ] JSON errors `{ "error": "…" }` with correct HTTP status
- [ ] Confirm web POS UI / server actions still work
- [ ] Smoke with curl using a real owner access token

### Example smoke

```bash
# After owner sign-in, copy access_token from Supabase session:
TOKEN="eyJ…"
BASE="https://your-host"

curl -sS "$BASE/api/app/staff/pos/customers?phone=9876543210" \
  -H "Authorization: Bearer $TOKEN"

curl -sS -X POST "$BASE/api/app/staff/pos/customers" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"phone":"+919876543210"}'

curl -sS -X POST "$BASE/api/app/staff/pos/checkout" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @pos-checkout.json

curl -sS "$BASE/api/app/staff/pos/recent" \
  -H "Authorization: Bearer $TOKEN"
```

---

## Do not

- Change `schema.sql` / listing RPCs for this step
- Move FEFO or order insert into Flutter
- Require cookies for the app
- Implement barcode / Bluetooth / print hardware APIs
- Touch the `medi_app` Flutter tree in the web session

---

## Flutter expectation (this repo)

medi_app Step 21 calls these routes with the staff Supabase access token. Until the web routes exist, charge fails with a clear “API not configured / failed” message; UI validation (phone, cart, stock) still works offline of the write.

---

## Done when

- curl/Postman with an owner Supabase token can lookup/ensure customer, checkout one line item, see stock move, and list the sale in `/pos/recent`
- Web POS charge path unchanged for browser users
