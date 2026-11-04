# MediSync UI/UX research, language, and current-screen audit

Started 28 October 2026. Research first, then a gap check of what the app already renders. Existing screens were **not** redesigned in this pass.

**Product:** Indian SME chemist — walk-in POS always on; pickup/delivery optional; neighbourhood storefront. Phone first. Almost no tutorial.

**Languages (locked):** English and Hindi now. Other Indian languages next. International locales after that. Same screens, not a forked product.

---

## 1. What the research says

### Customer merchandising

| Source | Finding we treat as a rule |
| --- | --- |
| Baymard Product List UX 2025 | 78% of mobile lists are poor–mediocre. Combine variants into one card. Show price and pack size. Filters must allow multiple values. |
| NN/g homepages & listings | Homepage is a shop window: clutter looks cheap. Cards need name with distinguishing attributes, a photo that identifies the pack, and price. |
| NN/g m-commerce | A phone shows ~3 products above the fold vs ~6 on desktop. Prioritisation matters more on mobile. |
| Tata 1mg vs PharmEasy home audits | Search + one “Order with prescription” CTA first; offers lower. Banner/membership stacks feel like a sale and weaken health trust. |
| Tata 1mg teardown (NextLeap) | Journey: search/reorder → exact brand+strength → Rx if needed → pay → track. Gaps elsewhere: unclear substitutes, Rx re-upload, offer clutter. |
| productgrowth.in Rx UX (2025–26) | ~40% abandon prescription flows. Label Schedule H/H1 in words. Never auto-substitute generics. Show a real pickup/delivery time. |

**Customer home, in this order**

1. This shop (or this area) + open/closed + pickup vs delivery if those modules are on
2. Sticky search (brand, salt, symptom)
3. Primary jobs: Order with prescription · WhatsApp/call chemist · Reorder
4. 8–12 category tiles (shop’s own categories)
5. Buy again / popular at **this** shop
6. Need rails (fever, diabetes, baby) — shop-authored, not ads
7. Trust (hours, genuine, GST invoice)
8. Offers last, one quiet strip

**Customer product card**

Pack photo on white · brand + strength + form · salt line · pack copy · ₹ price · Rx pill **with words** · stock as `0` (never “Out of Stock”) · one verb **Add** that becomes − 1 +. Search = 1-column list. Browse may be 2 columns. Combine pack/strength variants as chips on one family, not six near-identical cards.

Baymard’s “3 thumbnails on the list” is for apparel. For medicines the pack face is the product.

### Staff POS and shop ops

| Source | Finding |
| --- | --- |
| Shopify POS UI (Oct 2024) | If staff cannot make sense of it, the POS failed. Less is more. Smart grid of frequent actions. Same UI on phone and tablet. High contrast. Phone POS only has the keys to complete a sale. |
| Square / Toast pattern | Item grid + running cart + Charge. On a phone that becomes find → cart sheet → Charge. |
| Medbucket chemist study | Legacy software needs training and one PC. KPI: bill one item under 30s; anyone who uses WhatsApp should run the shop. |
| Pharmacy POS critiques | Rainbow buttons, tiny type, 6+ taps to sell = patient-safety risk. |
| Indian kirana POS (AngadiOne, DukaanDaari, MunshiJi) | Phone is the shop computer. Hindi+English. WhatsApp bill. Udhaar. Simple vs Advanced. |

**Staff IA:** POS (home) → Today → Medicines (catalogue) → Inventory / Purchases / Returns → Payments / Customers / Suppliers → Online orders (if modules on) → My Store.

**No-tutorial patterns:** one primary button per screen; Charge always tappable with inline red fields; pack math in the field (`10 strips × 15 = 150`); scan shows identity before quantity; status as words, not colour-only; default Simple mode.

### Visual system

- **Colour:** near-white canvas, near-black ink, one mid teal for Add/Charge/Order. Amber + “Rx”. Red + icon + words for errors/expiry only. Do not encode safety in colour alone (WCAG; ~8% of men are red-green colourblind).
- **Type:** Inter (Latin) + Noto Sans Devanagari. Customer body 16px. Staff body 16px; 14px tables only on laptop. Tabular figures for ₹. Dates **DD/MM/YYYY**. No letter-spacing on Hindi (breaks the shirorekha). Devanagari line-height ~1.7–1.8.
- **Touch:** 48×48dp (Material) / 44pt (Apple HIG), 8dp gap. Charge at least 56dp.
- **Shape:** 12px radius, 1px hairline, no drop shadow. Motion 150–200ms on sheets only.

### Phone → later app

Ship an installable PWA. Prompt **after** a successful order, not on first visit (clinic PWA: install acceptance jumped when delayed). Android can prompt; iOS needs Add to Home Screen copy. Native later only for camera scan and Bluetooth printer — same IA and tokens.

---

## 2. Language plan (English + Hindi now)

The platform **must** run in English and Hindi from the UI redesign onward. Later: other Indian languages (Tamil, Telugu, Marathi, Bengali, Kannada, Malayalam, Gujarati, Punjabi, …) then international locales. Do not wait for a “translation project” after the new UI; wire locale in while screens are rebuilt.

### What 1mg / kirana apps actually do

- **Chrome** (buttons, empty states, errors, nav) is translated.
- **Medicine brand names** stay as the pack is printed — Dolo, Crocin, Glycomet. Those are proper nouns. Hindi UI + English pack names is normal and expected.
- **Salts** can show bilingual later (Paracetamol / पैरासिटामोल) but v1 Hindi chrome is enough.
- Staff who think in Hinglish need Hindi labels on POS more than customers do.

### Split of strings

| Layer | Lives where | Localised? |
| --- | --- | --- |
| App name, URLs, legal operator, emails | `src/lib/constants/brand.ts` | No (identity) |
| All UI chrome (nav, CTAs, errors, empty states, POS, storefront) | `src/locales/en.json` + `src/locales/hi.json` | Yes |
| System category labels (12 seeds) | Locale map keyed by `slug` | Yes |
| Shop-authored category / product / customer names | Database as entered | Display as stored; optional `name_hi` later |
| Dates, ₹, phone | `en-IN` / `hi-IN` formatters | Always Indian grouping; locale only changes script of labels |

`brand.ts` stays the source for **identity**. It stops being the dump of every button label. Today almost all chrome is English-only inside `BRAND.MESSAGES`.

### Technical shape (when we implement)

1. Locale provider (`en` \| `hi`), cookie + `localStorage`, independent for customer vs owner session.
2. `<html lang="hi">` or `lang="en"` from the active locale.
3. Fonts: Inter + Noto Sans Devanagari with `unicode-range` so Latin users do not download the full Devanagari file.
4. Language control: **EN | हिं** in the customer header and in staff More/settings. One tap, no settings archaeology.
5. Message IDs, not concatenated English sentences (`orders.empty`, not `"You haven’t placed any orders yet"` in JSX).
6. No `uppercase tracking-widest` on translatable labels — Hindi cannot small-caps the way English can.
7. Search v1: query as typed against English catalog (`ilike` / `pg_trgm` as now). Hindi→English transliteration is a later search feature, not a UI blocker.
8. Next languages = more JSON files + font coverage (Noto Sans Tamil, Telugu, …). RTL only if Urdu/Arabic is added. Do not hard-code `en`/`hi` into layout math.

### Copy tone

- Hindi: spoken shop Hindi, not bureaucratic (`बिल बनाएँ` not `विक्रय लेनदेन पूर्ण करें`).
- English: short verbs (Add, Charge, Orders), not SaaS (`Get started with your omnichannel journey`).
- Same meaning in both; do not ship a “lite” Hindi.

---

## 3. Design we are aiming at (after this audit)

Two densities, one brand:

- **Customer phone:** bottom nav Home · Search · Cart · Orders · Account. Shop-window home. Cards as above.
- **Staff phone:** POS first; five-tab bar + More sheet. Laptop is a denser breakpoint of the same screens, not a different product.

Explicitly not copying: dark carnival marketplaces, 50-colour DOS billing, desktop-only Marg clones, hamburger-as-home on a phone.

---

## 4. Current screens (inventory)

Routes as of 28 October 2026.

### Customer / storefront

| Route | What it is |
| --- | --- |
| `/` | Marketplace home: hero, location-gated search, system category grid, nearby pharmacies, dark trust band |
| `/{storeSlug}` | Shop home: banner, search, category grid, **random** shelves labelled Trending / Today’s deals / Top in your area / Best sellers, then random category shelves |
| `/{storeSlug}/category/{slug}` | Category listing |
| `/{storeSlug}/product/{slug}` | Product detail |
| `/{storeSlug}/info` | Shop info |
| `/cart` `/checkout` | Cart and checkout (drawer also overlays storefront) |
| `/orders` `/orders/{id}` | Order list and detail |
| `/account` `/account/addresses` | Account |
| `/prescription` | Placeholder: “Prescription upload arrives in Phase 6.” |
| `/auth/customer` | Customer phone OTP |

Chrome: sticky header (logo, icon search, icon orders, cart). Footer is “Powered by MediSync”, not a bottom nav.

### Staff / owner

| Route | What it is |
| --- | --- |
| `/auth/store/login` `/signup` | Email/password |
| `/onboarding` | Store setup (no sidebar) |
| `/admin/pos` | Full-viewport POS: search + results + recent sales \| customer + cart + tender. F2/F4/F8 shortcuts. Desktop two-column. |
| `/dashboard` | KPI cards (counts, inventory value) |
| `/admin/medicines` | Catalogue |
| `/admin/products` + new/edit/batches | Inventory / product records |
| `/admin/categories` | Categories |
| `/admin/purchases` `/payments` `/orders` `/customers` `/suppliers` `/returns` | Shop books |
| `/settings/store` `/edit` `/settings/profile` | My store and profile |

Chrome: teal desktop sidebar (w-56) with gradient active state. Phone: hamburger drawer + **horizontal strip of every nav item**. POS hides the sidebar.

### Marketing

| Route | What it is |
| --- | --- |
| `/for-pharmacies` | Long SaaS landing. **`HomeMobileWarning` blocks viewports under 760px** (“Best viewed on a larger screen”). |
| `/contact` `/privacy-policy` `/terms-and-conditions` | Legal / contact |

### Visual / copy stack today

- Font: **Geist** Latin only. `html lang="en"`. `body` falls back to Arial. SEO locale `en_IN`.
- Colour: teal-700 sidebar, emerald-teal gradients, slate storefront, dark emerald trust panel, drop shadows on cards.
- Copy: English `BRAND.MESSAGES` (~hundreds of keys). Hardcoded leftovers exist (`Exit` on POS, dashboard KPI labels, prescription placeholder, mobile warning).
- Seed categories: English form-based names (Tablets & Capsules, Syrups, …) not need-based aisles (Fever, Diabetes).
- Product card already shows name, generic, form · strength, pack, price, Rx chip, Add → stepper. It also paints **“Out of stock”** in red when `stock_count <= 0`.

---

## 5. Gap vs the research (keep / change)

### Keep (already close)

- Dual product is real: marketplace (`/`) **and** per-shop storefront. Neighbourhood chemist is the shop slug; `/` is how a customer without a QR arrives. Do not delete nearby-shop finding — **demote it** so a known shop still feels like “my chemist”, not a mall.
- Store header already shows **shop name + open/closed**.
- Product card anatomy is most of the way there (identity, salt, pack, price, Add stepper).
- POS already has search-first, cart, cash/UPI/credit, Complete Sale + inline validation, pack-aware quantity.
- Catalogue vs inventory are **separate routes** (medicines vs products) — keep that split; rename in the UI.
- Strings are at least centralised (even if English-only). That makes locale files a mechanical move, not a scavenger hunt — except hardcoded leftovers.

### Change — customer

| Current | Target |
| --- | --- |
| Marketplace hero (“Medicines from pharmacies near you”) as fold 1 | Search + shop context first; hero copy is secondary |
| Location gate before search | Search can start; location needed for nearby/delivery, not for typing a medicine name |
| Fake shelves: Trending / Today’s deals / Top in your area / Best sellers (random shuffle of the same catalog) | Buy again, featured flag from DB, need rails, or nothing. Do not invent “deals” |
| No Rx CTA on home; `/prescription` is a Phase 6 stub | One “Order with prescription” job on shop home when online orders are on |
| No bottom nav; icon-only orders | Five labelled tabs, thumb zone |
| “Out of stock” badge | Show `0`, disable Add |
| Card shadow + hover zoom + 9px type on chips | Flat card, 12px+ chips, 16px body |
| Dark gradient trust slab | Quiet trust line (hours, licensed, WhatsApp) |
| Footer “Powered by” instead of app nav | Bottom nav; legal in Account |
| Geist Latin, `lang="en"` | Inter + Noto Devanagari, `lang` from locale, EN \| हिं |

### Change — staff

| Current | Target |
| --- | --- |
| Desktop-first teal sidebar + gradient pills | Same five jobs as bottom nav on phone; sidebar only from `lg` |
| Phone: hamburger **and** a scrolling chip-bar of 11 destinations | Five tabs + More. No tutorial required |
| POS two-column + keyboard shortcuts as the main speed path | Phone: search/tiles → cart sheet → Charge. Shortcuts stay as **additive** for laptop |
| Hardcoded “Exit”, “Point of Sale”, uppercase “Main/More” | Locale keys; no uppercase-only English chrome |
| Dashboard = six lifetime counts | Today: sales, cash, pending orders, near expiry — each tile is a task |
| No Simple vs Advanced | Default Simple (bill, stock in, today). Advanced = GST, batches, suppliers |
| Active nav uses gradient + shadow | Flat teal fill, high contrast, no gradient |

### Change — language (nothing exists yet)

- No locale switcher, no `hi` messages, no Devanagari font, `lang` fixed to `en`.
- Sidebar `tracking-widest uppercase` will break Hindi.
- Dashboard KPIs and POS “Exit” bypass `brand.ts` entirely.
- Category seeds have no Hindi labels.
- Marketing mobile block is English-only and **anti phone-first**.

### Change — marketing vs product

`/for-pharmacies` is a desktop-only landing with a full-screen mobile blocker. That contradicts “smooth on phone, later an app”. Treat marketing as a **phone page too**, or send phones to store login. Do not teach owners that MediSync is a laptop product.

---

## 6. Suggested build order (UI only, after approval)

1. Locale plumbing (`en` / `hi`) + fonts + `html lang` + EN|हिं control. Move chrome out of `brand.ts` into locale JSON. Identity stays in `brand.ts`.
2. Tokens: colour, type scale, radius, 48dp targets. Kill gradients/shadows on product chrome.
3. Customer: bottom nav, card (stock `0`, type size), shop home merchandising (kill fake deals).
4. Customer: search list, PDP, cart, checkout copy. Rx upload when that phase is scheduled — still a labelled CTA on home.
5. Staff: phone POS density, then five-tab shop nav, then Today dashboard.
6. PWA install after first successful bill/order.
7. Next languages: add JSON + Noto family; no layout rewrite.

Out of scope until asked: kiosk, H1 register UI, GSTR, extra staff roles, Razorpay chrome, barcode hardware, FCM, Hindi transliteration search.

---

## 7. Sources

Baymard Institute, Product List UX 2025 · Nielsen Norman Group, ecommerce homepages/listings and m-commerce · Shopify POS UI, Oct 2024 · Medbucket pharmacy billing case study · MedPlus POS (Samu XD) · Tata 1mg vs PharmEasy home audits · NextLeap Tata 1mg teardown · productgrowth.in prescription UX · Apple HIG · Material 3 / Android 48dp · Healthcare colour (PaletteRx, ColorArchive, WCAG) · Indic type (Noto, Inter pairing, shirorekha rules) · AngadiOne, DukaanDaari, MunshiJi, KiranaMitra · MDN PWA installability · 1mg PWA case notes.
