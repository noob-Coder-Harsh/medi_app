# Step 24 — Web todo (staff inventory / batch APIs)

**Repo to change:** `D:\code_files\nextjs\medsahayta` (not this Flutter project)  
**Depends:** staff Bearer context from [STEP_21_WEB_TODO.md](./STEP_21_WEB_TODO.md)  
**Unblocks:** Flutter Step 24 (inventory detail, opening stock, batch price edits)  
**Source of truth:** [BUILD_PLAN.md](./BUILD_PLAN.md) Step 24, [DATA_PLANE.md](./DATA_PLANE.md), existing `product.actions` / `ProductService`

Do **not** implement these routes in `medi_app`. Do **not** change listing RPCs (`list_store_inventory` already exists).

---

## Goal

JSON APIs under `/api/app/staff/…` that verify **Supabase access token**, resolve the owner store, then wrap:

- `updateStoreProductAction`
- `addProductBatchAction` (opening stock — only while `store.onboarding_completed !== true`)
- `updateProductBatchAction` (selling price / batch fields; FEFO listing projection stays on DB triggers)

Flutter **reads** inventory via `list_store_inventory` RPC and owner `SELECT` on `inventory_batches`. Writes stay on Next.

---

## Auth

Same as Step 21: `Authorization: Bearer <Supabase access_token>` → user → `store_users` → `store_id`.

---

## Routes to add

| Method | Path | Body | Response | Wrap |
| --- | --- | --- | --- | --- |
| `PATCH` | `/api/app/staff/inventory/products/:storeProductId` | update store product fields (below) | store product detail | `updateStoreProductAction` |
| `POST` | `/api/app/staff/inventory/products/:storeProductId/batches` | opening batch (below) | `InventoryBatch` | `addProductBatchAction` |
| `PATCH` | `/api/app/staff/inventory/products/:storeProductId/batches/:batchId` | update batch fields | `InventoryBatch` | `updateProductBatchAction` |

Optional (Flutter can SELECT instead):

| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/api/app/staff/inventory/products/:storeProductId` | `getStoreProductAction` |
| `GET` | `/api/app/staff/inventory/products/:storeProductId/batches` | `getProductBatchesAction` |

---

## Update store product body

Match `updateStoreProductSchema` (partial OK). Flutter v1 sends:

```json
{
  "is_active": true,
  "sale_policy": "loose_allowed",
  "rack_location": "A1",
  "reorder_level": 10
}
```

`sale_policy`: `inherit` | `loose_allowed` | `pack_only` | `whole_only`

---

## Add batch body (opening stock)

Match `createBatchSchema` / `openingBatchSchema`:

```json
{
  "batch_no": "OPEN-001",
  "mrp": 30,
  "selling_price": 28,
  "quantity": 150,
  "purchase_price": 20,
  "manufactured_at": null,
  "expires_at": "2027-01-31"
}
```

| Field | Notes |
| --- | --- |
| `quantity` | **Base units** (Flutter expands packs → units before POST) |
| `purchase_price` | Cost for that total quantity |
| Dates | `YYYY-MM-DD` or null / `""` |

Server must reject with a clear error when `onboarding_completed === true` (same as web: stock after setup goes through purchases).

---

## Update batch body

Match `updateBatchSchema`. Flutter v1 primarily patches selling price:

```json
{ "selling_price": 27.5 }
```

---

## Checklist (web)

- [ ] Reuse staff Bearer context helper from Step 21
- [ ] `PATCH …/inventory/products/:storeProductId`
- [ ] `POST …/batches` (opening stock gate)
- [ ] `PATCH …/batches/:batchId`
- [ ] JSON `{ error }` on failure; `401` / `403` / `400` as appropriate
- [ ] Confirm FEFO listing fields on `store_products` refresh after add/update (shop home / POS prices)
- [ ] Web admin inventory UI unchanged
- [ ] Smoke with owner token: add opening batch (pre-complete setup), edit selling price, confirm shop listing price

---

## Do not

- Implement purchase invoices here (Step 25)
- Allow Flutter client `INSERT`/`UPDATE` on `inventory_batches` / `store_products` as the product path
- Touch `medi_app` in the web session

---

## Flutter expectation

medi_app Step 24 lists via `list_store_inventory`, loads batches via owner SELECT, and calls these POSTs/PATCHes for writes. Until routes exist, writes show a clear API error; list + batch read still work with a Supabase session.
