# Step 28 — Web todo (staff store / profile / categories APIs)

**Repo to change:** `D:\code_files\nextjs\medsahayta` (not this Flutter project)  
**Depends:** staff Bearer context from [STEP_21_WEB_TODO.md](./STEP_21_WEB_TODO.md)  
**Unblocks:** Flutter Step 28 (My Store, profile, categories)  
**Source of truth:** [BUILD_PLAN.md](./BUILD_PLAN.md) Step 28, [DATA_PLANE.md](./DATA_PLANE.md), `UpdateStoreInput`, store/category actions

Do **not** implement these routes in `medi_app`. Store + categories **reads** are owner `SELECT` (no new list RPCs). Do **not** add Razorpay or FCM.

---

## Goal

JSON APIs under `/api/app/staff/…` wrapping existing web actions/services:

- Store update (hours, geo, WhatsApp, UPI, modules, COD, sale policy, branding URLs)
- Image upload to `med-images` (service_role only — clients cannot write the bucket)
- Profile update on `store_users`
- Categories: attach / detach / create custom / update custom

Flutter Done criterion: PATCH `module_delivery: true` (or pickup) → generated `accepts_online_orders` becomes true. Never accept a client write of `accepts_online_orders`.

---

## Auth

Same as Step 21: `Authorization: Bearer <Supabase access_token>` → user → `store_users` → `store_id`.

---

## Routes to add

| Method | Path | Body | Wrap |
| --- | --- | --- | --- |
| `PATCH` | `/api/app/staff/store` | `UpdateStoreInput` fields | update store action |
| `POST` | `/api/app/staff/store/images` | multipart `file` + `kind` (`logo` \| `banner` \| `upi_qr`) | service-role upload → `{ "url": "…" }` |
| `PATCH` | `/api/app/staff/profile` | `{ "full_name"?, "phone"? }` | update `store_users` |
| `POST` | `/api/app/staff/categories/attach` | `{ "category_ids": ["uuid", …] }` | upsert `store_categories` |
| `POST` | `/api/app/staff/categories/detach` | `{ "category_ids": ["uuid", …] }` | delete mappings |
| `POST` | `/api/app/staff/categories` | `{ "name": "…", "slug"? }` | create custom category + attach |
| `PATCH` | `/api/app/staff/categories/:categoryId` | `{ "name"?, "is_active"?, "sort_order"? }` | edit **custom** only |

Response for store PATCH: full store row (include `accepts_online_orders`).

---

## Store patch notes

Omit nulls Flutter did not edit. Important fields for Step 28:

```json
{
  "name": "…",
  "phone": "…",
  "whatsapp_number": "…",
  "opening_time": "09:00",
  "closing_time": "21:00",
  "latitude": 28.6,
  "longitude": 77.2,
  "module_pickup": true,
  "module_delivery": true,
  "allow_cod": true,
  "allow_manual_upi": true,
  "upi_id": "shop@upi",
  "logo_url": "https://…",
  "banner_url": "https://…",
  "sale_policy": "loose_allowed",
  "is_open": true,
  "is_active": true
}
```

`sale_policy`: `loose_allowed` \| `pack_only` \| `whole_only`

---

## Checklist (web)

- [ ] Reuse staff Bearer helper
- [ ] Store PATCH rejects writes to `accepts_online_orders` / `owner_id`
- [ ] Image upload uses service role + public URL
- [ ] Category create sets `is_system=false`
- [ ] Category PATCH/DELETE blocked for system categories
- [ ] Web admin UIs unchanged

---

## Flutter expects

| Call | Path |
| --- | --- |
| `StaffWriteApi.updateStore` | `PATCH …/store` |
| `StaffWriteApi.uploadStoreImage` | `POST …/store/images` |
| `StaffWriteApi.updateProfile` | `PATCH …/profile` |
| `StaffWriteApi.attachCategories` | `POST …/categories/attach` |
| `StaffWriteApi.detachCategories` | `POST …/categories/detach` |
| `StaffWriteApi.createCategory` | `POST …/categories` |
| `StaffWriteApi.updateCategory` | `PATCH …/categories/:id` |
