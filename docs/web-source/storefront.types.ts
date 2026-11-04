import type { Category } from "@/modules/categories/category.types";
import type { Order, OrderItem, OrderStatusHistoryEntry } from "@/modules/orders/order.types";
import type { StoreProductListItem } from "@/modules/products/product.types";

export type StorefrontMode = "marketplace" | "store";

export type PublicStoreStatus = "ok" | "not_found" | "unavailable";

/** Public-facing store shell — no owner internals. */
export type PublicStore = {
  id: string;
  name: string;
  slug: string;
  phone: string | null;
  description: string | null;
  address: string | null;
  city: string | null;
  state: string | null;
  pincode: string | null;
  latitude: number | null;
  longitude: number | null;
  logo_url: string | null;
  banner_url: string | null;
  whatsapp_number: string | null;
  opening_time: string | null;
  closing_time: string | null;
  service_radius_km: number;
  minimum_order_amount: number;
  delivery_charge: number;
  free_delivery_above: number | null;
  allow_cod: boolean;
  allow_manual_upi: boolean;
  allow_prescription_upload: boolean;
  module_pickup: boolean;
  module_delivery: boolean;
  upi_id: string | null;
  upi_qr_url: string | null;
  is_open: boolean;
  accepts_online_orders: boolean;
  sale_policy: string;
};

export type PublicStoreResolveResult =
  | { status: "ok"; store: PublicStore }
  | { status: "not_found" }
  | { status: "unavailable"; store: PublicStore | null };

export type NearbyStore = PublicStore & {
  distance_km: number;
};

/** Cross-store marketplace search hit (server-driven). */
export type MarketplaceProductResult = StoreProductListItem & {
  store_id: string;
  store_name: string;
  store_slug: string;
  distance_km: number | null;
};

export type StoreCatalogBootstrap = {
  storeId: string;
  categories: Category[];
  products: StoreProductListItem[];
  loadedAt: number;
};

export type StorefrontCustomerSession = {
  customerId: string;
  authUserId: string;
  phone: string;
  name: string | null;
};

export type StorefrontCartLine = {
  storeProductId: string;
  quantity: number;
};

export type StorefrontCartState = {
  storeId: string | null;
  items: StorefrontCartLine[];
};

export type StorefrontLocationState = {
  latitude: number;
  longitude: number;
  permission: "granted" | "denied" | "prompt" | "unsupported";
  resolvedAt: number;
};

export type RevalidateCartLineInput = {
  storeProductId: string;
  quantity: number;
};

export type RevalidatedCartLine = {
  storeProductId: string;
  quantity: number;
  name: string;
  unitPrice: number;
  mrp: number | null;
  stockCount: number;
  isActive: boolean;
  ok: boolean;
  message?: string;
};

export type RevalidateCartResult = {
  storeId: string;
  store: PublicStore;
  lines: RevalidatedCartLine[];
  subtotal: number;
  ok: boolean;
  messages: string[];
};

export type PlaceOnlineOrderInput = {
  storeId: string;
  items: RevalidateCartLineInput[];
  addressId?: string | null;
  address?: {
    label?: string | null;
    address_line_1: string;
    address_line_2?: string | null;
    city?: string | null;
    state?: string | null;
    pincode?: string | null;
    latitude?: number | null;
    longitude?: number | null;
  } | null;
  saveAddress?: boolean;
  fulfillmentType: "pickup" | "delivery";
  paymentMethod: "cod" | "upi";
  notes?: string | null;
};

export type PlaceOnlineOrderResult = {
  orderId: string;
  storeId: string;
  orderNumber: number | null;
  totalAmount: number;
};

export type StorefrontOrderListItem = {
  id: string;
  orderNumber: number;
  storeId: string;
  storeName: string;
  storeSlug: string | null;
  itemCount: number;
  totalAmount: number;
  status: string;
  placedAt: string;
  canCancel: boolean;
};

export type StorefrontOrderDetail = {
  order: Order;
  items: OrderItem[];
  statusHistory: OrderStatusHistoryEntry[];
  storeName: string;
  storeSlug: string | null;
  canCancel: boolean;
};
