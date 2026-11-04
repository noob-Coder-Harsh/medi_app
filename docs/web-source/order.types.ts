import type {
  FulfillmentType,
  InventoryReferenceType,
  InventoryTransactionType,
  OrderSource,
  OrderStatus,
} from "@/types/database";

export type { FulfillmentType, InventoryReferenceType, InventoryTransactionType, OrderSource, OrderStatus };

export interface CustomerSnapshot {
  id: string;
  name: string | null;
  phone: string;
}

export interface AddressSnapshot {
  label?: string | null;
  address_line_1?: string | null;
  address_line_2?: string | null;
  city?: string | null;
  state?: string | null;
  pincode?: string | null;
  latitude?: number | null;
  longitude?: number | null;
}

export interface PricingSnapshot {
  subtotal: number;
  discount: number;
  delivery: number;
  tax: number;
  total: number;
}

export interface ProductSnapshot {
  product_id: string;
  store_product_id: string;
  name: string;
  generic_name: string | null;
  manufacturer: string | null;
  strength: string | null;
  dosage_form: string | null;
  drug_schedule?: string | null;
  hsn_code?: string | null;
  gst_rate?: number | null;
  batch_no?: string | null;
  expires_at?: string | null;
  mrp: number | null;
  packaging?: {
    base_unit: string | null;
    primary_pack_type: string | null;
    primary_pack_quantity: number | null;
    secondary_pack_type: string | null;
    secondary_pack_quantity: number | null;
    label: string;
  } | null;
}

export interface FulfillmentSnapshot {
  fulfillment_type: FulfillmentType | null;
}

export interface OrderItemBatchAllocation {
  batch_id: string;
  quantity: number;
}

export interface CreateOrderItemInput {
  store_product_id: string;
  quantity: number;
  unit_price?: number;
  unit_mrp?: number | null;
}

export interface CreateOrderInput {
  customer_id: string;
  items: CreateOrderItemInput[];
  source: OrderSource;
  notes?: string | null;
  address_snapshot?: AddressSnapshot | null;
  fulfillment_type?: FulfillmentType | null;
  delivery_charge?: number;
  discount_amount?: number;
  tax_amount?: number;
  payment_method?: string;
  paid_amount?: number;
}

export interface ChangeOrderStatusInput {
  to_status: OrderStatus;
  actor_id?: string | null;
  notes?: string | null;
}

export interface RecordInventoryTransactionInput {
  store_id: string;
  store_product_id: string;
  batch_id?: string | null;
  type: InventoryTransactionType;
  quantity: number;
  reference_type: InventoryReferenceType;
  reference_id: string;
  notes?: string | null;
}

export interface Order {
  id: string;
  store_id: string;
  customer_id: string;
  prescription_id: string | null;
  order_number: number;
  source: OrderSource;
  status: OrderStatus;
  payment_method: string;
  payment_status: string;
  fulfillment_type: FulfillmentType | null;
  delivery_slot: string | null;
  estimated_delivery_at: string | null;
  actual_delivery_at: string | null;
  subtotal: number;
  delivery_charge: number;
  discount_amount: number;
  total_amount: number;
  customer_snapshot: CustomerSnapshot;
  address_snapshot: AddressSnapshot;
  pricing_snapshot: PricingSnapshot;
  notes: string | null;
  placed_at: string;
  created_at: string;
  updated_at: string;
}

export interface OrderItem {
  id: string;
  order_id: string;
  store_product_id: string;
  quantity: number;
  unit_price: number;
  total_price: number;
  product_snapshot: ProductSnapshot;
  fulfillment_snapshot: FulfillmentSnapshot | null;
  created_at: string;
  batch_allocations: OrderItemBatch[];
}

export interface OrderItemBatch {
  id: string;
  order_item_id: string;
  batch_id: string;
  quantity: number;
  created_at: string;
}

export interface OrderStatusHistoryEntry {
  id: string;
  order_id: string;
  from_status: OrderStatus | null;
  to_status: OrderStatus;
  actor_id: string | null;
  notes: string | null;
  created_at: string;
}

export interface InventoryTransaction {
  id: string;
  store_id: string;
  store_product_id: string;
  batch_id: string | null;
  type: InventoryTransactionType;
  quantity: number;
  reference_type: InventoryReferenceType;
  reference_id: string;
  notes: string | null;
  created_at: string;
}

export interface OrderListItem {
  id: string;
  order_number: number;
  customer_id: string;
  customer_name: string | null;
  customer_phone: string;
  item_count: number;
  total_amount: number;
  source: OrderSource;
  status: OrderStatus;
  placed_at: string;
}

export interface OrderDetail {
  order: Order;
  items: OrderItem[];
  status_history: OrderStatusHistoryEntry[];
}

export interface OrderSearchFilters {
  query?: string;
  status?: OrderStatus | "all";
  source?: OrderSource | "all";
  date_from?: string;
  date_to?: string;
  sort_by?: "order_number" | "amount" | "created" | "status";
  sort_dir?: "asc" | "desc";
}

export const ORDER_STATUS_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  draft: ["pending", "cancelled"],
  pending: ["confirmed", "delivered", "cancelled"],
  confirmed: ["processing", "cancelled"],
  processing: ["ready", "cancelled"],
  ready: ["out_for_delivery", "delivered", "cancelled"],
  out_for_delivery: ["delivered", "cancelled"],
  delivered: ["refunded"],
  cancelled: [],
  refunded: [],
};

export const EMPTY_ADDRESS_SNAPSHOT: AddressSnapshot = {};
