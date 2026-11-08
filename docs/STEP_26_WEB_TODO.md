# Step 26 — Web todo (staff customers / suppliers / payments APIs)

**Repo to change:** `D:\code_files\nextjs\medsahayta` (not this Flutter project)  
**Depends:** staff Bearer context from [STEP_21_WEB_TODO.md](./STEP_21_WEB_TODO.md); suppliers create from [STEP_25_WEB_TODO.md](./STEP_25_WEB_TODO.md)  
**Unblocks:** Flutter Step 26 (khata customers, supplier balances, payment ledger)  
**Source of truth:** [BUILD_PLAN.md](./BUILD_PLAN.md) Step 26, [DATA_PLANE.md](./DATA_PLANE.md), existing customer / supplier / payment actions

Do **not** implement these routes in `medi_app`. Lists are owner `SELECT` (no new RPCs).

---

## Goal

JSON APIs under `/api/app/staff/…` wrapping:

- Customers: `getOrCreateStoreCustomerAction`, `updateStoreCustomerAction`
- Suppliers: `createSupplierAction` (Step 25), `updateSupplierAction`, `setSupplierActiveAction`
- Payments: `settleCustomerPaymentAction`, `settleSupplierPaymentAction`

Flutter reads `store_customers` / `suppliers` / `payments` with owner JWT. Writes stay on Next.

---

## Auth

Same as Step 21: `Authorization: Bearer <Supabase access_token>`.

---

## Routes to add

| Method | Path | Body | Wrap |
| --- | --- | --- | --- |
| `POST` | `/api/app/staff/customers` | `{ "phone": "+91…" }` | `getOrCreateStoreCustomerAction` |
| `PATCH` | `/api/app/staff/customers/:storeCustomerId` | `{ "notes"?, "loyalty_points"? }` | `updateStoreCustomerAction` |
| `POST` | `/api/app/staff/suppliers` | create supplier fields | `createSupplierAction` (may already exist from Step 25) |
| `PATCH` | `/api/app/staff/suppliers/:supplierId` | update supplier fields | `updateSupplierAction` |
| `POST` | `/api/app/staff/suppliers/:supplierId/active` | `{ "is_active": true\|false }` | `setSupplierActiveAction` |
| `POST` | `/api/app/staff/payments/customer-settlement` | customer settlement (below) | `settleCustomerPaymentAction` |
| `POST` | `/api/app/staff/payments/supplier-settlement` | supplier settlement (below) | `settleSupplierPaymentAction` |

---

## Customer settlement

`customer_id` = **global** `customers.id` (not `store_customers.id`):

```json
{
  "customer_id": "uuid",
  "amount": 100,
  "method": "cash",
  "notes": null
}
```

`method`: `cash` \| `upi` \| `card` \| `bank_transfer` \| `credit` \| `wallet`

## Supplier settlement

```json
{
  "supplier_id": "uuid",
  "amount": 500,
  "method": "upi",
  "notes": null,
  "reference_number": null
}
```

---

## Checklist (web)

- [ ] Reuse staff Bearer helper
- [ ] Customer create/update routes
- [ ] Supplier update + active (create if missing from Step 25)
- [ ] Customer + supplier settlement routes
- [ ] Reject settlement over balance with clear JSON `{ error }`
- [ ] Web admin UIs unchanged
- [ ] Smoke: add customer by phone, collect dues; create/edit supplier; settle supplier; payments list shows rows

---

## Do not

- Merge settlement into POS charge
- Allow Flutter table writes for these mutations
- Touch `medi_app` in the web session

---

## Flutter expectation

Lists load via owner SELECT. Add/update/settle call these APIs. Until routes exist, writes show a clear API error; reads still work with a Supabase session.
