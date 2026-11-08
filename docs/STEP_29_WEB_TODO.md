# Step 29 — Web todo (deep-link hosting only)

**Repo:** Next.js / `med.im7.in` host (not `medi_app`)  
**Unblocks:** Flutter Step 29 App Links / Universal Links for `https://med.im7.in/{slug}`  
**Flutter must not wait on new business APIs.** Listing by slug already uses `get_store_home` / `get_store_shell`.

**Forward this file (or the fuller [STEP_29_30_WEB_TODO.md](./STEP_29_30_WEB_TODO.md)) to the web/ops owner. Do not implement in Flutter.**

## Needed on the web host (ops / Next.js public files)

1. **Android App Links** — serve `https://med.im7.in/.well-known/assetlinks.json`  
   - `package_name`: `com.im7digital.med.medi_app`  
   - `sha256_cert_fingerprints`: release signing cert(s)
2. **iOS Universal Links** — serve `https://med.im7.in/.well-known/apple-app-site-association` (no `.json` suffix)  
   - `appID`: `TEAMID.com.im7digital.med.mediApp`  
   - paths covering shop slugs (optionally exclude marketing/legal)
3. **Path contract** — web = `/{slug}`; Flutter = `/shop/{slug}`. Native mapper only — **do not change web routes**.
4. **Custom scheme** — Flutter uses `medisync://shop/{slug}` (app-only; no web file).
5. **QR / share** — keep `https://med.im7.in/{slug}`.

## Not needed

- New Supabase RPCs or REST routes for “open shop by slug”
- Server-side dual-auth coupling
- Catalog-cache APIs (Riverpod in-memory)
- Step 30 UX chrome (Flutter-only). Catalog create `opening_batch` API is listed under Step 30 in [STEP_29_30_WEB_TODO.md](./STEP_29_30_WEB_TODO.md)

## Done when

- `assetlinks.json` and `apple-app-site-association` validate for the release signing identity
- Opening `https://med.im7.in/{validSlug}` on a device with the app installed lands the Flutter guest shop home without GPS
