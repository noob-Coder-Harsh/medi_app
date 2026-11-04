import type { OrderDetail } from "@/modules/orders/order.types";
import type { OrderListItem } from "@/modules/orders/order.types";

export type PosPaymentMethod = "cash" | "upi" | "card" | "credit" | "mixed";

export type PosDiscountType = "none" | "fixed" | "percentage";

export interface PosDiscount {
  type: PosDiscountType;
  value: number;
}

export interface PosProductResult {
  store_product_id: string;
  name: string;
  generic_name: string | null;
  manufacturer: string | null;
  category_name: string | null;
  requires_prescription: boolean;
  stock_count: number;
  mrp: number | null;
  unit_price: number;
  base_unit: string | null;
  primary_pack_type: string | null;
  primary_pack_quantity: number | null;
}

export interface PosCartItem {
  store_product_id: string;
  name: string;
  generic_name: string | null;
  manufacturer: string | null;
  category_name: string | null;
  requires_prescription: boolean;
  stock_count: number;
  mrp: number | null;
  unit_price: number;
  quantity: number;
  base_unit: string | null;
  primary_pack_type: string | null;
  primary_pack_quantity: number | null;
}

export interface PosCustomerCard {
  customer_id: string;
  phone: string;
  name: string | null;
  total_orders: number;
  loyalty_points: number;
}

export interface PosAllocationPreview {
  batch_no: string;
  expires_at: string | null;
  quantity: number;
}

export interface PosCheckoutItem {
  store_product_id: string;
  quantity: number;
  unit_price: number;
  unit_mrp?: number | null;
}

export interface PosCheckoutInput {
  customer_id: string;
  items: PosCheckoutItem[];
  payment_method: PosPaymentMethod;
  paid_amount: number;
  discount: PosDiscount;
  tax_amount?: number;
  notes?: string | null;
}

export interface PosCheckoutResult {
  order: OrderDetail;
}

export type PosRecentSale = OrderListItem;

export interface PosTotals {
  subtotal: number;
  discount: number;
  delivery: number;
  tax: number;
  grand_total: number;
}
