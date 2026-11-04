# App shape (locked)

Decided **31 October 2026**. This is the native product, not a later option.

## One app, full web parity

The Flutter app ships **the same features, same screens, same jobs** as the web product:

- All customer storefront screens (shop home, search, category, PDP, cart, checkout, orders, account, addresses, Rx/WhatsApp job)
- All staff/owner screens (login, signup, onboarding, POS, Today, medicines, inventory, categories, purchases, payments, orders, customers, suppliers, returns, my store, profile)

Same backend, same RPCs, same domain rules. Auth stays split: **customers = Firebase phone OTP**, **staff = Supabase email/password**.

Marketing landing (`/for-pharmacies`) stays web. Legal pages (privacy, terms, contact) stay reachable from Account, as on web.

**App-only customer change (not on web):** do **not** start on login. Start on **location → resolve store**. Login only when the customer must **write** (checkout, save address, load/cancel orders). Cart is **local** until then.

## Customer-first shell

The store listing and every cold start look like a **customer pharmacy app**. Staff tools are not a second icon, not a tab, not a “I’m a chemist” button.

### Cold start (guest)

1. Location screen (logo + “allow location to find your chemist”). **Long-press the logo** here for staff.
2. On grant → `list_nearby_stores`.
3. **Resolve store**
   - **1+ nearby:** open the **nearest** shop that accepts online orders. If more than one, keep a quiet shop-switcher on home (not a mall homepage).
   - **0 nearby:** empty state + retry. Do not invent a national catalogue.
   - **Deep link / QR** `/{storeSlug}`: skip nearby and open that shop.
4. Persist last lat/lng, last `storeId`/`slug` locally. Next launch: if location still granted, re-resolve; if the last shop is still in range, keep it.
5. Browse shop home, search, category, PDP, add to cart — **no account**. Fetch is **intent-driven** ([STOREFRONT_PLAN.md](./STOREFRONT_PLAN.md)): home = slices, search = new query, cart = those SKU ids only. Never download the shop catalog into local storage.
6. Customer bottom nav: **Home · Search · Cart · Orders · Account**
   - Orders / Account while guest: content + **Sign in** CTA, not a blocking login wall on launch.

### When login is required

Firebase phone OTP only when the user is about to **write** or read **their** rows:

- Place order (checkout)
- Save an address
- Load / cancel **my** orders
- Update profile name

OTP sheet can open on top of checkout. After success, continue the same action. Do not dump them back to a login home.

### Cart (local)

- Stored on device (`shared_preferences` JSON is enough).
- Shape: `{ storeId, items: [{ storeProductId, quantity }] }` — same as web.
- One shop at a time. Adding from another shop asks to replace the cart.
- Survives process kill. Does **not** require login.
- At checkout, revalidate via API (`get_listing_cards` / revalidate) then write the order.

## Hidden staff entry

Staff world is a **hidden step**. Because customer login is no longer first:

- **Long-press the logo** on the **location** screen (primary)
- Same long-press on the **OTP sheet / customer login** if it is showing
- Reveals staff email/password, then the staff shell (POS first)
- No label, no settings switch, no visible “Admin”
- Staff logout returns to the customer world (location or last shop, not a login wall)

“Admin” = store owner / shop staff. Platform super-admin and extra RBAC stay out of scope.

## Why this shape

Play Store shows a pharmacy app for neighbourhood customers. Guests can browse and fill a cart. The chemist who already knows the product long-presses the logo on the first screen.
