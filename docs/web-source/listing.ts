import { isPrescriptionRequired } from "@/lib/pharmacy/kind";
import type { Category } from "@/modules/categories/category.types";
import type { PosProductResult } from "@/modules/pos/pos.types";
import type { MasterProduct, StoreProduct, StoreProductListItem } from "@/modules/products/product.types";
import type { PurchaseStoreProductOption } from "@/modules/purchases/purchase.types";
import type { NearbyStore, PublicStore, PublicStoreResolveResult } from "@/modules/storefront/storefront.types";

export type ListingCard = {
  id: string;
  store_id: string;
  product_id: string;
  slug: string;
  name: string;
  generic_name: string | null;
  manufacturer: string | null;
  composition: string | null;
  description: string | null;
  thumb: string | null;
  image_url: string | null;
  pack_label: string;
  base_unit: string | null;
  primary_pack_type: string | null;
  primary_pack_quantity: number | null;
  secondary_pack_type: string | null;
  secondary_pack_quantity: number | null;
  dosage_form: string | null;
  strength: string | null;
  mrp: number | null;
  selling_price: number | null;
  unit: string | null;
  in_stock: boolean;
  available_quantity: number;
  on_hand_quantity: number;
  reserved_quantity: number;
  reorder_level: number;
  rack_location: string | null;
  sale_policy: string;
  schedule: string;
  kind: string;
  category_id: string | null;
  category_name: string | null;
  category_slug: string | null;
  is_featured: boolean;
  is_active: boolean;
  requires_prescription: boolean;
  gst_rate: number | null;
  hsn_code: string | null;
  track_batch: boolean;
  storage: string;
  is_system?: boolean;
  created_at: string;
  updated_at: string;
  store_name?: string;
  store_slug?: string;
};

export type StoreShellPayload = {
  status: "ok" | "not_found" | "unavailable";
  store: PublicStore | null;
  categories: Category[];
};

export type StoreHomePayload = StoreShellPayload & {
  featured: ListingCard[];
  products: ListingCard[];
};

export type InventoryPagePayload = {
  items: ListingCard[];
  total: number;
};

export type DashboardCounts = {
  products: number;
  categories: number;
  customers: number;
  orders: number;
  inventory_units: number;
  inventory_value: number;
  low_stock: number;
  expiring_batches: number;
  today_sales: number;
  today_cash: number;
  today_order_count: number;
  pending_online_orders: number;
};

export const DATA_PLANE_QUERY_KEY = ["data-plane"] as const;

function asRecord(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  return value as Record<string, unknown>;
}

function asString(value: unknown, fallback = ""): string {
  return typeof value === "string" ? value : fallback;
}

function asNullableString(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}

function asNumber(value: unknown, fallback = 0): number {
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function asNullableNumber(value: unknown): number | null {
  if (value == null || value === "") return null;
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? n : null;
}

function asBoolean(value: unknown, fallback = false): boolean {
  return typeof value === "boolean" ? value : fallback;
}

export function parseListingCard(value: unknown): ListingCard | null {
  const row = asRecord(value);
  if (!row || typeof row.id !== "string") return null;

  const schedule = asString(row.schedule, "none");
  const available = asNumber(row.available_quantity);

  return {
    id: row.id,
    store_id: asString(row.store_id),
    product_id: asString(row.product_id),
    slug: asString(row.slug),
    name: asString(row.name),
    generic_name: asNullableString(row.generic_name),
    manufacturer: asNullableString(row.manufacturer),
    composition: asNullableString(row.composition),
    description: asNullableString(row.description),
    thumb: asNullableString(row.thumb) ?? asNullableString(row.image_url),
    image_url: asNullableString(row.image_url) ?? asNullableString(row.thumb),
    pack_label: asString(row.pack_label, "Unit"),
    base_unit: asNullableString(row.base_unit) ?? asNullableString(row.unit),
    primary_pack_type: asNullableString(row.primary_pack_type),
    primary_pack_quantity: asNullableNumber(row.primary_pack_quantity),
    secondary_pack_type: asNullableString(row.secondary_pack_type),
    secondary_pack_quantity: asNullableNumber(row.secondary_pack_quantity),
    dosage_form: asNullableString(row.dosage_form),
    strength: asNullableString(row.strength),
    mrp: asNullableNumber(row.mrp),
    selling_price: asNullableNumber(row.selling_price),
    unit: asNullableString(row.unit) ?? asNullableString(row.base_unit),
    in_stock: asBoolean(row.in_stock, available > 0),
    available_quantity: available,
    on_hand_quantity: asNumber(row.on_hand_quantity, available),
    reserved_quantity: asNumber(row.reserved_quantity),
    reorder_level: asNumber(row.reorder_level),
    rack_location: asNullableString(row.rack_location),
    sale_policy: asString(row.sale_policy, "inherit"),
    schedule,
    kind: asString(row.kind, "tablet_capsule"),
    category_id: asNullableString(row.category_id),
    category_name: asNullableString(row.category_name),
    category_slug: asNullableString(row.category_slug),
    is_featured: asBoolean(row.is_featured),
    is_active: asBoolean(row.is_active, true),
    requires_prescription: asBoolean(row.requires_prescription, isPrescriptionRequired(schedule)),
    gst_rate: asNullableNumber(row.gst_rate),
    hsn_code: asNullableString(row.hsn_code),
    track_batch: asBoolean(row.track_batch, true),
    storage: asString(row.storage, "ambient"),
    is_system: asBoolean(row.is_system, true),
    created_at: asString(row.created_at),
    updated_at: asString(row.updated_at),
    store_name: asNullableString(row.store_name) ?? undefined,
    store_slug: asNullableString(row.store_slug) ?? undefined,
  };
}

export function parseListingCards(value: unknown): ListingCard[] {
  if (!Array.isArray(value)) return [];
  return value.map(parseListingCard).filter((card): card is ListingCard => Boolean(card));
}

export function parseCategory(value: unknown): Category | null {
  const row = asRecord(value);
  if (!row || typeof row.id !== "string") return null;
  return {
    id: row.id,
    name: asString(row.name),
    slug: asString(row.slug),
    icon_url: asNullableString(row.icon_url),
    sort_order: asNumber(row.sort_order),
    is_system: asBoolean(row.is_system, true),
    is_active: asBoolean(row.is_active, true),
    created_at: asString(row.created_at),
  };
}

export function parseCategories(value: unknown): Category[] {
  if (!Array.isArray(value)) return [];
  return value.map(parseCategory).filter((item): item is Category => Boolean(item));
}

export function parsePublicStore(value: unknown): PublicStore | null {
  const row = asRecord(value);
  if (!row || typeof row.id !== "string") return null;
  return {
    id: row.id,
    name: asString(row.name),
    slug: asString(row.slug),
    phone: asNullableString(row.phone),
    description: asNullableString(row.description),
    address: asNullableString(row.address),
    city: asNullableString(row.city),
    state: asNullableString(row.state),
    pincode: asNullableString(row.pincode),
    latitude: asNullableNumber(row.latitude),
    longitude: asNullableNumber(row.longitude),
    logo_url: asNullableString(row.logo_url),
    banner_url: asNullableString(row.banner_url),
    whatsapp_number: asNullableString(row.whatsapp_number),
    opening_time: asNullableString(row.opening_time),
    closing_time: asNullableString(row.closing_time),
    service_radius_km: asNumber(row.service_radius_km, 5),
    minimum_order_amount: asNumber(row.minimum_order_amount),
    delivery_charge: asNumber(row.delivery_charge),
    free_delivery_above: asNullableNumber(row.free_delivery_above),
    allow_cod: asBoolean(row.allow_cod, true),
    allow_manual_upi: asBoolean(row.allow_manual_upi, true),
    allow_prescription_upload: asBoolean(row.allow_prescription_upload, true),
    module_pickup: asBoolean(row.module_pickup),
    module_delivery: asBoolean(row.module_delivery),
    upi_id: asNullableString(row.upi_id),
    upi_qr_url: asNullableString(row.upi_qr_url),
    is_open: asBoolean(row.is_open, true),
    accepts_online_orders: asBoolean(row.accepts_online_orders),
    sale_policy: asString(row.sale_policy, "loose_allowed"),
  };
}

export function parseNearbyStores(value: unknown): NearbyStore[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((entry) => {
      const store = parsePublicStore(entry);
      const row = asRecord(entry);
      if (!store || !row) return null;
      return { ...store, distance_km: asNumber(row.distance_km) };
    })
    .filter((item): item is NearbyStore => Boolean(item));
}

export function parseStoreShell(value: unknown): StoreShellPayload {
  const row = asRecord(value);
  const status = asString(row?.status, "not_found");
  const parsedStatus =
    status === "ok" || status === "unavailable" || status === "not_found" ? status : "not_found";
  return {
    status: parsedStatus,
    store: parsePublicStore(row?.store),
    categories: parseCategories(row?.categories),
  };
}

export function shellToResolveResult(shell: StoreShellPayload): PublicStoreResolveResult {
  if (shell.status === "ok" && shell.store) return { status: "ok", store: shell.store };
  if (shell.status === "unavailable") return { status: "unavailable", store: shell.store };
  return { status: "not_found" };
}

export function parseStoreHome(value: unknown): StoreHomePayload {
  const shell = parseStoreShell(value);
  const row = asRecord(value);
  return {
    ...shell,
    featured: parseListingCards(row?.featured),
    products: parseListingCards(row?.products),
  };
}

export function parseInventoryPage(value: unknown): InventoryPagePayload {
  const row = asRecord(value);
  return {
    items: parseListingCards(row?.items),
    total: asNumber(row?.total),
  };
}

export function parseDashboardCounts(value: unknown): DashboardCounts {
  const row = asRecord(value);
  return {
    products: asNumber(row?.products),
    categories: asNumber(row?.categories),
    customers: asNumber(row?.customers),
    orders: asNumber(row?.orders),
    inventory_units: asNumber(row?.inventory_units),
    inventory_value: asNumber(row?.inventory_value),
    low_stock: asNumber(row?.low_stock),
    expiring_batches: asNumber(row?.expiring_batches),
    today_sales: asNumber(row?.today_sales),
    today_cash: asNumber(row?.today_cash),
    today_order_count: asNumber(row?.today_order_count),
    pending_online_orders: asNumber(row?.pending_online_orders),
  };
}

export function listingCardToListItem(card: ListingCard): StoreProductListItem {
  const storeProduct: StoreProduct = {
    id: card.id,
    store_id: card.store_id,
    product_id: card.product_id,
    is_active: card.is_active,
    is_featured: card.is_featured,
    sale_policy: card.sale_policy,
    rack_location: card.rack_location,
    reorder_level: card.reorder_level,
    on_hand_quantity: card.on_hand_quantity,
    reserved_quantity: card.reserved_quantity,
    available_quantity: card.available_quantity,
    listing_mrp: card.mrp,
    listing_selling_price: card.selling_price,
    listing_batch_id: null,
    created_at: card.created_at,
    updated_at: card.updated_at,
  };

  const product: MasterProduct = {
    id: card.product_id,
    category_id: card.category_id,
    name: card.name,
    generic_name: card.generic_name,
    composition: card.composition,
    manufacturer: card.manufacturer,
    strength: card.strength,
    dosage_form: card.dosage_form,
    product_kind: card.kind,
    drug_schedule: card.schedule,
    hsn_code: card.hsn_code,
    gst_rate: card.gst_rate ?? 5,
    track_batch: card.track_batch,
    storage: card.storage,
    base_unit: card.base_unit,
    primary_pack_type: card.primary_pack_type,
    primary_pack_quantity: card.primary_pack_quantity,
    secondary_pack_type: card.secondary_pack_type,
    secondary_pack_quantity: card.secondary_pack_quantity,
    slug: card.slug,
    description: card.description,
    image_url: card.image_url,
    requires_prescription: card.requires_prescription,
    is_system: card.is_system ?? true,
    approval_status: "approved",
    is_active: true,
    created_at: card.created_at,
    updated_at: card.updated_at,
  };

  return {
    store_product: storeProduct,
    product,
    category_name: card.category_name,
    stock_count: card.available_quantity,
    unit_price: Number(card.selling_price ?? 0),
    mrp: card.mrp,
  };
}

export function listingCardToPosProduct(card: ListingCard): PosProductResult {
  return {
    store_product_id: card.id,
    name: card.name,
    generic_name: card.generic_name,
    manufacturer: card.manufacturer,
    category_name: card.category_name,
    requires_prescription: card.requires_prescription,
    stock_count: card.available_quantity,
    mrp: card.mrp,
    unit_price: Number(card.selling_price ?? 0),
    base_unit: card.base_unit,
    primary_pack_type: card.primary_pack_type,
    primary_pack_quantity: card.primary_pack_quantity,
  };
}

export function listingCardToPurchaseOption(card: ListingCard): PurchaseStoreProductOption {
  return {
    store_product_id: card.id,
    product_name: card.name,
    generic_name: card.generic_name,
    manufacturer: card.manufacturer,
    stock_count: card.available_quantity,
    base_unit: card.base_unit,
    primary_pack_type: card.primary_pack_type,
    primary_pack_quantity: card.primary_pack_quantity,
  };
}
