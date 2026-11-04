/**
 * ============================================================================
 * BRAND CONFIGURATION FILE
 * ============================================================================
 *
 * Identity (app name, URLs, operator) lives here.
 * UI chrome (buttons, nav, errors) lives in src/locales/en.json and hi.json.
 *
 * ============================================================================
 */

import enMessages from "@/locales/en.json";

export const BRAND = {
  APP_NAME: "MediSync",
  APP_NAME_FULL: "MediSync - Pharmacy Ordering SaaS",
  COMPANY_NAME: "MediSync",
  TAGLINE: "Enable local pharmacies to accept online orders in 1 hour",
  CUSTOMER_TAGLINE: "Your Health, Our Priority",
  THEME: {
    COLOR: "#0f766e",
    BACKGROUND: "#f7faf9",
  },
  SHORT_DESCRIPTION: "Online pharmacy ordering platform for local medical stores",
  LONG_DESCRIPTION:
    "MediSync empowers local pharmacies to start accepting online orders without requiring technical knowledge. Get a dedicated online storefront, QR code ordering, product catalog, and order dashboard.",

  CONTACT: {
    EMAIL: "harsh.kushwaha664@gmail.com",
    PHONE: "+91 9871538356",
    SUPPORT_EMAIL: "harsh.kushwaha664@gmail.com",
  },

  OPERATOR: {
    NAME: "IM7 Digital",
    TAGLINE: "Owned and managed by IM7 Digital",
    WEBSITE: "https://im7.in",
  },

  URLs: {
    WEBSITE: "https://med.im7.in",
    APP: "https://med.im7.in",
    DOCS: "https://med.im7.in",
    PRIVACY_POLICY: "https://med.im7.in/privacy-policy",
    TERMS_OF_SERVICE: "https://med.im7.in/terms-and-conditions",
    CONTACT: "https://med.im7.in/contact",
  },

  SOCIAL: {
    TWITTER: "https://twitter.com/medsync",
    LINKEDIN: "https://linkedin.com/company/medsync",
    INSTAGRAM: "https://instagram.com/medsync",
    FACEBOOK: "https://facebook.com/medsync",
    YOUTUBE: "https://youtube.com/@medsync",
  },

  /** English fallback. Prefer `useMessages()` in client UI so Hindi applies. */
  MESSAGES: enMessages,

  FEATURES: {
    ONLINE_STOREFRONT: "Online Pharmacy Storefront",
    DEDICATED_URL: "Dedicated Store URL",
    QR_CODE_ORDERING: "QR Code Ordering",
    PRODUCT_CATALOG: "Product Catalog Management",
    ORDER_DASHBOARD: "Order Management Dashboard",
    CUSTOMER_MANAGEMENT: "Customer Management",
    PRESCRIPTION_UPLOAD: "Prescription Upload Support",
    ANALYTICS: "Order Analytics & Reports",
  },

  ROLES: {
    ADMIN: "Platform Admin",
    STORE_OWNER: "Store Owner",
    CUSTOMER: "Customer",
    SUPER_ADMIN: "Super Administrator",
  },

  STORAGE: {
    BUCKET_NAME: "medsahayta",
    MAX_UPLOAD_SIZE_MB: 10,
  },

  SEO: {
    DEFAULT_TITLE: "Free Pharmacy Management Software",
    DEFAULT_DESCRIPTION:
      "MediSync is free pharmacy management software for inventory, billing, POS, prescriptions, and customer management. Run your medical store with modern pharmacy inventory management and pharmacy billing software.",
    KEYWORDS: [
      "free pharmacy management software",
      "pharmacy inventory management",
      "pharmacy billing software",
      "pharmacy POS software",
      "medical store software",
      "pharmacy management system",
      "MediSync",
    ],
    OG_IMAGE: "/images/pharmacy-hero.png",
    OG_IMAGE_ALT: "MediSync — Free pharmacy management software dashboard",
    LOGO: "/images/med-logo.png",
    FAVICON: "/favicon.ico",
  },

  ANALYTICS: {
    GOOGLE_ANALYTICS_ID: process.env.NEXT_PUBLIC_GOOGLE_ANALYTICS_ID || "",
    GOOGLE_SITE_VERIFICATION: process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION || "",
    MICROSOFT_CLARITY_ID: process.env.NEXT_PUBLIC_MICROSOFT_CLARITY_ID || "",
    SEGMENT_WRITE_KEY: process.env.NEXT_PUBLIC_SEGMENT_WRITE_KEY || "",
  },

  LEGAL: {
    PRIVACY_TITLE: "Privacy Policy",
    TERMS_TITLE: "Terms and Conditions",
    CONTACT_TITLE: "Contact Us",
    LAST_UPDATED: "June 20, 2026",
  },

  FAQ: [
    {
      question: "Is MediSync really free pharmacy management software?",
      answer:
        "Yes. MediSync offers core pharmacy management features — inventory, billing, POS, and customer records — at no cost so local pharmacies can digitize operations without upfront software fees.",
    },
    {
      question: "What pharmacy inventory management features are included?",
      answer:
        "Track stock levels, batches, expiry dates, and product availability. Manage catalog products, custom medicines, categories, and low-stock visibility from one dashboard.",
    },
    {
      question: "Does MediSync include pharmacy billing and POS software?",
      answer:
        "Yes. MediSync includes pharmacy POS software with fast checkout, invoice generation, payment tracking, batch allocation, and receipt printing for in-store sales.",
    },
    {
      question: "Who is MediSync built for?",
      answer:
        "MediSync is built for independent pharmacy owners and medical store operators in India who want free, easy-to-use software to manage daily operations and prepare for online ordering.",
    },
  ] as const,
} as const;

export function getWelcomeMessage(role: "customer" | "store" | "admin"): string {
  switch (role) {
    case "customer":
      return BRAND.MESSAGES.CUSTOMER_WELCOME;
    case "store":
      return BRAND.MESSAGES.STORE_OWNER_WELCOME;
    case "admin":
      return `Welcome to ${BRAND.APP_NAME} Admin`;
    default:
      return `Welcome to ${BRAND.APP_NAME}`;
  }
}

export function getPageTitle(pageTitle: string): string {
  return `${pageTitle} | ${BRAND.APP_NAME}`;
}

export function getMetaDescription(description: string): string {
  return description.length > 160 ? description.substring(0, 157) + "..." : description;
}
