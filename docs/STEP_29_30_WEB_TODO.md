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

## Step 30 — staff catalog create (superseded for app)

**Status:** App create is unblocked by Postgres RPC `create_custom_product` (see [WRITE_RPCS.md](./WRITE_RPCS.md)), not by fixing Next `POST /api/app/staff/catalog/custom`.

**v1 product:** Catalog owns create/edit + manage-stock (`adjust_stock`). `stores.track_stock` gates POS oversell. No dedicated inventory page.

### Optional web parity (not an app blocker)

Web admin may keep using Next `createCustomProductAction`. When convenient, web can also call the same RPCs so browser and app share one write path. Fixing the mobile catalog/custom route for `opening_batch` is **optional** for Flutter.

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
- [ ] (Optional) Web admin reuses `create_custom_product` / `adjust_stock` RPCs
- [x] App create product via `create_custom_product` RPC (see WRITE_RPCS.md) — apply SQL on live DB
