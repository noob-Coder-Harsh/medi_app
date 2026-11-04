# Brand Configuration Rules & Guidelines

## Overview

All brand-related strings (app name, URLs, emails, messages) are centralized in **`src/lib/constants/brand.ts`**. This ensures consistency across the entire application.

---

## Core Rules for ALL Developers & AI Agents

### ❌ NEVER DO THIS:

```typescript
// BAD: Hardcoded strings
const appName = "MediSync";
const supportEmail = "support@medsahayta.com";
const welcomeMsg = "Welcome to MediSync - Pharmacy Ordering";
```

### ✅ ALWAYS DO THIS:

```typescript
// GOOD: Use brand config
import { BRAND, getPageTitle } from "@/lib/constants/brand";

const appName = BRAND.APP_NAME;
const supportEmail = BRAND.CONTACT.SUPPORT_EMAIL;
const welcomeMsg = BRAND.MESSAGES.LOGIN_WELCOME;
```

---

## Usage Guide

### 1. **Import the Brand Config**

```typescript
import { BRAND } from "@/lib/constants/brand";
```

### 2. **Access Brand Information**

**App Identity:**

```typescript
BRAND.APP_NAME; // "MediSync"
BRAND.TAGLINE; // "Enable local pharmacies to accept online orders in 1 hour"
BRAND.SHORT_DESCRIPTION; // Short brand description
BRAND.LONG_DESCRIPTION; // Full brand description
```

**Contact Information:**

```typescript
BRAND.CONTACT.EMAIL; // from brand.ts — never hardcode
BRAND.CONTACT.PHONE; // Phone number
BRAND.CONTACT.SUPPORT_EMAIL; // Support email
```

**URLs:**

```typescript
BRAND.URLs.WEBSITE;
BRAND.URLs.APP;
BRAND.URLs.DOCS;
BRAND.URLs.PRIVACY_POLICY; // Privacy policy link
BRAND.URLs.TERMS_OF_SERVICE; // Terms link
```

**Messages:**

```typescript
BRAND.MESSAGES.LOGIN_WELCOME;
BRAND.MESSAGES.CUSTOMER_WELCOME;
BRAND.MESSAGES.STORE_OWNER_WELCOME;
BRAND.MESSAGES.ERROR_GENERIC;
BRAND.MESSAGES.SUCCESS_ORDER;
// ...and many more
```

**Helper Functions:**

```typescript
import { getPageTitle, getWelcomeMessage, getMetaDescription } from "@/lib/constants/brand";

getPageTitle("Dashboard"); // "Dashboard | MediSync"
getWelcomeMessage("customer"); // Customer welcome message
getMetaDescription("Long description..."); // Truncated to 160 chars
```

---

## When to Add New Brand Strings

### Before Creating a New Page/Feature:

1. Identify all user-facing strings
2. Add them to `src/lib/constants/brand.ts` in the appropriate section
3. Import and use in your component

### Example Workflow:

```typescript
// ✅ Step 1: Add to brand.ts
export const BRAND = {
  FEATURES: {
    NEW_FEATURE: "New Feature Name",
  },
  MESSAGES: {
    NEW_FEATURE_WELCOME: "Welcome to New Feature",
  },
};

// ✅ Step 2: Use in your component
import { BRAND } from "@/lib/constants/brand";

export default function NewFeature() {
  return <h1>{BRAND.MESSAGES.NEW_FEATURE_WELCOME}</h1>;
}
```

---

## Current Brand Config Structure

| Section     | Purpose                | Example                        |
| ----------- | ---------------------- | ------------------------------ |
| `APP_NAME`  | Core brand identity    | "MediSync"                     |
| `CONTACT`   | Support & contact info | Emails, phone numbers          |
| `URLs`      | External links         | Website, docs, policies        |
| `SOCIAL`    | Social media links     | Twitter, LinkedIn, etc.        |
| `MESSAGES`  | User-facing UI text    | Welcomes, errors, success msgs |
| `FEATURES`  | Product features       | Feature names and descriptions |
| `ROLES`     | User role labels       | "Store Owner", "Customer"      |
| `PRICING`   | Pricing & payment info | Currency, commission rates     |
| `STORAGE`   | Infrastructure config  | Bucket names, file sizes       |
| `SEO`       | Search & social meta   | OG images, favicons            |
| `ANALYTICS` | Tracking IDs           | Analytics keys                 |

---

## Important Notes

### 1. **Environment Variables**

Some values (like analytics keys) may come from environment variables:

```typescript
ANALYTICS: {
  GOOGLE_ANALYTICS_ID: process.env.NEXT_PUBLIC_GOOGLE_ANALYTICS_ID || "",
}
```

### 2. **Making Changes**

To change any brand string:

1. Update ONLY in `src/lib/constants/brand.ts`
2. The change automatically reflects everywhere
3. No need to update multiple files

### 3. **TypeScript Support**

The file uses `as const` for full type safety:

```typescript
const role: (typeof BRAND.ROLES)[keyof typeof BRAND.ROLES] = BRAND.ROLES.STORE_OWNER;
```

### 4. **Adding New Sections**

For new sections, follow the pattern:

```typescript
SECTION_NAME: {
  KEY_NAME: "value",
  ANOTHER_KEY: "another value",
}
```

---

## Validation Checklist

**Before committing code with new UI strings:**

- [ ] All user-facing strings are in `brand.ts`
- [ ] No hardcoded app name, email, or URL
- [ ] Using imported `BRAND` constant
- [ ] Using helper functions where applicable
- [ ] TypeScript compilation passes without errors

---

## Troubleshooting

**Q: I see a hardcoded string in the codebase** A: Create an issue or add it to the appropriate section in `brand.ts` and update the component to use it.

**Q: I need to add a new message type** A: Add it to the `MESSAGES` section in `brand.ts` following the naming convention.

**Q: How do I use brand config in API routes?** A: Simply import and use the same way:

```typescript
import { BRAND } from "@/lib/constants/brand";

export async function POST() {
  const email = BRAND.CONTACT.SUPPORT_EMAIL;
  // ...
}
```

---

## File Location

📁 **Location:** `src/lib/constants/brand.ts`

---

_Last updated: 2026-10-28_
