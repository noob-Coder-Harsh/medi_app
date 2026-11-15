# Staff write RPCs (v1)

Shared Postgres write functions for catalog-owned stock and POS. Flutter (and later web) call `supabase.rpc` with the owner JWT.

**Product images:** uploaded by the app to `med-images/{store_id}/products/…` under staff JWT (storage RLS). Next `POST …/store/images` only allows `logo|banner|upi_qr` — sending `kind=product` returns **invalid asset type**. Store logo/banner/UPI QR can still use Next.

Source: [`web-source/schema.sql`](./web-source/schema.sql) (`WRITE RPCs` section).

## Apply to a live database

If `stores` already exists without the column:

```sql
alter table public.stores
  add column if not exists track_stock boolean not null default true;
```

Then paste/run the WRITE RPCs block + grants from `schema.sql` (`create or replace function` is idempotent).

Reload the API schema cache after creating functions:

```sql
notify pgrst, 'reload schema';
```

### App shows "Bad Request" on save

1. Confirm RPCs exist: `select proname from pg_proc where proname = 'create_custom_product';`
2. Confirm grant: authenticated must `EXECUTE` (see grants at end of `schema.sql`)
3. Confirm `track_stock` column exists (ALTER above)
4. Hot **restart** the Flutter app after pulling RPC client changes
5. Read the on-screen / log line after `StaffWriteRpc.create_custom_product failed:` — it now includes PostgREST `code`, `details`, and `hint` (not only "Bad Request")

## Conventions

- `security definer`, `set search_path = public[, extensions]`
- Gate: `auth_store_id()` → else `STORE_REQUIRED`
- `grant execute` → **`authenticated` only** (not anon)
- Error codes: `STORE_REQUIRED`, `VALIDATION_ERROR`, `INSUFFICIENT_STOCK`, `NOT_FOUND`, `SYSTEM_PRODUCT_READONLY`

## Store flag: `track_stock`

| Value | Create product | Manage stock | POS checkout |
| --- | --- | --- | --- |
| `true` (default) | `opening_batch` required when stocking | reduce blocked below 0 | Enforces qty; FEFO decrement |
| `false` | Prices may be set on `store_products` listing columns; batch optional | Adjustments still allowed | **No** stock check; skip batch allocation |

## Functions

| RPC | Args | Returns |
| --- | --- | --- |
| `create_custom_product` | `p jsonb` | `{ store_product_id, product_id, name }` |
| `add_system_product_to_store` | `p_product_id uuid` | `{ store_product_id, product_id, name }` |
| `update_store_listing` | `p_store_product_id uuid`, `p jsonb` | `{ store_product_id, product_id }` |
| `adjust_stock` | `p_store_product_id uuid`, `p jsonb` | `{ store_product_id, available_quantity, listing_mrp, listing_selling_price }` |
| `update_store` | `p jsonb` | full store row jsonb (includes `track_stock`) |
| `ensure_pos_customer` | `p_phone text` | `{ customer_id, phone, name, total_orders, loyalty_points }` |
| `pos_checkout` | `p jsonb` | `{ order_id, order_number, total_amount, payment_method, customer_phone, placed_at }` |

### `adjust_stock` payload

```json
{
  "direction": "add",
  "quantity": 10,
  "reason": "purchase",
  "batch_no": "B001",
  "mrp": 20,
  "selling_price": 18,
  "purchase_price": 12,
  "manufactured_at": null,
  "expires_at": null,
  "notes": null
}
```

| UI | direction | reason |
| --- | --- | --- |
| Add | `add` | `purchase`, `opening`, `return_in`, `adjustment` |
| Reduce | `reduce` | `damage`, `expiry`, `theft`, `adjustment` |

### `pos_checkout` payload

Same shape as app `PosCheckoutInput` / Step 21 (`customer_id`, `items[]`, `payment_method`, `paid_amount`, `discount_type`, `discount_value`, `tax_amount`, `notes`).

## v1 product rules

- **Catalog** owns create/edit, pricing, and manage-stock (no dedicated inventory / purchase-order UI).
- Purchases, returns, settlements remain on Next until a later wave.
- Next `POST …/catalog/custom` opening_batch fix is **not** required for the app — create uses `create_custom_product`.
