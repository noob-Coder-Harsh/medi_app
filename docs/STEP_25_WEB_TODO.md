# Step 25 — Web todo (staff purchases APIs)

**Repo to change:** `D:\code_files\nextjs\medsahayta` (not this Flutter project)  
**Depends:** staff Bearer context from [STEP_21_WEB_TODO.md](./STEP_21_WEB_TODO.md)  
**Unblocks:** Flutter Step 25 (supplier invoice → stock in)  
**Source of truth:** [BUILD_PLAN.md](./BUILD_PLAN.md) Step 25, [DATA_PLANE.md](./DATA_PLANE.md), existing `purchase.actions` / `PurchaseService` / `createSupplierAction`

Do **not** implement these routes in `medi_app`. Do **not** add purchase list RPCs (owner SELECT is enough).

---

## Goal

JSON APIs under `/api/app/staff/…` that verify **Supabase access token**, resolve the owner store, then wrap:

- `createPurchaseAction` (prefer `status: "completed"` so stock applies immediately)
- `createSupplierAction` (minimal — purchases need a supplier when the list is empty; full suppliers CRUD is Step 26)

Flutter **reads** `purchase_orders` / `purchase_order_items` / `suppliers` with owner JWT. Product picker uses existing `search_pos_catalog`. Writes stay on Next.

---

## Auth

Same as Step 21: `Authorization: Bearer <Supabase access_token>` → user → `store_users` → `store_id`.

---

## Routes to add

| Method | Path | Body | Response | Wrap |
| --- | --- | --- | --- | --- |
| `POST` | `/api/app/staff/purchases` | `SavePurchaseInput` (below) | `PurchaseOrderDetail` | `createPurchaseAction` |
| `POST` | `/api/app/staff/suppliers` | `{ "name": "…" }` (+ optional phone/notes) | supplier `{ id, name, … }` | `createSupplierAction` |

Optional later:

| Method | Path | Notes |
| --- | --- | --- |
| `POST` | `/api/app/staff/purchases/:id/complete` | `completePurchaseAction` for drafts |
| `POST` | `/api/app/staff/purchases/:id/cancel` | `cancelPurchaseAction` |
| `PATCH` | `/api/app/staff/purchases/:id` | `updatePurchaseAction` (draft only) |

---

## Create purchase body

Match `savePurchaseSchema` / `sanitizeSavePurchasePayload`. Flutter sends:

```json
{
  "supplier_id": "uuid",
  "invoice_number": "INV-001",
  "invoice_date": "2026-11-05",
  "items": [
    {
      "store_product_id": "uuid",
      "batch_number": "B1",
      "quantity": 150,
      "purchase_price": 2.0,
      "mrp": 3.0,
      "selling_price": 2.8,
      "tax_percent": 0,
      "discount_percent": 0,
      "manufactured_at": null,
      "expires_at": "2027-06-30"
    }
  ],
  "subtotal": 300,
  "discount_amount": 0,
  "tax_amount": 0,
  "other_charges": 0,
  "round_off_amount": 0,
  "grand_total": 300,
  "payment_status": "paid",
  "payment_method": "cash",
  "paid_amount": 300,
  "due_amount": 0,
  "notes": null,
  "status": "completed"
}
```

| Field | Notes |
| --- | --- |
| `items[].quantity` | **Base units** (packs expanded on device) |
| `status` | `"completed"` applies inventory + supplier balance + payment ledger |
| `payment_status` | `pending` \| `partial` \| `paid` |
| Dates | `YYYY-MM-DD`; reject past `expires_at` (same as web) |

---

## Create supplier body (minimal)

```json
{ "name": "Local Wholesaler", "phone": null, "notes": null }
```

---

## Checklist (web)

- [ ] Reuse staff Bearer context helper from Step 21
- [ ] `POST …/purchases` → create (completed path must increase on-hand)
- [ ] `POST …/suppliers` → create
- [ ] JSON `{ error }` on failure; `401` / `403` / `400` as appropriate
- [ ] Duplicate invoice → clear error (same copy as web)
- [ ] Web admin purchases UI unchanged
- [ ] Smoke: create supplier, complete purchase with one line, confirm stock up on inventory / POS

---

## Do not

- Implement GSTR / GST reports
- Allow Flutter client `INSERT` into `purchase_orders` / batches as the product path
- Touch `medi_app` in the web session

---

## Flutter expectation

medi_app Step 25 lists purchases/suppliers via owner SELECT, picks products via `search_pos_catalog`, and POSTs create purchase/supplier. Until routes exist, create shows a clear API error; list/search still work with a Supabase session.
