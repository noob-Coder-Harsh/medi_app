-- Additive replace. Paste in the Supabase SQL Editor (Role: postgres).
-- Owner dashboard summary: range sales, inventory health/value, POs, expiry alerts.
--
-- If you get: permission denied for schema public (42501)
-- the SQL Editor is not running as postgres. Set Role to postgres, then re-run.

drop function if exists public.get_store_dashboard_summary(text);

create or replace function public.get_store_dashboard_summary(
  p_range text default 'today'
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  sid uuid := public.auth_store_id();
  v_range text := lower(coalesce(nullif(trim(p_range), ''), 'today'));
  v_since timestamptz;
  v_products int;
  v_categories int;
  v_customers int;
  v_metrics jsonb;
  v_inventory_value jsonb;
  v_sales jsonb;
  v_alerts jsonb;
  v_open_po int;
  v_purchase_count int;
  v_unpaid_po int;
  v_supplier_due numeric;
begin
  if sid is null then
    raise exception 'Not authorized';
  end if;

  if v_range not in ('today', '7d', '30d', '90d', 'all') then
    v_range := 'today';
  end if;

  v_since := case v_range
    when 'today' then date_trunc('day', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata'
    when '7d' then now() - interval '7 days'
    when '30d' then now() - interval '30 days'
    when '90d' then now() - interval '90 days'
    else null
  end;

  select count(*)::int into v_products
  from public.store_products sp
  where sp.store_id = sid;

  select count(*)::int into v_categories
  from public.store_categories sc
  where sc.store_id = sid;

  select count(*)::int into v_customers
  from public.store_customers sc
  where sc.store_id = sid;

  select jsonb_build_object(
    'totalSkus', count(*)::int,
    'inStock', count(*) filter (
      where sp.available_quantity > 0
        and sp.available_quantity > case
          when sp.reorder_level > 0 then sp.reorder_level else 5 end
    )::int,
    'lowStock', count(*) filter (
      where sp.available_quantity > 0
        and sp.available_quantity <= case
          when sp.reorder_level > 0 then sp.reorder_level else 5 end
    )::int,
    'outOfStock', count(*) filter (where sp.available_quantity <= 0)::int
  )
  into v_metrics
  from public.store_products sp
  where sp.store_id = sid;

  select jsonb_build_object(
    'atPurchase', coalesce(sum(ib.available_quantity * coalesce(ib.purchase_price, 0)), 0),
    'atSelling', coalesce(sum(ib.available_quantity * coalesce(ib.selling_price, 0)), 0),
    'atMrp', coalesce(sum(ib.available_quantity * coalesce(ib.mrp, 0)), 0)
  )
  into v_inventory_value
  from public.inventory_batches ib
  join public.store_products sp on sp.id = ib.store_product_id
  where sp.store_id = sid;

  select jsonb_build_object(
    'orderCount', count(*)::int,
    'cancelledCount', count(*) filter (where o.status = 'cancelled')::int,
    'onlineOrderCount', count(*) filter (where o.source = 'online')::int,
    'posOrderCount', count(*) filter (where o.source = 'pos')::int,
    'salesTotal', coalesce(sum(o.total_amount) filter (
      where o.status not in ('cancelled', 'draft', 'refunded')
    ), 0),
    'onlineSalesTotal', coalesce(sum(o.total_amount) filter (
      where o.source = 'online' and o.status not in ('cancelled', 'draft', 'refunded')
    ), 0),
    'posSalesTotal', coalesce(sum(o.total_amount) filter (
      where o.source = 'pos' and o.status not in ('cancelled', 'draft', 'refunded')
    ), 0),
    'salesOrderCount', count(*) filter (
      where o.status not in ('cancelled', 'draft', 'refunded')
    )::int,
    'prescriptionOrderCount', count(*) filter (
      where o.prescription_id is not null
        and o.status not in ('cancelled', 'draft', 'refunded')
    )::int,
    'statusCounts', jsonb_build_object(
      'delivered', count(*) filter (where o.status = 'delivered')::int,
      'processing', count(*) filter (
        where o.status in ('pending', 'confirmed', 'processing')
      )::int,
      'ready', count(*) filter (where o.status = 'ready')::int,
      'cancelled', count(*) filter (where o.status = 'cancelled')::int,
      'other', count(*) filter (
        where o.status not in (
          'delivered', 'pending', 'confirmed', 'processing', 'ready', 'cancelled'
        )
      )::int
    )
  )
  into v_sales
  from public.orders o
  where o.store_id = sid
    and (v_since is null or o.placed_at >= v_since);

  select jsonb_build_object(
    'expiring30', (
      select count(*)::int
      from public.inventory_batches ib
      join public.store_products sp on sp.id = ib.store_product_id
      where sp.store_id = sid
        and ib.available_quantity > 0
        and ib.expires_at is not null
        and ib.expires_at <= (current_date + 30)
    ),
    'expiring90', (
      select count(*)::int
      from public.inventory_batches ib
      join public.store_products sp on sp.id = ib.store_product_id
      where sp.store_id = sid
        and ib.available_quantity > 0
        and ib.expires_at is not null
        and ib.expires_at > (current_date + 30)
        and ib.expires_at <= (current_date + 90)
    ),
    'lowStock', coalesce((v_metrics ->> 'lowStock')::int, 0)
  )
  into v_alerts;

  select count(*)::int into v_open_po
  from public.purchase_orders po
  where po.store_id = sid
    and po.status = 'draft';

  select count(*)::int into v_purchase_count
  from public.purchase_orders po
  where po.store_id = sid;

  select count(*)::int into v_unpaid_po
  from public.purchase_orders po
  where po.store_id = sid
    and po.payment_status in ('pending', 'partial')
    and coalesce(po.due_amount, 0) > 0;

  select coalesce(sum(s.current_balance), 0) into v_supplier_due
  from public.suppliers s
  where s.store_id = sid
    and s.deleted_at is null;

  return jsonb_build_object(
    'range', v_range,
    'sales', coalesce(v_sales, '{}'::jsonb),
    'catalogCounts', jsonb_build_object(
      'products', coalesce(v_products, 0),
      'categories', coalesce(v_categories, 0),
      'customers', coalesce(v_customers, 0)
    ),
    'inventoryMetrics', coalesce(v_metrics, '{}'::jsonb),
    'inventoryValue', coalesce(v_inventory_value, '{}'::jsonb),
    'alerts', coalesce(v_alerts, '{}'::jsonb),
    'openPoCount', coalesce(v_open_po, 0),
    'purchaseCount', coalesce(v_purchase_count, 0),
    'unpaidPoCount', coalesce(v_unpaid_po, 0),
    'supplierDueTotal', coalesce(v_supplier_due, 0)
  );
end;
$$;

revoke all on function public.get_store_dashboard_summary(text) from public;
grant execute on function public.get_store_dashboard_summary(text) to authenticated;
