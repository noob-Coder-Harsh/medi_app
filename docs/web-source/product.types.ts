export interface MasterProduct {
  id: string;
  category_id: string | null;
  name: string;
  generic_name: string | null;
  composition: string | null;
  manufacturer: string | null;
  strength: string | null;
  dosage_form: string | null;
  product_kind: string;
  drug_schedule: string;
  hsn_code: string | null;
  gst_rate: number;
  track_batch: boolean;
  storage: string;
  /** Smallest sellable unit label (metadata; stock is always in this unit). */
  base_unit: string | null;
  primary_pack_type: string | null;
  primary_pack_quantity: number | null;
  secondary_pack_type: string | null;
  secondary_pack_quantity: number | null;
  slug: string;
  description: string | null;
  image_url: string | null;
  /** Derived from drug_schedule. Not a DB column. */
  requires_prescription: boolean;
  is_system: boolean;
  approval_status: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface StoreProduct {
  id: string;
  store_id: string;
  product_id: string;
  is_active: boolean;
  is_featured: boolean;
  sale_policy: string;
  rack_location: string | null;
  reorder_level: number;
  on_hand_quantity: number;
  reserved_quantity: number;
  available_quantity: number;
  listing_mrp: number | null;
  listing_selling_price: number | null;
  listing_batch_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface InventoryBatch {
  id: string;
  store_product_id: string;
  batch_no: string | null;
  purchase_price: number | null;
  mrp: number;
  selling_price: number;
  quantity: number;
  available_quantity: number;
  reserved_quantity: number;
  manufactured_at: string | null;
  expires_at: string | null;
  created_at: string;
}

export interface StoreProductListItem {
  store_product: StoreProduct;
  product: MasterProduct;
  category_name: string | null;
  stock_count: number;
  /** FEFO selling price from available batches (0 if none). */
  unit_price?: number;
  mrp?: number | null;
}

export interface CatalogProductItem extends MasterProduct {
  category_name: string | null;
  is_in_store: boolean;
}

export interface CatalogBrowseResult {
  available: CatalogProductItem[];
}

export interface BulkAddProductsResult {
  added: string[];
  skipped: string[];
  products: StoreProductListItem[];
}

export interface BulkStoreProductMutationResult {
  succeeded: string[];
  failed: string[];
}

export interface CreateCustomProductInput {
  category_id: string;
  name: string;
  generic_name?: string | null;
  manufacturer?: string | null;
  strength?: string | null;
  dosage_form?: string | null;
  base_unit?: string | null;
  primary_pack_type?: string | null;
  primary_pack_quantity?: number | null;
  secondary_pack_type?: string | null;
  secondary_pack_quantity?: number | null;
  description?: string | null;
  requires_prescription?: boolean;
  drug_schedule?: string;
  product_kind?: string;
  composition?: string | null;
  hsn_code?: string | null;
  gst_rate?: number;
  track_batch?: boolean;
  storage?: string;
  opening_batch?: OpeningBatchInput;
}

export interface OpeningBatchInput {
  batch_no: string;
  mrp: number;
  selling_price: number;
  quantity: number;
  manufactured_at?: string | null;
  expires_at?: string | null;
  purchase_price?: number | null;
}

export interface UpdateStoreProductInput {
  category_id?: string;
  name?: string;
  generic_name?: string | null;
  manufacturer?: string | null;
  strength?: string | null;
  dosage_form?: string | null;
  base_unit?: string | null;
  primary_pack_type?: string | null;
  primary_pack_quantity?: number | null;
  secondary_pack_type?: string | null;
  secondary_pack_quantity?: number | null;
  description?: string | null;
  requires_prescription?: boolean;
  drug_schedule?: string;
  product_kind?: string;
  composition?: string | null;
  hsn_code?: string | null;
  gst_rate?: number;
  track_batch?: boolean;
  storage?: string;
  is_active?: boolean;
  sale_policy?: string;
  rack_location?: string | null;
  reorder_level?: number;
}

export interface UpdateBatchInput {
  batch_no?: string;
  mrp?: number;
  selling_price?: number;
  available_quantity?: number;
  quantity?: number;
  manufactured_at?: string | null;
  expires_at?: string | null;
  purchase_price?: number | null;
}

export interface StoreProductDetail {
  store_product: StoreProduct;
  product: MasterProduct;
  category_name: string | null;
  stock_count: number;
  unit_price?: number;
  mrp?: number | null;
  batches: InventoryBatch[];
}
