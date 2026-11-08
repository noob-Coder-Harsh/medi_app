# Step 23 — Web todo (staff medicines / catalogue APIs)

**Repo to change:** `D:\code_files\nextjs\medsahayta` (not this Flutter project)  
**Depends:** staff Bearer context from [STEP_21_WEB_TODO.md](./STEP_21_WEB_TODO.md)  
**Unblocks:** Flutter Step 23 (add master SKU / create custom medicine)  
**Source of truth:** [BUILD_PLAN.md](./BUILD_PLAN.md) Step 23, [DATA_PLANE.md](./DATA_PLANE.md), existing `product.actions` / `ProductService`

Do **not** implement these routes in `medi_app`. Do **not** change listing RPCs.

---

## Goal

JSON APIs under `/api/app/staff/…` that verify **Supabase access token**, resolve the owner store, then wrap:

- `addProductToStoreAction` / `addProductsToStoreAction`
- `createCustomProductAction` (**catalog-only** path — no opening stock; stock is Step 24/25)

Flutter may **read** `master_products` / `store_products` with the owner JWT (RLS). Writes stay on Next.

---

## Auth

Same as Step 21: `Authorization: Bearer <Supabase access_token>` → user → `store_users` → `store_id`.

---

## Routes to add

| Method | Path | Body | Response | Wrap |
| --- | --- | --- | --- | --- |
| `POST` | `/api/app/staff/catalog/products` | `{ "productId": "uuid" }` | store product summary (id, productId, name, …) | `addProductToStoreAction` |
| `POST` | `/api/app/staff/catalog/products/bulk` | `{ "productIds": ["uuid", …] }` | `{ added, skipped, products }` | `addProductsToStoreAction` |
| `POST` | `/api/app/staff/catalog/custom` | custom product fields (see below) | created store product + master | `createCustomProductAction` with **catalog-only** schema (no `opening_batch`) |

Optional (nice-to-have; Flutter can SELECT instead):

| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/api/app/staff/catalog/browse` | `getCatalogBrowseAction` |
| `GET` | `/api/app/staff/catalog/search?q=` | `searchCatalogAction` |

---

## Custom product body (catalog-only)

Match `createCustomProductCatalogOnlySchema`:

```json
{
  "category_id": "uuid",
  "name": "My Syrup",
  "generic_name": null,
  "manufacturer": null,
  "strength": "100ml",
  "dosage_form": "syrup",
  "base_unit": "ml",
  "primary_pack_type": "bottle",
  "primary_pack_quantity": 100,
  "requires_prescription": false,
  "description": null
}
```

Do **not** require `opening_batch` on this route (medicines ≠ inventory).

---

## Checklist (web)

- [ ] Reuse staff Bearer context helper from Step 21
- [ ] `POST …/catalog/products`
- [ ] `POST …/catalog/products/bulk` (optional but useful)
- [ ] `POST …/catalog/custom` → catalog-only create
- [ ] JSON `{ error }` on failure; `401` / `403` / `400` as appropriate
- [ ] Web admin medicines UI unchanged
- [ ] Smoke with owner access token: add one system SKU, create one custom, confirm both show in POS search

---

## Do not

- Move FEFO / batches into this step
- Allow Flutter client `INSERT` into `store_products` / `master_products` as the product path (use these APIs)
- Touch `medi_app` in the web session

---

## Flutter expectation

medi_app Step 23 browses via owner SELECT (or optional GET browse/search). Add / create call these POSTs. Until routes exist, add/create show a clear API error; browse/search still work when Supabase session is present.
