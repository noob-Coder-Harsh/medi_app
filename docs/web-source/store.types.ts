import type { DeliverySlot } from "./delivery-slot.utils";

export interface Store {
  id: string;
  owner_id: string;
  name: string;
  slug: string;
  phone: string | null;
  email: string | null;
  description: string | null;
  gst_number: string | null;
  drug_license_number: string | null;
  pharmacist_name: string | null;
  pharmacist_registration_no: string | null;
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
  module_pos: boolean;
  module_pickup: boolean;
  module_delivery: boolean;
  delivery_slots: DeliverySlot[] | null;
  upi_id: string | null;
  upi_qr_url: string | null;
  is_open: boolean;
  is_active: boolean;
  accepts_online_orders: boolean;
  /** How medicines may be sold (presentation only; inventory stays base-unit). */
  sale_policy: string;
  onboarding_completed: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateStoreInput {
  name: string;
  slug?: string;
  phone?: string | null;
  email?: string | null;
  description?: string | null;
  address?: string | null;
  city?: string | null;
  state?: string | null;
  pincode?: string | null;
  gst_number?: string | null;
  drug_license_number?: string | null;
  whatsapp_number?: string | null;
}

export interface UpdateStoreInput {
  name?: string;
  slug?: string;
  phone?: string | null;
  email?: string | null;
  description?: string | null;
  gst_number?: string | null;
  drug_license_number?: string | null;
  pharmacist_name?: string | null;
  pharmacist_registration_no?: string | null;
  address?: string | null;
  city?: string | null;
  state?: string | null;
  pincode?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  logo_url?: string | null;
  banner_url?: string | null;
  whatsapp_number?: string | null;
  opening_time?: string | null;
  closing_time?: string | null;
  service_radius_km?: number;
  minimum_order_amount?: number;
  delivery_charge?: number;
  free_delivery_above?: number | null;
  allow_cod?: boolean;
  allow_manual_upi?: boolean;
  allow_prescription_upload?: boolean;
  module_pos?: boolean;
  module_pickup?: boolean;
  module_delivery?: boolean;
  delivery_slots?: DeliverySlot[] | null;
  upi_id?: string | null;
  upi_qr_url?: string | null;
  is_open?: boolean;
  is_active?: boolean;
  sale_policy?: string;
  onboarding_completed?: boolean;
}

export interface StorePanelContext {
  store: Store | null;
  hasStore: boolean;
}
