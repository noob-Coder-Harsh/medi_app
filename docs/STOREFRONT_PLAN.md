# Customer storefront — design locked

Source of fetch rules: [`web-source/Ecommerce-knowledge.txt`](./web-source/Ecommerce-knowledge.txt).  
Source of screens / copy / visual: [`ui-ux-research.md`](./ui-ux-research.md).  
Entry / auth: [`APP_SHAPE.md`](./APP_SHAPE.md).  
RPCs: [`DATA_PLANE.md`](./DATA_PLANE.md).

This is the **customer plane only**. POS catalog replica is not this. Do not put the warehouse in memory so filters feel instant.

## Mental model

1. **Home = merchandising slices** (shell + a few rails of cards).
2. **Browse / search = a new index query**, one page, not “filter the array we already downloaded.”
3. **Cart / checkout = live reads for those SKU ids only**, then a backend write.
4. **The UI never owns the catalog.** It owns the **current intent**.

If the customer never searches, we never paid for the other 4,950 SKUs.

```
Location → nearest shop
    │
    ├─ Home     get_store_home / get_store_shell     ~20–80 cards
    ├─ Search   search_store_catalog(q)              10–20 hits, debounce
    ├─ Category search_store_catalog(category)       first page 20–40
    ├─ PDP      get_store_product + 8 related        1 + related
    ├─ Cart     local ids → get_listing_cards        cart size
    └─ Checkout backend revalidate + place order     those ids, NOW
```

Guest until a **write**. Local cart is `{ storeId, items: [{ storeProductId, quantity }] }` only — never a persisted product dump.

---

## Screens (customer IA)

Bottom nav: **Home · Search · Cart · Orders · Account**. One shop at a time after location resolve.

| # | Screen | Guest? | Fetch (intent) | Must not |
| --- | --- | --- | --- | --- |
| 0 | Location | yes | `list_nearby_stores` | dump catalog; login wall |
| 1 | Shop home | yes | `get_store_home` (shell + featured 12 + products 24 + categories) | fake “deals”; nested batches |
| 2 | Search | yes | debounce 250ms, min 2 chars → `search_store_catalog` | search a local catalog array |
| 3 | Category | yes | `search_store_catalog(store, '', categoryId, 24)` | load every SKU in the aisle |
| 4 | PDP | yes | `get_store_product`; related = same RPC category limit 8 | send warehouse batches |
| 5 | Cart | yes | ids from prefs → `get_listing_cards` when the screen opens | trust stale prices at pay |
| 6 | Checkout | OTP if needed | backend `POST /cart/revalidate` then `POST /orders` | client totals as truth |
| 7 | Orders | sign-in CTA | backend GET after OTP | anon RPC of “my” orders |
| 8 | Account / info / Rx | yes (writes need OTP) | shell already loaded; WhatsApp is a URL | |

Shop-switcher (if `nearby.length > 1`): changes `storeId` / slug, **clears or confirms cart**, then `get_store_home` again. Not a national mall.

---

## Home — composed slices, not a table

Order on screen ([ui-ux-research](./ui-ux-research.md)):

1. This shop: name, logo, **Open / Closed**, pickup vs delivery if those modules are on  
2. Sticky search (taps Search tab / focuses search)  
3. Jobs: **Order with prescription** · **WhatsApp chemist** · **Reorder** (Reorder: guest sees “Sign in” or hides until a past order exists)  
4. 8–12 **shop** category tiles (from shell, not a second catalog download)  
5. **Popular** = `featured` from `get_store_home` (omit rail if empty — do not invent deals)  
6. **Medicines** = `products` window (24). “See all” opens category-less browse via search with a category chip or the first category  
7. Quiet trust: hours, licensed, GST invoice  
8. Offers last — v1: **none**

**Query key:** `['store', slug, 'home']`  
**Fresh enough:** 15–60s. Refetch on app resume if older than 60s. Home may be slightly stale; that is correct.

**Paint:** shell first (name, hours, categories) if we already have last shop from prefs; then collections. Do not block the whole screen on 80 cards.

---

## Product card (customer read model)

The RPC returns a full `ListingCard`. **The tile must not display the warehouse.**

**Show**

- Pack photo (`thumb`), white canvas  
- Brand name + strength + form  
- Salt line (`generic_name`)  
- Pack copy (`pack_label`)  
- ₹ selling price; MRP strike if higher  
- Rx **in words** if `requires_prescription`  
- Stock: `0` when `!in_stock` or `available_quantity <= 0`. Never “Out of Stock”  
- **Add** → stepper. Disabled at 0  

**Do not show on the card:** exact `available_quantity` as “47 left”, `on_hand`, `reserved`, `purchase` cost, GST slab, HSN, rack, batches, `track_batch`.

Search = **1 column**. Category browse may be **2 columns**. Body 16px, 48dp Add.

---

## Search / sort / filter

Never: download catalog, then `.where((p) => p.name.contains(q))`.

| Rule | v1 |
| --- | --- |
| Debounce | 250ms, **min 2 characters** (or a selected category with empty q) |
| Empty query + no category | `[]` — RPC already does this. Show “Type to search this pharmacy” |
| Call | `search_store_catalog(store_id, q, category_id, limit=20)` |
| Query key | `['search', storeId, q, categoryId]` |
| Cache | skip or ≤10s. Changing q is a **new** query |
| Sort | relevance from RPC (`similarity` then in-stock). No client sort of a dump |
| Filter v1 | category chip only (server `p_category_id`). `in_stock` filter later as a **query param**, not a local filter |
| Facets | not in current RPC — do not fake counts from a local list |

**Gap vs knowledge:** no cursor, max 50 hits. v1 = one page of 20. If a shop outgrows that, add **shared** `list_store_catalog(..., offset, limit) → { items, total }` to `schema.sql` (web + app). Not an app-only RPC.

---

## Category listing

Intent: **first page of that aisle**, 20–40 cards.

- Route `/shop/:slug/category/:cat`  
- Key `['search', storeId, '', categoryId]`  
- Infinite scroll **only after** the catalog list RPC grows a cursor/offset. Until then, one page (same as web).  
- Empty: “No medicines in this category”

---

## PDP

- `get_store_product(store_id, slug)` — one card, including description / pack / sale_policy hints  
- Key `['product', storeId, slug]`  
- Freshness: refetch when the screen is opened (price/stock closer to now than home)  
- Related: `search_store_catalog` same `category_id`, limit 8, drop self  
- Add uses **sale_policy** (`loose_allowed` / `pack_only` / `whole_only`) — pack math in the stepper, same as web  
- Exact warehouse qty still not a customer headline; stepper caps by `available_quantity` without advertising the number

---

## Cart (device) vs checkout (live)

```
prefs: { storeId, items: [{ storeProductId, quantity }] }
         │
         ├─ open Cart tab → get_listing_cards(storeId, ids)   // display names/prices
         └─ Place order     → POST /cart/revalidate           // authoritative
                            → OTP if needed
                            → POST /orders
```

- Home **Add** only writes prefs. No RPC.  
- Opening Cart hydrates cards (stale 15s ok for display).  
- Checkout must **not** use home/search cache for money or stock. Revalidate those ids.  
- One shop per cart; other shop → replace dialog.  
- Knowledge: **check → reserve → pay → confirm**. Reserve lives on the backend (not in Flutter). Home 20s behind is fine; overselling at pay is not.

---

## Query keys (do not use `['catalog']`)

| Key | Invalidation |
| --- | --- |
| `['nearby', lat, lng]` | new location only |
| `['store', slug, 'home']` | resume >60s; after shop switch |
| `['search', storeId, q, categoryId]` | each new q |
| `['product', storeId, slug]` | on open / focus |
| `['cart-cards', storeId, sortedIds]` | on open cart |
| `['product', id]` after a staff edit | staff plane only; customer home waits for TTL |

When staff changes Paracetamol, do **not** wipe customer search cache globally. Next home TTL / next PDP open is enough.

---

## Freshness clocks (customer)

| Surface | Fresh enough |
| --- | --- |
| Home tiles | 15–60s |
| Category / search | 10–30s |
| PDP price | refetch on open |
| Add to cart (local) | no server |
| Cart display | refetch on open |
| Checkout | **now** (backend) |
| New order on staff | staff channel later; not a catalog stream |

No Supabase Realtime on the whole `store_products` table for the customer app.

---

## Numbers (10k SKU shop)

- Home JSON: tens of KB, not megabytes  
- Search: ~10–30 KB  
- Cart hydrate: N cards, N = lines  
- Never: 5–20 MB catalog in `shared_preferences`

POS may later keep a **this-store snapshot** for cashiers. That is **not** the customer home path.

---

## What would make this incomplete again

- A Zustand/Hive “all products” store filled at login or at shop open  
- Client-side search/sort/filter over that dump  
- Showing admin batch/cost fields on tiles  
- Fake merchandising rails (Trending / Today’s deals) from a random shuffle  
- Login before location / browse  
- Customer “my orders” via anon RPC  

Build steps 04–17 in [BUILD_PLAN.md](./BUILD_PLAN.md) implement this file, one screen-intent per session.
