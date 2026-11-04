# MediSync app — gathered source from the web project

This Flutter repo is the **native app** for the existing web product.

Web source (read-only origin): `D:\code_files\nextjs\medsahayta`  
Folder name is `medsahayta`. Product name is **MediSync**. Operator is **IM7 Digital**. Live site: https://med.im7.in

Copied **31 October 2026**. Product shape is locked. Execution playbook is locked.

## Read in this order

1. [APP_SHAPE.md](./APP_SHAPE.md) — one app, location-first guest, hidden staff, local cart
2. [STOREFRONT_PLAN.md](./STOREFRONT_PLAN.md) — customer screens, fetch intents, card, cart vs checkout
3. [BUILD_PLAN.md](./BUILD_PLAN.md) — **one step per agent session**, stack, folders, 30 steps
4. [DATA_PLANE.md](./DATA_PLANE.md) — same RPCs as web, reads vs writes, pagination
5. [WEB_PROJECT.md](./WEB_PROJECT.md) — what it is, who it is for, purpose, scope, ideal product
6. [ARCHITECTURE.md](./ARCHITECTURE.md) — stack, auth, data plane, schema map, RPCs, modules, screens
7. [ui-ux-research.md](./ui-ux-research.md) — phone-first IA, language, visual tokens, current web gaps
8. [BRAND_CONFIG_RULES.md](./BRAND_CONFIG_RULES.md) — identity lives in brand config, chrome in locale files
9. [web-source/Ecommerce-knowledge.txt](./web-source/Ecommerce-knowledge.txt) — intent-driven catalog (do not dump SKUs)

## Copied web contracts (`web-source/`)

| File | Why it matters for the app |
| --- | --- |
| `schema.sql` | Postgres source of truth. Tables, RLS, listing RPCs, seed categories, `med-images` bucket |
| `database.ts` | Typed table/RPC contract used by the web client |
| `listing.ts` | Listing card payload the RPCs return |
| `brand.ts` | App name, URLs, operator, theme teal `#0f766e` |
| `locales/en.json` + `hi.json` | All UI chrome (EN + Hindi) |
| `packaging.constants.ts` | Base units, pack types, sale policies |
| `pharmacy.kind.ts` | Product kinds, drug schedules, Rx derivation |
| `dosage-forms.ts` | Dosage form enum |
| `store.types.ts`, `product.types.ts`, `order.types.ts`, `pos.types.ts`, `storefront.types.ts` | Domain types |
| `env.example` | Required keys (empty). Same backends: Supabase + Firebase |
| `database-README.md` | One-paste bootstrap, no numbered migrations |

Do not copy secrets from the web README into this repo. Use `env.example` only.
