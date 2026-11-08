import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/dashboard_summary.dart';
import '../../../data/rpc/dashboard_rpc.dart';
import '../../../data/supabase_client.dart';

class TodayRangeController extends Notifier<DashboardRange> {
  @override
  DashboardRange build() => DashboardRange.today;

  void setRange(DashboardRange range) {
    if (state == range) return;
    state = range;
  }
}

final todayRangeProvider =
    NotifierProvider<TodayRangeController, DashboardRange>(
      TodayRangeController.new,
    );

class TodayController extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() {
    final range = ref.watch(todayRangeProvider);
    return _load(range);
  }

  Future<DashboardSummary> _load(DashboardRange range) async {
    if (!AppSupabase.isReady) return const DashboardSummary.empty();
    return ref.read(dashboardRpcProvider).getStoreDashboardSummary(range);
  }

  Future<void> refresh() async {
    final range = ref.read(todayRangeProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(range));
  }

  void setRange(DashboardRange range) {
    ref.read(todayRangeProvider.notifier).setRange(range);
  }
}

final todayDashboardProvider =
    AsyncNotifierProvider<TodayController, DashboardSummary>(
      TodayController.new,
    );
