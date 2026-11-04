# Rapid build plan — one step per agent session

This is the execution playbook. Product rules: [APP_SHAPE.md](./APP_SHAPE.md), [STOREFRONT_PLAN.md](./STOREFRONT_PLAN.md), [WEB_PROJECT.md](./WEB_PROJECT.md), [ARCHITECTURE.md](./ARCHITECTURE.md), [ui-ux-research.md](./ui-ux-research.md), [web-source/Ecommerce-knowledge.txt](./web-source/Ecommerce-knowledge.txt).

Web origin: `D:\code_files\nextjs\medsahayta`  
App repo: this Flutter project.

## How to run this

Each **Step N** is **one Cursor agent coding session**.

| Rule | Why |
| --- | --- |
| One step per session | Agents degrade past ~8–15 files / one vertical slice |
| App must **analyze clean** at the end of the step | Next session starts from a green tree |
| Do not start the next step in the same session | Scope creep is how this plan dies |
| Read the step’s **Do not** list | Stops POS appearing inside location, etc. |
| Paste the prompt at the bottom of the step | Same instruction every time |

**Prompt to paste**

```
Implement ONLY Step N from docs/BUILD_PLAN.md.
Read docs/APP_SHAPE.md and this step’s Goal / Files / Done / Do not.
Stop when Done is met. Do not start Step N+1. Leave the app compiling.
```

Replace `N`. If a step is `repo: medsahayta`, work in `D:\code_files\nextjs\medsahayta`, not here.

## Locked stack (do not renegotiate)

| Need | Package |
| --- | --- |
| State | `flutter_riverpod` |
| Routes | `go_router` |
| Listing RPCs | `supabase_flutter` (anon key; owner JWT only for staff **reads**) |
| Customer OTP | `firebase_core` + `firebase_auth` |
| Location | `geolocator` + `permission_handler` |
| Local cart + last shop + locale | `shared_preferences` (JSON). Not Hive, not SQLite for v1 |
| Staff/customer tokens | `flutter_secure_storage` |
| Images | `cached_network_image` |
| Dates / ₹ | `intl` (`en_IN` / `hi_IN`) |
| WhatsApp / tel / https | `url_launcher` |
| HTTP to Next write APIs | `dio` |
| Env | `--dart-define` or gitignored `.env` via `flutter_dotenv`. Never commit keys |
| Fonts | Inter + Noto Sans Devanagari (google_fonts or bundled) |

**Reads:** same web RPCs, device → Supabase. See [DATA_PLANE.md](./DATA_PLANE.md). Do not invent app RPCs.

**Writes:** Next `/api/app/*` only. Customer = Firebase bearer. Staff = Supabase bearer. Flutter never writes tables.

**Pagination:** use `list_store_inventory` for staff inventory. Customer search is the existing `search_store_catalog` (max 50, no offset — same as web). If a list needs page/sort later, add **one shared function to `schema.sql`**, not a Flutter-only query.

## Folder layout (create in Step 01, then fill)

```
lib/
  main.dart
  app.dart
  core/
    brand.dart
    theme.dart
    env.dart
    router.dart
    i18n.dart
    format.dart          # DD/MM/YYYY, ₹
  data/
    supabase_client.dart
    firebase_client.dart
    api_client.dart      # dio → Next write APIs
    rpc/
    models/              # ListingCard, PublicStore, … from web-source
    local/               # prefs: cart, last store, locale, location
  features/
    location/
    storefront/          # home, search, category, pdp, shop info
    cart/
    checkout/            # includes OTP sheet
    orders/
    account/
    staff/
      auth/
      shell/
      pos/
      today/
      medicines/
      inventory/
      purchases/
      payments/
      orders/
      customers/
      suppliers/
      returns/
      store_settings/
      onboarding/
assets/locales/en.json
assets/locales/hi.json
```

Delete the default counter demo in Step 01.

## Visual / copy rules every UI step follows

- Teal `#0f766e`, canvas `#f7faf9`, 12px radius, no drop shadow
- Body 16px, touch 48dp, Charge ≥ 56dp
- Stock shows `0`, never “Out of Stock”
- Dates `DD/MM/YYYY`
- Chrome from locale JSON, identity from `brand.dart`
- EN | हिं from the start (even if some strings still English)

---

# Phase A — Foundation

### Step 01 — Project skeleton

- **Repo:** medi_app
- **Depends:** none
- **Goal:** Runnable app with empty shell, deps, folders, gitignored env. No screens yet beyond a placeholder scaffold.
- **Create/change:** `pubspec.yaml` (packages above), `lib/` tree as empty barrels, `lib/core/env.dart`, `lib/main.dart` / `app.dart` (ProviderScope + MaterialApp.router stub), `analysis_options.yaml` if needed, Android/iOS location permission **strings** only, `assets/locales/` copies of `docs/web-source/locales/*.json`, `.gitignore` for `.env`
- **Done when:** `flutter analyze` is clean. App launches to a blank “MediSync” scaffold. Counter demo is gone.
- **Do not:** location logic, Supabase init with real calls, Firebase, any feature UI

### Step 02 — Brand, theme, i18n

- **Repo:** medi_app
- **Depends:** 01
- **Goal:** Tokens + `en`/`hi` loader + `brand.dart` from `docs/web-source/brand.ts` (name, teal, operator, URLs).
- **Create/change:** `core/brand.dart`, `core/theme.dart`, `core/i18n.dart`, `core/format.dart`, language switcher widget (unused is ok)
- **Done when:** Theme uses teal/canvas. `t('NAV.HOME')` works for en and hi. Dates/rupees format Indian.
- **Do not:** screens, networking

### Step 03 — Router shells

- **Repo:** medi_app
- **Depends:** 02
- **Goal:** `go_router` routes exist as placeholders. Customer shell has 5-tab bottom nav. Staff shell is a separate branch, not linked from a visible button.
- **Routes (placeholders):** `/location`, `/shop/:slug`, `/shop/:slug/category/:cat`, `/shop/:slug/product/:product`, `/cart`, `/checkout`, `/orders`, `/orders/:id`, `/account`, `/staff/login`, `/staff/onboarding`, `/staff/pos`, `/staff/today`, …
- **Done when:** Tabs switch between dummy pages. Deep path `/shop/foo` builds. Staff paths exist but are not in customer nav.
- **Do not:** implement those pages; do not add a visible Staff tab

---

# Phase B — Guest browse (no login)

### Step 04 — Location screen

- **Repo:** medi_app
- **Depends:** 03
- **Goal:** First route is `/location`. Ask permission. Show rationale. Deny → retry UI. **Long-press logo 600ms+** navigates to `/staff/login` (placeholder).
- **Done when:** Grant stores lat/lng in prefs. Deny does not crash. Long-press opens staff login placeholder. No login wall.
- **Do not:** call nearby RPC yet; do not auto-skip this screen; do not add pincode in this step

### Step 05 — Supabase + listing models + RPCs

- **Repo:** medi_app
- **Depends:** 04
- **Goal:** Typed Dart models matching `docs/web-source/listing.ts` + RPC wrappers: `list_nearby_stores`, `get_store_shell`, `get_store_home`, `search_store_catalog`, `get_store_product`, `get_listing_cards`, `list_system_categories`.
- **Done when:** A throwaway debug button or unit-less call can print nearby JSON against the real project (env required). Models parse `ListingCard`.
- **Do not:** UI beyond a temporary test; do not staff RPCs yet

### Step 06 — Resolve store

- **Repo:** medi_app
- **Depends:** 05
- **Goal:** After location grant, call `list_nearby_stores`. Open **nearest** accepting shop (`/shop/:slug`). 0 results → empty state on location screen. Persist `lastStoreId` + slug. Shop-switcher data (other nearby) stored for home.
- **Done when:** Real device/emulator with location lands on a shop route if one exists in radius. Cold start with saved location re-resolves.
- **Do not:** marketplace mall homepage; do not require login

### Step 07 — Shop home

- **Repo:** medi_app
- **Depends:** 06
- **Goal:** Home as **merchandising slices** per [STOREFRONT_PLAN.md](./STOREFRONT_PLAN.md): shell + jobs + category tiles + featured rail (omit if empty) + products window. Query key `['store', slug, 'home']`. Cards use the customer read model (no warehouse qty). Quiet shop-switcher if `nearby.length > 1`.
- **Done when:** Matches STOREFRONT_PLAN home order. Guest can use it. No full-catalog store.
- **Do not:** fake “Today’s deals”; dump `store_products`; nest batches; cart persistence yet

### Step 08 — Product card + category listing + PDP

- **Repo:** medi_app
- **Depends:** 07
- **Goal:** Reusable `ProductCard`. Category grid → `/shop/:slug/category/:cat` via `search_store_catalog`. PDP via `get_store_product`. Pack, salt, ₹, Rx words, Add placeholder.
- **Done when:** Browse category and open a medicine as guest.
- **Do not:** cart persistence; do not checkout

### Step 09 — Search

- **Repo:** medi_app
- **Depends:** 08
- **Goal:** Debounce 250ms, min 2 chars, **new RPC per query** (`search_store_catalog`). Key `['search', storeId, q, categoryId]`. 1-column cards. Empty q + no category → hint, not a dump.
- **Done when:** Typing finds medicines in the resolved shop without a local catalog array.
- **Do not:** client-side filter of home results; marketplace cross-shop search; prefetch “the rest of the aisle”

---

# Phase C — Local cart + guest chrome

### Step 10 — Local cart

- **Repo:** medi_app
- **Depends:** 09
- **Goal:** Prefs JSON cart `{storeId, items[]}`. `tryAdd` / replace-other-shop dialog. Qty stepper on card and PDP. Badge on Cart tab. Survives restart.
- **Done when:** Kill app, cart still there. Two shops cannot mix without confirm.
- **Do not:** login; do not write Supabase

### Step 11 — Cart screen

- **Repo:** medi_app
- **Depends:** 10
- **Goal:** Hydrate lines with `get_listing_cards`. Subtotal. Checkout button **enabled** but destination is Step 19 (for now push `/checkout` placeholder). Empty state.
- **Done when:** Guest sees names, qty, ₹ from local ids.
- **Do not:** place order

### Step 12 — Account + legal + shop info + Rx job (guest)

- **Repo:** medi_app
- **Depends:** 11
- **Goal:** Account guest copy + Sign in CTA (OTP not wired). Legal links. Shop info page. WhatsApp chemist job with real `wa.me`. EN|हिं control.
- **Done when:** Guest can message the chemist and open privacy/terms. No forced login.
- **Do not:** Firebase OTP yet

### Step 13 — Orders tab guest

- **Repo:** medi_app
- **Depends:** 12
- **Goal:** Guest orders = empty + “Sign in to see orders”. Do not open OTP until they tap (OTP still stub until 18).
- **Done when:** Tab does not crash and does not block the rest of the app.
- **Do not:** fetch orders

---

# Phase D — Write path (web API + checkout)

Customer writes cannot use Next server actions. Add JSON APIs that verify Firebase **idToken** (Bearer), then call existing `storefrontService`.

### Step 14 — Web: customer write APIs

- **Repo:** `D:\code_files\nextjs\medsahayta`
- **Depends:** 13 (app can wait; this unblocks 18–20)
- **Goal:** Routes under `/api/app/…` (or `/api/mobile/…`):
  - `POST /session` — body `{ idToken }` → `{ customerId, phone, name }` (reuse ensure customer)
  - `POST /cart/revalidate`
  - `GET /addresses` `POST /addresses`
  - `POST /orders` — place online order
  - `GET /orders` `GET /orders/:id` `POST /orders/:id/cancel`
- Auth: `Authorization: Bearer <Firebase idToken>`. No httpOnly cookie requirement for the app.
- **Done when:** curl/postman with a test token returns JSON. Web’s existing cookie session still works.
- **Do not:** change listing RPCs; do not Flutter in this step; do not add a second mobile RPC schema
- **Note:** Staff mutations get `/api/app/staff/…` routes in the same web repo when those steps run (POS charge, products, purchases). Same pattern: Bearer + existing service. Not client table writes.

### Step 15 — Firebase OTP sheet

- **Repo:** medi_app
- **Depends:** 14 (can code UI against mocks if API not merged; wire real in same step if API exists)
- **Goal:** Phone OTP (IN +91). On success, `idToken` in secure storage, `POST /session`, then `pop` with success so checkout can continue.
- **Done when:** Real OTP creates a `customers` row via the API. Guest browse still works signed-out.
- **Do not:** make OTP the launch screen; long-press on this logo also goes to staff login

### Step 16 — Checkout

- **Repo:** medi_app
- **Depends:** 15
- **Goal:** Pickup vs delivery (if modules on), address form, COD/UPI, revalidate, **if no session → OTP then resume**, `POST /orders`, success screen.
- **Done when:** Guest fills cart without login; tapping Place order authenticates if needed and creates an `orders` row (`source=online`).
- **Do not:** Razorpay; do not staff POS

### Step 17 — My orders

- **Repo:** medi_app
- **Depends:** 16
- **Goal:** List + detail. Guest tap Sign in → OTP → load. Cancel if `canCancel`.
- **Done when:** Placed order appears after login.
- **Do not:** staff order board

---

# Phase E — Staff world

### Step 18 — Staff login / signup (hidden)

- **Repo:** medi_app
- **Depends:** 03, 04 (can proceed in parallel with C/D after 04)
- **Goal:** `/staff/login` email/password via Supabase. Signup. Session persist. Failed login stays hidden (no marketing). After login, if no store → onboarding, else `/staff/pos`.
- **Done when:** Long-press on location logo reaches a working owner session.
- **Do not:** show Staff in customer nav

### Step 19 — Onboarding + staff shell

- **Repo:** medi_app
- **Depends:** 18
- **Goal:** Create store, copy system categories (same as web). Staff bottom nav: POS · Today · Medicines · Orders + More sheet (purchases, payments, inventory, customers, suppliers, returns, my store, profile). Logout clears staff cache and returns to **customer location/shop**, not a login wall.
- **Done when:** Owner can open empty staff tabs. Customer world untouched.
- **Do not:** implement tab bodies except stubs

### Step 20 — POS search + cart

- **Repo:** medi_app
- **Depends:** 19
- **Goal:** Phone POS: search / `get_pos_home` seed ~50, running cart sheet, pack math, stock `0`. Charge button always tappable (validation next step).
- **Done when:** Staff can build a cart from real inventory.
- **Do not:** persist the sale yet if that explodes scope — prefer completing Step 21 in the **next** session. If both fit cleanly, still split mentally: this step UI, next step write.

### Step 21 — POS charge

- **Repo:** medi_app
- **Depends:** 20
- **Goal:** Customer phone lookup / walk-in, cash/UPI/credit, inline red validation. **POST** backend POS checkout (FEFO stays on the server). Success + print/share stub.
- **Done when:** One item bills into DB via `/api/app`, stock moves, recent sales list updates.
- **Do not:** barcode, Bluetooth printer, FEFO or order insert from Flutter

### Step 22 — Today dashboard

- **Repo:** medi_app
- **Depends:** 19
- **Goal:** `get_store_dashboard_counts` tiles: today sales, cash, pending online, near expiry — each tile is a task link.
- **Done when:** Numbers match web dashboard for the same shop.
- **Do not:** extra charts

### Step 23 — Medicines (catalogue)

- **Repo:** medi_app
- **Depends:** 19
- **Goal:** Browse master catalogue, add to store, custom medicine create. Separate from inventory.
- **Done when:** New SKU appears in POS search.
- **Do not:** batch editor here

### Step 24 — Inventory + batches

- **Repo:** medi_app
- **Depends:** 23
- **Goal:** `list_store_inventory`, product view/edit, batches, opening stock with purchase price, pack math in fields.
- **Done when:** Qty/FEFO listing prices update on shop home.
- **Do not:** purchases invoices (next)

### Step 25 — Purchases

- **Repo:** medi_app
- **Depends:** 24
- **Goal:** Supplier invoice in, lines, batch, stock in. Searchable product picker.
- **Done when:** Completing a purchase increases on-hand.
- **Do not:** GSTR

### Step 26 — Payments, customers, suppliers

- **Repo:** medi_app
- **Depends:** 19
- **Goal:** Three CRUD/list screens matching web jobs (khata/udhaar on customers, supplier balances, payment ledger). Searchable dropdowns, empty Add actions.
- **Done when:** Each list loads (owner read / RPC). Create/update goes through `/api/app/staff`, not a table write from Flutter.
- **Do not:** merge into POS

### Step 27 — Staff orders + returns

- **Repo:** medi_app
- **Depends:** 21, 17
- **Goal:** Online + POS order board, status changes. Returns create/process.
- **Done when:** A customer online order can be marked ready/delivered from staff.
- **Do not:** kiosk

### Step 28 — My store + profile + categories

- **Repo:** medi_app
- **Depends:** 19
- **Goal:** Hours, geo, WhatsApp, UPI, modules pickup/delivery, COD, sale policy, logo/banner (`med-images`), profile. Categories add/edit.
- **Done when:** Turning on delivery makes the customer shop accept online orders (`accepts_online_orders`).
- **Do not:** Razorpay, FCM

---

# Phase F — Finish

### Step 29 — Restore, deep links, session hygiene

- **Repo:** medi_app
- **Depends:** customer + staff shells exist
- **Goal:** `https://med.im7.in/{slug}` and custom scheme open that shop as guest. Last shop restore. Staff logout clears catalog cache. Customer logout does not clear cart. App logout from staff does not sign out a customer Firebase session unless we explicitly decide to — **keep them independent**.
- **Done when:** QR-style slug works without location. Two auth slots can coexist.
- **Do not:** new features

### Step 30 — UX pass

- **Repo:** medi_app
- **Depends:** 29
- **Goal:** Hindi chrome gaps, 48dp targets, no shadows/gradients on product chrome, stock `0`, Charge 56dp, empty table min-heights, 13″ not required (phone is the product).
- **Done when:** Walkthrough of guest browse → cart → OTP → order, and long-press → POS sale, both match APP_SHAPE.
- **Do not:** new modules (scan, printer, FCM)

---

## Suggested session grouping

If you batch for a human, still one agent step at a time:

| Days | Steps | Ship |
| --- | --- | --- |
| 1 | 01–06 | Location → a real shop home |
| 2 | 07–13 | Guest browse + local cart |
| 3 | 14–17 | Checkout writes |
| 4 | 18–22 | Hidden staff + POS + Today |
| 5 | 23–28 | Shop books |
| 6 | 29–30 | Hardening |

Steps 14 (web APIs) and 18 (staff login) can run **in parallel** with Phase C.

## Out of scope until a later plan

Kiosk, H1 register, GSTR, staff RBAC, Razorpay, FCM, barcode, Bluetooth printer, Hindi transliteration search, pincode-without-GPS (add only if location-denied becomes a blocker).
