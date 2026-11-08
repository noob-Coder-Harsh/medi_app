import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_counts.dart';
import '../models/dashboard_summary.dart';
import '../supabase_client.dart';

/// Owner dashboard RPCs.
class DashboardRpc {
  DashboardRpc(this._client);

  final SupabaseClient _client;

  /// Legacy IST “today” counts — prefer [getStoreDashboardSummary].
  Future<DashboardCounts> getStoreDashboardCounts() async {
    final raw = await _client.rpc('get_store_dashboard_counts');
    return parseDashboardCounts(raw);
  }

  Future<DashboardSummary> getStoreDashboardSummary(
    DashboardRange range,
  ) async {
    final raw = await _client.rpc(
      'get_store_dashboard_summary',
      params: <String, dynamic>{'p_range': range.apiValue},
    );
    return parseDashboardSummary(raw);
  }
}

final dashboardRpcProvider = Provider<DashboardRpc>((Ref ref) {
  return DashboardRpc(AppSupabase.client);
});
