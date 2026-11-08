# Steps 29–30 — Web todo (hosting / ops only)

**Repo to change:** Next.js host for `med.im7.in` (not this Flutter project)  
**Unblocks:** Flutter Step 29 App Links / Universal Links  
**Do not:** change Flutter routes to match web; do not add business APIs for these steps.

Flutter already opens shops by slug via `get_store_home` / `get_store_shell`. Step 30 UX chrome is Flutter-only; one staff catalog API fix on web unblocks app create-product parity.

Also see the shorter [STEP_29_WEB_TODO.md](./STEP_29_WEB_TODO.md).

---

## Step 29 — deep-link hosting

### 1. Android App Links

Serve `https://med.im7.in/.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.im7digital.med.medi_app",
      "sha256_cert_fingerprints": ["REPLACE_WITH_RELEASE_SHA256"]
    }
  }
]
```

Use the **release** signing certificate fingerprint(s). Debug builds need the debug keystore fingerprint added during development.

### 2. iOS Universal Links

Serve `https://med.im7.in/.well-known/apple-app-site-association` (**no** `.json` suffix, `application/json`):

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.im7digital.med.mediApp",
        "paths": ["/*"]
      }
    ]
  }
}
```

Replace `TEAMID` with the Apple Developer Team ID. Optionally exclude marketing/legal paths (`/for-pharmacies`, `/privacy-policy`, `/terms-and-conditions`, `/contact`) if those should stay in Safari.

### 3. Path contract (do not change web URLs)

| Surface | Shop URL |
| --- | --- |
| Web | `https://med.im7.in/{slug}` |
| Flutter in-app | `/shop/{slug}` |

Native mapper: host path `/{slug}` → Flutter `/shop/{slug}` (and category/product/info the same way). **Keep web routes as-is.**

### 4. Custom scheme (app-only)

Flutter uses `medisync://shop/{slug}` (and nested paths). No web file required. Prefer HTTPS QR/share links; custom scheme is a fallback / internal open.

### 5. QR / share

Keep QR codes as `https://med.im7.in/{slug}`. Installed app opens via App/Universal Links; others stay on web.

---

## Step 30 — staff catalog create API (app blocker)

**Repo:** `medsahayta` (Next.js)  
**Unblocks:** Flutter Create product form (Product Information + Packaging + Pricing & Stock / opening batch)  
**Flutter already ships:** `CreateCustomProductInput` includes required `opening_batch`; UI matches web `ProductCreateForm`.

### 1. Accept `opening_batch` on the mobile create route

File: `src/app/api/app/staff/catalog/custom/route.ts`

Today the route parses `createCustomProductCatalogOnlySchema` and never passes `opening_batch`. Web UI create already uses `createCustomProductAction` + `createCustomProductSchema` (opening stock required). `ProductService.createCustomProduct` already creates the opening batch when `opening_batch` is present.

**Change:**

1. Parse body with `createCustomProductSchema` (not catalog-only).
2. Normalize empty `manufactured_at` / `expires_at` to `null` (same as `normalizeOpeningBatch` in `product.actions.ts`).
3. Pass `opening_batch` into `productService.createCustomProduct`.
4. Keep strength / dosage_form empty-string → `null` normalization.

Expected body shape (same as web form):

```json
{
  "category_id": "uuid",
  "name": "Paracetamol 500 mg",
  "generic_name": "Paracetamol",
  "manufacturer": "Cipla",
  "strength": "500 mg",
  "dosage_form": "tablet",
  "base_unit": "tablet",
  "primary_pack_type": "strip",
  "primary_pack_quantity": 10,
  "requires_prescription": false,
  "opening_batch": {
    "batch_no": "B001",
    "quantity": 1,
    "purchase_price": 0,
    "mrp": 0,
    "selling_price": 0,
    "manufactured_at": null,
    "expires_at": null
  }
}
```

### 2. Done when

- `POST /api/app/staff/catalog/custom` with a valid `opening_batch` creates master + store product **and** opening stock batch (and opening_stock inventory transaction).
- Invalid / missing `opening_batch` returns the same Zod validation errors as web create.
- Flutter Create product then stocks the shelf on first create (no silent catalog-only create).

### Flutter-only (not web)

Hindi staff chrome, 48dp targets, Charge 56dp, stock `0`, empty-list min-heights.

---

## Not needed on web

- New Supabase RPCs or `/api/app` routes for open-by-slug
- Server-side dual-auth session coupling
- Catalog-cache clear APIs (Riverpod in-memory)
- Razorpay / FCM / scan / printer
- New create-product fields beyond what web `ProductCreateForm` already posts

---

## Checklist (web / ops)

- [ ] Publish `assetlinks.json` with release SHA-256
- [ ] Publish `apple-app-site-association` with Team ID + bundle id
- [ ] Verify with Google / Apple link validators
- [ ] Confirm `https://med.im7.in/{validSlug}` opens the installed Flutter guest shop without GPS
- [ ] `POST /api/app/staff/catalog/custom` accepts `opening_batch` via `createCustomProductSchema`
- [ ] App create product with batch + prices creates stock (not catalog-only)
