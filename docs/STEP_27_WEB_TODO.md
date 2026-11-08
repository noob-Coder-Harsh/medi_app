# Step 27 — Web todo (staff orders status + returns APIs)

**Repo to change:** `D:\code_files\nextjs\medsahayta` (not this Flutter project)  
**Depends:** staff Bearer context from [STEP_21_WEB_TODO.md](./STEP_21_WEB_TODO.md)  
**Unblocks:** Flutter Step 27 (order board status changes; returns create/process)  
**Source of truth:** [BUILD_PLAN.md](./BUILD_PLAN.md) Step 27, [DATA_PLANE.md](./DATA_PLANE.md), `ChangeOrderStatusInput`, return actions/services

Do **not** implement these routes in `medi_app`. Lists are owner `SELECT` on `orders` / `returns` (no new list RPCs). Do **not** build kiosk.

---

## Goal

JSON APIs under `/api/app/staff/…` wrapping existing server actions/services:

- Order status: `changeOrderStatus` / equivalent (`ChangeOrderStatusInput`)
- Returns: create + approve + reject (restock / refund side-effects stay server-side)

Flutter **reads** `orders`, `order_items`, `order_status_history`, `returns`, `return_items` with owner JWT. Writes stay on Next.

---

## Auth

Same as Step 21: `Authorization: Bearer <Supabase access_token>` → user → `store_users` → `store_id`.

---

## Routes to add

| Method | Path | Body | Wrap |
| --- | --- | --- | --- |
| `POST` | `/api/app/staff/orders/:orderId/status` | `{ "to_status", "notes"? }` | change order status |
| `POST` | `/api/app/staff/returns` | create return (below) | create return action |
| `POST` | `/api/app/staff/returns/:returnId/approve` | `{}` or `{ "notes"? }` | approve / process + restock |
| `POST` | `/api/app/staff/returns/:returnId/reject` | `{ "notes"? }` | reject pending return |

Optional:

| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/api/app/staff/orders/:orderId` | Full `OrderDetail` if SELECT joins are awkward |

---

## Change status body

```json
{
  "to_status": "ready",
  "notes": null
}
```

`to_status` must obey `ORDER_STATUS_TRANSITIONS` (server enforces). Flutter Done path needs at least `ready` and `delivered` from online/POS orders.

---

## Create return body

Only for **delivered** orders:

```json
{
  "order_id": "uuid",
  "reason": "Customer changed mind",
  "notes": null,
  "items": [
    {
      "order_item_id": "uuid",
      "quantity": 1,
      "condition": "sealed",
      "restock_action": "restock"
    }
  ]
}
```

- `condition`: `sealed` \| `opened` \| `damaged` \| `expired`
- `restock_action`: `restock` \| `dispose` \| `supplier_return`

Response: return detail `{ id, status, refund_amount, items, … }` (or `{ return: … }`).

---

## Checklist (web)

- [ ] Reuse staff Bearer helper
- [ ] Status route verifies order belongs to caller store
- [ ] Enforce status transitions; reject illegal jumps with `{ error }`
- [ ] Create return validates delivered + returnable qty
- [ ] Approve restocks / updates refund_status; reject only when `pending`
- [ ] Web admin UIs unchanged

---

## Flutter expects

| Call | Path |
| --- | --- |
| `StaffWriteApi.updateOrderStatus` | `POST …/orders/:id/status` |
| `StaffWriteApi.createReturn` | `POST …/returns` |
| `StaffWriteApi.approveReturn` | `POST …/returns/:id/approve` |
| `StaffWriteApi.rejectReturn` | `POST …/returns/:id/reject` |
