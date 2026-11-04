export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];
export type OrderStatus =
  | "draft"
  | "pending"
  | "confirmed"
  | "processing"
  | "ready"
  | "out_for_delivery"
  | "delivered"
  | "cancelled"
  | "refunded";

export type OrderSource = "pos" | "online" | "kiosk";

export type InventoryTransactionType =
  | "purchase"
  | "sale"
  | "return"
  | "customer_return"
  | "adjustment"
  | "expired"
  | "damaged"
  | "opening_stock";

export type InventoryReferenceType = "order" | "adjustment" | "purchase" | "return" | "opening_stock";

export type ReturnType = "customer" | "supplier" | "damage" | "expiry";

export type ReturnStatus = "pending" | "inspection" | "approved" | "rejected" | "completed";

export type ReturnRefundStatus = "none" | "pending" | "processed" | "failed";

export type ReturnItemCondition = "sealed" | "opened" | "damaged" | "expired";

export type ReturnRestockAction = "restock" | "dispose" | "supplier_return";

export type PurchaseOrderStatus = "draft" | "completed" | "cancelled";

export type PurchasePaymentStatus = "pending" | "partial" | "paid";

export type PaymentDirection = "inflow" | "outflow";

export type PaymentType = "sale" | "purchase" | "refund" | "supplier_settlement" | "adjustment";

export type PaymentMethod = "cash" | "upi" | "card" | "bank_transfer" | "credit" | "wallet";

export type PaymentStatus = "pending" | "partial" | "paid" | "failed" | "refunded" | "cancelled";

export type FulfillmentType = "counter" | "pickup" | "delivery";

export type PrescriptionStatus = "pending" | "approved" | "rejected";

export type StoreUserRole = "owner" | "manager" | "staff" | "delivery" | "customer_support";

export interface Database {
  public: {
    Tables: {
      stores: {
        Row: {
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
          delivery_slots: Json | null;
          upi_id: string | null;
          upi_qr_url: string | null;
          is_open: boolean;
          is_active: boolean;
          accepts_online_orders: boolean;
          sale_policy: string;
          onboarding_completed: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          owner_id: string;
          name: string;
          slug: string;
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
          delivery_slots?: Json | null;
          upi_id?: string | null;
          upi_qr_url?: string | null;
          is_open?: boolean;
          is_active?: boolean;
          sale_policy?: string;
          onboarding_completed?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          owner_id?: string;
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
          delivery_slots?: Json | null;
          upi_id?: string | null;
          upi_qr_url?: string | null;
          is_open?: boolean;
          is_active?: boolean;
          sale_policy?: string;
          onboarding_completed?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      store_users: {
        Row: {
          id: string;
          store_id: string | null;
          auth_user_id: string;
          full_name: string | null;
          email: string | null;
          phone: string | null;
          role: string;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          store_id?: string | null;
          auth_user_id: string;
          full_name?: string | null;
          email?: string | null;
          phone?: string | null;
          role?: string;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          store_id?: string | null;
          auth_user_id?: string;
          full_name?: string | null;
          email?: string | null;
          phone?: string | null;
          role?: string;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      categories: {
        Row: {
          id: string;
          name: string;
          slug: string;
          icon_url: string | null;
          sort_order: number;
          is_system: boolean;
          is_active: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          slug: string;
          icon_url?: string | null;
          sort_order?: number;
          is_system?: boolean;
          is_active?: boolean;
          created_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          slug?: string;
          icon_url?: string | null;
          sort_order?: number;
          is_system?: boolean;
          is_active?: boolean;
          created_at?: string;
        };
      };
      store_categories: {
        Row: {
          store_id: string;
          category_id: string;
        };
        Insert: {
          store_id: string;
          category_id: string;
        };
        Update: {
          store_id?: string;
          category_id?: string;
        };
      };
      master_products: {
        Row: {
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
          base_unit: string | null;
          primary_pack_type: string | null;
          primary_pack_quantity: number | null;
          secondary_pack_type: string | null;
          secondary_pack_quantity: number | null;
          slug: string;
          description: string | null;
          image_url: string | null;
          is_system: boolean;
          approval_status: string;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          category_id?: string | null;
          name: string;
          generic_name?: string | null;
          composition?: string | null;
          manufacturer?: string | null;
          strength?: string | null;
          dosage_form?: string | null;
          product_kind?: string;
          drug_schedule?: string;
          hsn_code?: string | null;
          gst_rate?: number;
          track_batch?: boolean;
          storage?: string;
          base_unit?: string | null;
          primary_pack_type?: string | null;
          primary_pack_quantity?: number | null;
          secondary_pack_type?: string | null;
          secondary_pack_quantity?: number | null;
          slug: string;
          description?: string | null;
          image_url?: string | null;
          is_system?: boolean;
          approval_status?: string;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          category_id?: string | null;
          name?: string;
          generic_name?: string | null;
          composition?: string | null;
          manufacturer?: string | null;
          strength?: string | null;
          dosage_form?: string | null;
          product_kind?: string;
          drug_schedule?: string;
          hsn_code?: string | null;
          gst_rate?: number;
          track_batch?: boolean;
          storage?: string;
          base_unit?: string | null;
          primary_pack_type?: string | null;
          primary_pack_quantity?: number | null;
          secondary_pack_type?: string | null;
          secondary_pack_quantity?: number | null;
          slug?: string;
          description?: string | null;
          image_url?: string | null;
          is_system?: boolean;
          approval_status?: string;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      store_products: {
        Row: {
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
        };
        Insert: {
          id?: string;
          store_id: string;
          product_id: string;
          is_active?: boolean;
          is_featured?: boolean;
          sale_policy?: string;
          rack_location?: string | null;
          reorder_level?: number;
          on_hand_quantity?: number;
          reserved_quantity?: number;
          listing_mrp?: number | null;
          listing_selling_price?: number | null;
          listing_batch_id?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          store_id?: string;
          product_id?: string;
          is_active?: boolean;
          is_featured?: boolean;
          sale_policy?: string;
          rack_location?: string | null;
          reorder_level?: number;
          on_hand_quantity?: number;
          reserved_quantity?: number;
          listing_mrp?: number | null;
          listing_selling_price?: number | null;
          listing_batch_id?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      inventory_batches: {
        Row: {
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
        };
        Insert: {
          id?: string;
          store_product_id: string;
          batch_no?: string | null;
          purchase_price?: number | null;
          mrp: number;
          selling_price: number;
          quantity: number;
          available_quantity: number;
          reserved_quantity?: number;
          manufactured_at?: string | null;
          expires_at?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          store_product_id?: string;
          batch_no?: string | null;
          purchase_price?: number | null;
          mrp?: number;
          selling_price?: number;
          quantity?: number;
          available_quantity?: number;
          reserved_quantity?: number;
          manufactured_at?: string | null;
          expires_at?: string | null;
          created_at?: string;
        };
      };
      customers: {
        Row: {
          id: string;
          auth_user_id: string | null;
          phone: string;
          name: string | null;
          email: string | null;
          gender: string | null;
          dob: string | null;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          auth_user_id?: string | null;
          phone: string;
          name?: string | null;
          email?: string | null;
          gender?: string | null;
          dob?: string | null;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          auth_user_id?: string | null;
          phone?: string;
          name?: string | null;
          email?: string | null;
          gender?: string | null;
          dob?: string | null;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      store_customers: {
        Row: {
          id: string;
          store_id: string;
          customer_id: string;
          notes: string | null;
          loyalty_points: number;
          total_orders: number;
          total_spent: number;
          current_balance: number;
          last_order_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          store_id: string;
          customer_id: string;
          notes?: string | null;
          loyalty_points?: number;
          total_orders?: number;
          total_spent?: number;
          current_balance?: number;
          last_order_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          store_id?: string;
          customer_id?: string;
          notes?: string | null;
          loyalty_points?: number;
          total_orders?: number;
          total_spent?: number;
          current_balance?: number;
          last_order_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      suppliers: {
        Row: {
          id: string;
          store_id: string;
          name: string;
          contact_person: string | null;
          phone: string | null;
          email: string | null;
          gst_number: string | null;
          drug_license_number: string | null;
          address: string | null;
          opening_balance: number;
          current_balance: number;
          payment_terms_days: number;
          notes: string | null;
          is_active: boolean;
          last_purchase_at: string | null;
          total_purchase_amount: number;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: string;
          store_id: string;
          name: string;
          contact_person?: string | null;
          phone?: string | null;
          email?: string | null;
          gst_number?: string | null;
          drug_license_number?: string | null;
          address?: string | null;
          opening_balance?: number;
          current_balance?: number;
          payment_terms_days?: number;
          notes?: string | null;
          is_active?: boolean;
          last_purchase_at?: string | null;
          total_purchase_amount?: number;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: string;
          store_id?: string;
          name?: string;
          contact_person?: string | null;
          phone?: string | null;
          email?: string | null;
          gst_number?: string | null;
          drug_license_number?: string | null;
          address?: string | null;
          opening_balance?: number;
          current_balance?: number;
          payment_terms_days?: number;
          notes?: string | null;
          is_active?: boolean;
          last_purchase_at?: string | null;
          total_purchase_amount?: number;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
      };
      purchase_orders: {
        Row: {
          id: string;
          store_id: string;
          supplier_id: string;
          invoice_number: string;
          invoice_date: string;
          subtotal: number;
          discount_amount: number;
          tax_amount: number;
          other_charges: number;
          round_off_amount: number;
          grand_total: number;
          payment_status: string;
          payment_method: string | null;
          paid_amount: number;
          due_amount: number;
          notes: string | null;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          store_id: string;
          supplier_id: string;
          invoice_number: string;
          invoice_date?: string;
          subtotal?: number;
          discount_amount?: number;
          tax_amount?: number;
          other_charges?: number;
          round_off_amount?: number;
          grand_total?: number;
          payment_status?: string;
          payment_method?: string | null;
          paid_amount?: number;
          due_amount?: number;
          notes?: string | null;
          status?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          store_id?: string;
          supplier_id?: string;
          invoice_number?: string;
          invoice_date?: string;
          subtotal?: number;
          discount_amount?: number;
          tax_amount?: number;
          other_charges?: number;
          round_off_amount?: number;
          grand_total?: number;
          payment_status?: string;
          payment_method?: string | null;
          paid_amount?: number;
          due_amount?: number;
          notes?: string | null;
          status?: string;
          created_at?: string;
          updated_at?: string;
        };
      };
      purchase_order_items: {
        Row: {
          id: string;
          purchase_order_id: string;
          store_product_id: string;
          batch_number: string;
          quantity: number;
          purchase_price: number;
          mrp: number;
          selling_price: number;
          tax_percent: number;
          discount_percent: number;
          manufactured_at: string | null;
          expires_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          purchase_order_id: string;
          store_product_id: string;
          batch_number: string;
          quantity: number;
          purchase_price: number;
          mrp: number;
          selling_price: number;
          tax_percent?: number;
          discount_percent?: number;
          manufactured_at?: string | null;
          expires_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          purchase_order_id?: string;
          store_product_id?: string;
          batch_number?: string;
          quantity?: number;
          purchase_price?: number;
          mrp?: number;
          selling_price?: number;
          tax_percent?: number;
          discount_percent?: number;
          manufactured_at?: string | null;
          expires_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      customer_addresses: {
        Row: {
          id: string;
          customer_id: string;
          label: string | null;
          address_line_1: string;
          address_line_2: string | null;
          city: string | null;
          state: string | null;
          pincode: string | null;
          latitude: number | null;
          longitude: number | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          customer_id: string;
          label?: string | null;
          address_line_1: string;
          address_line_2?: string | null;
          city?: string | null;
          state?: string | null;
          pincode?: string | null;
          latitude?: number | null;
          longitude?: number | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          customer_id?: string;
          label?: string | null;
          address_line_1?: string;
          address_line_2?: string | null;
          city?: string | null;
          state?: string | null;
          pincode?: string | null;
          latitude?: number | null;
          longitude?: number | null;
          created_at?: string;
        };
      };
      prescriptions: {
        Row: {
          id: string;
          customer_id: string;
          store_id: string;
          file_url: string;
          status: string;
          pharmacist_user_id: string | null;
          reviewed_at: string | null;
          doctor_name: string | null;
          doctor_registration_no: string | null;
          patient_name: string | null;
          patient_address: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          customer_id: string;
          store_id: string;
          file_url: string;
          status?: string;
          pharmacist_user_id?: string | null;
          reviewed_at?: string | null;
          doctor_name?: string | null;
          doctor_registration_no?: string | null;
          patient_name?: string | null;
          patient_address?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          customer_id?: string;
          store_id?: string;
          file_url?: string;
          status?: string;
          pharmacist_user_id?: string | null;
          reviewed_at?: string | null;
          doctor_name?: string | null;
          doctor_registration_no?: string | null;
          patient_name?: string | null;
          patient_address?: string | null;
          created_at?: string;
        };
      };
      orders: {
        Row: {
          id: string;
          store_id: string;
          customer_id: string;
          prescription_id: string | null;
          pharmacist_user_id: string | null;
          order_number: number;
          source: string;
          status: string;
          payment_method: string;
          payment_status: string;
          fulfillment_type: string | null;
          delivery_slot: string | null;
          estimated_delivery_at: string | null;
          actual_delivery_at: string | null;
          subtotal: number;
          delivery_charge: number;
          discount_amount: number;
          total_amount: number;
          customer_snapshot: Json;
          address_snapshot: Json;
          pricing_snapshot: Json;
          notes: string | null;
          placed_at: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          store_id: string;
          customer_id: string;
          prescription_id?: string | null;
          pharmacist_user_id?: string | null;
          order_number?: number;
          source?: string;
          status?: string;
          payment_method?: string;
          payment_status?: string;
          fulfillment_type?: string | null;
          delivery_slot?: string | null;
          estimated_delivery_at?: string | null;
          actual_delivery_at?: string | null;
          subtotal: number;
          delivery_charge?: number;
          discount_amount?: number;
          total_amount: number;
          customer_snapshot: Json;
          address_snapshot: Json;
          pricing_snapshot: Json;
          notes?: string | null;
          placed_at?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          store_id?: string;
          customer_id?: string;
          prescription_id?: string | null;
          pharmacist_user_id?: string | null;
          order_number?: number;
          source?: string;
          status?: string;
          payment_method?: string;
          payment_status?: string;
          fulfillment_type?: string | null;
          delivery_slot?: string | null;
          estimated_delivery_at?: string | null;
          actual_delivery_at?: string | null;
          subtotal?: number;
          delivery_charge?: number;
          discount_amount?: number;
          total_amount?: number;
          customer_snapshot?: Json;
          address_snapshot?: Json;
          pricing_snapshot?: Json;
          notes?: string | null;
          placed_at?: string;
          created_at?: string;
          updated_at?: string;
        };
      };
      order_items: {
        Row: {
          id: string;
          order_id: string;
          store_product_id: string;
          quantity: number;
          unit_price: number;
          total_price: number;
          product_snapshot: Json;
          fulfillment_snapshot: Json | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          order_id: string;
          store_product_id: string;
          quantity: number;
          unit_price: number;
          total_price: number;
          product_snapshot: Json;
          fulfillment_snapshot?: Json | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          order_id?: string;
          store_product_id?: string;
          quantity?: number;
          unit_price?: number;
          total_price?: number;
          product_snapshot?: Json;
          fulfillment_snapshot?: Json | null;
          created_at?: string;
        };
      };
      order_item_batches: {
        Row: {
          id: string;
          order_item_id: string;
          batch_id: string;
          quantity: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          order_item_id: string;
          batch_id: string;
          quantity: number;
          created_at?: string;
        };
        Update: {
          id?: string;
          order_item_id?: string;
          batch_id?: string;
          quantity?: number;
          created_at?: string;
        };
      };
      order_status_history: {
        Row: {
          id: string;
          order_id: string;
          from_status: string | null;
          to_status: string;
          actor_id: string | null;
          notes: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          order_id: string;
          from_status?: string | null;
          to_status: string;
          actor_id?: string | null;
          notes?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          order_id?: string;
          from_status?: string | null;
          to_status?: string;
          actor_id?: string | null;
          notes?: string | null;
          created_at?: string;
        };
      };
      inventory_transactions: {
        Row: {
          id: string;
          store_id: string;
          store_product_id: string;
          batch_id: string | null;
          type: string;
          quantity: number;
          reference_type: string;
          reference_id: string;
          notes: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          store_id: string;
          store_product_id: string;
          batch_id?: string | null;
          type: string;
          quantity: number;
          reference_type: string;
          reference_id: string;
          notes?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          store_id?: string;
          store_product_id?: string;
          batch_id?: string | null;
          type?: string;
          quantity?: number;
          reference_type?: string;
          reference_id?: string;
          notes?: string | null;
          created_at?: string;
        };
      };
      payments: {
        Row: {
          id: string;
          store_id: string;
          order_id: string | null;
          purchase_order_id: string | null;
          supplier_id: string | null;
          customer_id: string | null;
          payment_direction: string;
          payment_type: string;
          amount: number;
          method: string;
          status: string;
          transaction_id: string | null;
          reference_number: string | null;
          paid_at: string | null;
          notes: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          store_id: string;
          order_id?: string | null;
          purchase_order_id?: string | null;
          supplier_id?: string | null;
          customer_id?: string | null;
          payment_direction: string;
          payment_type: string;
          amount: number;
          method: string;
          status?: string;
          transaction_id?: string | null;
          reference_number?: string | null;
          paid_at?: string | null;
          notes?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          store_id?: string;
          order_id?: string | null;
          purchase_order_id?: string | null;
          supplier_id?: string | null;
          customer_id?: string | null;
          payment_direction?: string;
          payment_type?: string;
          amount?: number;
          method?: string;
          status?: string;
          transaction_id?: string | null;
          reference_number?: string | null;
          paid_at?: string | null;
          notes?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      returns: {
        Row: {
          id: string;
          store_id: string;
          order_id: string | null;
          customer_id: string | null;
          return_type: string;
          status: string;
          reason: string | null;
          notes: string | null;
          subtotal: number;
          refund_amount: number;
          refund_status: string;
          processed_by: string | null;
          processed_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          store_id: string;
          order_id?: string | null;
          customer_id?: string | null;
          return_type?: string;
          status?: string;
          reason?: string | null;
          notes?: string | null;
          subtotal?: number;
          refund_amount?: number;
          refund_status?: string;
          processed_by?: string | null;
          processed_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          store_id?: string;
          order_id?: string | null;
          customer_id?: string | null;
          return_type?: string;
          status?: string;
          reason?: string | null;
          notes?: string | null;
          subtotal?: number;
          refund_amount?: number;
          refund_status?: string;
          processed_by?: string | null;
          processed_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      return_items: {
        Row: {
          id: string;
          return_id: string;
          order_item_id: string | null;
          inventory_batch_id: string | null;
          quantity: number;
          unit_price: number;
          refund_amount: number;
          restock_action: string;
          condition: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          return_id: string;
          order_item_id?: string | null;
          inventory_batch_id?: string | null;
          quantity: number;
          unit_price?: number;
          refund_amount?: number;
          restock_action?: string;
          condition?: string;
          created_at?: string;
        };
        Update: {
          id?: string;
          return_id?: string;
          order_item_id?: string | null;
          inventory_batch_id?: string | null;
          quantity?: number;
          unit_price?: number;
          refund_amount?: number;
          restock_action?: string;
          condition?: string;
          created_at?: string;
        };
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      get_store_shell: { Args: { p_slug?: string | null; p_store_id?: string | null }; Returns: Json };
      get_store_home: { Args: { p_slug: string }; Returns: Json };
      search_store_catalog: {
        Args: { p_store_id: string; p_query?: string; p_category_id?: string | null; p_limit?: number };
        Returns: Json;
      };
      list_nearby_stores: { Args: { p_lat: number; p_lng: number; p_limit?: number }; Returns: Json };
      list_system_categories: { Args: Record<string, never>; Returns: Json };
      get_listing_cards: { Args: { p_store_id: string; p_ids: string[] }; Returns: Json };
      get_store_product: { Args: { p_store_id: string; p_slug: string }; Returns: Json };
      search_marketplace_products: {
        Args: { p_store_ids: string[]; p_query?: string; p_category_id?: string | null; p_limit?: number };
        Returns: Json;
      };
      get_pos_home: { Args: { p_limit?: number }; Returns: Json };
      search_pos_catalog: { Args: { p_query: string; p_limit?: number }; Returns: Json };
      list_store_inventory: {
        Args: {
          p_query?: string;
          p_category_id?: string | null;
          p_status?: string;
          p_rx?: string;
          p_stock?: string;
          p_sort?: string;
          p_sort_dir?: string;
          p_offset?: number;
          p_limit?: number;
        };
        Returns: Json;
      };
      get_store_dashboard_counts: { Args: Record<string, never>; Returns: Json };
    };
    Enums: {
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
}

export type Tables<T extends keyof Database["public"]["Tables"]> = Database["public"]["Tables"][T]["Row"];

export type TablesInsert<T extends keyof Database["public"]["Tables"]> = Database["public"]["Tables"][T]["Insert"];

export type TablesUpdate<T extends keyof Database["public"]["Tables"]> = Database["public"]["Tables"][T]["Update"];
