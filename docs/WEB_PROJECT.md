# What MediSync is

**MediSync** is pharmacy POS, inventory, and an optional neighbourhood storefront for Indian SME chemists.

Folder on this machine: `D:\code_files\nextjs\medsahayta`  
Started **28 October 2026** against a new Supabase project.  
This Flutter project (`medi_app`, Android id `com.im7digital.med.medi_app`) is the **app version** of that web product: **same features, same screens**. Same backend, same IA, same tokens. Native extras later: camera scan and Bluetooth printer. The web already ships as a PWA.

Locked app shape: [APP_SHAPE.md](./APP_SHAPE.md) — one customer-first app; location then resolve store; login only at write; staff via long-press on the location-screen logo. Build order: [BUILD_PLAN.md](./BUILD_PLAN.md).

## Purpose

Give an independent Indian chemist software they can run without training:

- Bill a walk-in sale in under 30 seconds (POS is always on).
- Keep inventory in the smallest sellable unit, with batches and FEFO on the bill line.
- Optionally turn on pickup and/or delivery so neighbourhood customers can order from “their chemist”, not a mall.

Tagline (identity): *Enable local pharmacies to accept online orders in 1 hour.*

It is **not** a 1mg/PharmEasy clone. Marketplace home exists so a customer without a shop QR can find nearby chemists. A known shop should still feel like *my chemist*.

## Who it is for

| Role | Auth | Job |
| --- | --- | --- |
| Store owner / staff | Supabase email/password | POS, today, catalogue, inventory, purchases, payments, orders, customers, suppliers, returns, my store |
| Customer | Firebase phone OTP **only at write** (checkout / addresses / my orders) | Location → nearest shop, search, local cart, checkout, account, WhatsApp chemist, Rx photo via WhatsApp |
| Platform admin / extra staff RBAC | Named in types, not built | Out of scope unless asked |

KPI from research: anyone who uses WhatsApp should be able to run the shop.

## Ideal product (research target)

Two densities, **one brand**:

**Customer phone**

1. This shop (or this area) + open/closed + pickup vs delivery if those modules are on
2. Sticky search (brand, salt, symptom)
3. Jobs: Order with prescription · WhatsApp/call chemist · Reorder
4. 8–12 shop category tiles
5. Buy again / popular at **this** shop
6. Need rails (fever, diabetes, baby) — shop-authored, not ads
7. Quiet trust (hours, genuine, GST invoice)
8. Offers last, one strip

Bottom nav: **Home · Search · Cart · Orders · Account**

Product card: pack photo on white · brand + strength + form · salt · pack copy · ₹ · Rx **in words** · stock as `0` (never “Out of Stock”) · **Add** → stepper. Search = 1 column. Combine pack/strength as chips on one family.

**Staff phone**

POS first. Five-tab bar + More sheet. Laptop is a denser breakpoint of the same screens.

Staff jobs: POS → Today → Medicines (catalogue) → Orders, then More: Inventory, Purchases, Payments, Customers, Suppliers, Returns, My Store.

Phone POS: find → cart sheet → Charge. Charge always tappable; missing fields show inline red validation. Pack math in the field (`10 strips × 15 = 150`). Default Simple mode (bill, stock in, today). Advanced = GST, batches, suppliers.

**Language (locked)**

English and Hindi now. Other Indian languages next, then international. Chrome is translated. Medicine brand names stay as printed on the pack (Dolo, Crocin). Spoken shop Hindi, short English verbs.

**Visual tokens**

- Canvas near-white, ink near-black, one mid teal for Add/Charge/Order (`#0f766e`)
- Amber + “Rx”. Red + icon + words for errors/expiry only. Never colour-only safety.
- Inter + Noto Sans Devanagari. Body 16px. Dates **DD/MM/YYYY**. ₹ tabular figures.
- Touch 48×48dp. Charge ≥ 56dp. 12px radius, 1px hairline, no drop shadow.

## What the web already builds (feature map)

### Always on — staff / shop ops

- Owner signup/login, store onboarding (copies system categories into the shop)
- POS: search, ~50 seed medicines, cart, cash/UPI/card/credit/mixed, Complete Sale, recent sales, pack-aware qty, FEFO allocation preview
- Today dashboard (counts, inventory value, today sales/cash, pending online orders, low stock, near expiry)
- Medicines (master catalogue add-to-store) **separate from** Inventory (store products + batches)
- Categories, purchases, payments, customers, suppliers, returns
- My Store / profile / online-order modules (pickup, delivery, COD, UPI, WhatsApp, hours, geo, GST, drug licence)

### Optional modules — customer storefront

`accepts_online_orders` is generated: `module_pickup OR module_delivery`.

- Marketplace `/` — location, system categories, nearby pharmacies, cross-store search
- Shop `/{slug}` — banner, search, categories, featured/popular, jobs (Rx / WhatsApp / reorder)
- Category, product detail, cart (one shop at a time), checkout
- Orders list/detail, account, addresses
- Prescription: WhatsApp the chemist (Phase 6 upload is still a stub on web)

### Marketing / legal

`/for-pharmacies` stays a web landing page. `/contact`, `/privacy-policy`, `/terms-and-conditions` stay reachable from Account, as on web.

## Explicitly out of scope until asked

Kiosk app, H1 register UI, GSTR export, staff RBAC beyond owner, Razorpay, FCM, barcode hardware, Hindi transliteration search.

Native later (web research): camera scan and Bluetooth printer — **same IA and tokens**.

## Domain rules the app must keep

1. Inventory is the **smallest sellable unit** (a syrup is a bottle, not ml of liquid in stock). Packaging is metadata (`10 strips × 15 tablets = 150`).
2. Listing lives on `store_products`. Batches are warehouse. **FEFO** on the bill line.
3. `requires_prescription` is **derived** from `drug_schedule` (`h`, `h1`, `x`, `c`). Not a DB column.
4. Schedule **X** is excluded from public storefront listing RPCs.
5. Sale policy (`loose_allowed` / `pack_only` / `whole_only`) is how customers may buy. It does not change how stock is counted.
6. POS is always on. Pickup/delivery are store modules.
7. Logout clears local workspace data (catalog cache, tokens, preferences).
8. Zero stock shows `0`. After a successful write, patch the active query — do not dump the full catalog into local storage.
9. Identity strings in brand config. UI chrome in locale JSON (`en` / `hi`).
10. Anon cannot `SELECT` business tables. Public listing goes through intent RPCs.

## Dual product, one app, one database

The web is one Next.js app with two surfaces sharing one Supabase Postgres. The native app is the same: **one Flutter app**, two worlds, one database.

- **Customer world** is the default (storefront).
- **Staff world** is hidden: long-press the logo on the customer login screen, then Supabase email/password.

See [APP_SHAPE.md](./APP_SHAPE.md).

## Web todos (app blockers)

Step 30 catalog create API: see [STEP_29_30_WEB_TODO.md](./STEP_29_30_WEB_TODO.md) — `POST /api/app/staff/catalog/custom` must accept `opening_batch` (same as web `ProductCreateForm`).
