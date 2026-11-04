# Step 14 — Web todo (customer write APIs)

**Repo to change:** `D:\code_files\nextjs\medsahayta` (not this Flutter project)  
**Depends:** medi_app Steps 01–13 done  
**Unblocks:** Flutter Steps 15–17 (OTP, checkout, my orders)  
**Source of truth:** [BUILD_PLAN.md](./BUILD_PLAN.md) Step 14, [DATA_PLANE.md](./DATA_PLANE.md), [ARCHITECTURE.md](./ARCHITECTURE.md)

This file is a handoff checklist for the Next.js agent. Do **not** implement these routes in `medi_app`.

---

## Goal

JSON APIs under `/api/app/…` that verify Firebase **idToken** (`Authorization: Bearer …`), then call existing `storefrontService` (and related services). No new mobile RPC schema. Web cookie session must keep working.

---

## Auth contract

| Item | Rule |
| --- | --- |
| Header | `Authorization: Bearer <Firebase idToken>` |
| Cookie | **Not required** for the app |
| Identity | Verify token → ensure/upsert `customers` by phone (`auth_user_id` = Firebase uid as text) |
| Web | Existing `POST /api/customer/session` + httpOnly cookie path stays |

Reuse the same Firebase Admin verify + “ensure customer” logic the web session route already uses. Prefer extracting a shared helper rather than duplicating.

---

## Routes to add

Base path: `/api/app` (prefer this over `/api/mobile`).

| Method | Path | Body / query | Response (JSON) | Notes |
| --- | --- | --- | --- | --- |
| `POST` | `/api/app/session` | `{ "idToken"?: string }` (token may also be only in Bearer) | `{ customerId, phone, name }` | Reuse ensure customer |
| `POST` | `/api/app/cart/revalidate` | cart shape `{ storeId, items: [{ storeProductId, quantity }] }` (+ fulfillment fields if web already needs them) | validated lines, prices, stock issues, totals | Authoritative; do not trust client money |
| `GET` | `/api/app/addresses` | — | address list for customer | |
| `POST` | `/api/app/addresses` | address fields matching web save | created/updated address | |
| `POST` | `/api/app/orders` | place-online-order payload (same domain as web checkout) | `{ orderId, … }` | `source=online`; call `storefrontService.placeOnlineOrder` (or equivalent) |
| `GET` | `/api/app/orders` | optional `?offset&limit` | order list for this customer | No anon RPC; backend only |
| `GET` | `/api/app/orders/:id` | — | order detail | 404 if not owned |
| `POST` | `/api/app/orders/:id/cancel` | optional reason | cancelled order / status | Only when `canCancel` / pending rules match web |

---

## Implementation checklist (web repo)

- [ ] Shared Firebase Bearer verifier (reject missing/invalid token with `401`)
- [ ] Shared “ensure customer from verified token” used by all routes
- [ ] `POST /api/app/session`
- [ ] `POST /api/app/cart/revalidate` → existing listing/revalidate path (`get_listing_cards` / current service)
- [ ] `GET` + `POST /api/app/addresses`
- [ ] `POST /api/app/orders` → existing place-online-order service
- [ ] `GET /api/app/orders` + `GET /api/app/orders/:id`
- [ ] `POST /api/app/orders/:id/cancel`
- [ ] Consistent JSON error shape (`{ error, code? }`) and HTTP status codes
- [ ] CORS only if the app needs it for non-native clients; Flutter mobile usually does not
- [ ] Confirm web cookie checkout still works unchanged
- [ ] Smoke with curl/Postman using a real Firebase test idToken

### Example smoke

```bash
# After obtaining a Firebase idToken for a test phone user:
curl -sS -X POST "$BASE/api/app/session" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'

curl -sS "$BASE/api/app/orders" \
  -H "Authorization: Bearer $ID_TOKEN"
```

---

## Do not

- Change listing RPCs or `schema.sql` for this step
- Add a Flutter-only / mobile-only SQL surface
- Write business tables from the Flutter client
- Implement staff `/api/app/staff/…` here (later steps; same Bearer pattern with Supabase access token)
- Touch the `medi_app` Flutter tree in the web session

---

## Out of scope here (later Flutter steps)

| Step | Needs from this API |
| --- | --- |
| 15 OTP sheet | `POST /session` |
| 16 Checkout | `POST /cart/revalidate`, `POST /orders`, addresses |
| 17 My orders | `GET /orders`, `GET /orders/:id`, `POST /orders/:id/cancel` |

---

## Done when

- curl/Postman with a test Firebase token returns JSON for session, revalidate, addresses, and orders
- Web’s existing cookie session path still works
- No listing RPC or Flutter changes required for this step
