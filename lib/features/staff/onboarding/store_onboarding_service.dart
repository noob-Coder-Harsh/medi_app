import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/slug.dart';
import '../../../data/rpc/listing_rpc.dart';
import '../../../data/supabase_client.dart';
import '../auth/staff_auth_service.dart';
import '../auth/staff_user.dart';
import 'create_store_input.dart';

/// Creates the owner store and seeds system categories (same order as web).
/// Client writes under RLS until `/api/app/staff` onboarding exists.
class StoreOnboardingService {
  StoreOnboardingService({
    required StaffAuthService auth,
    ListingRpc? listing,
    ListingRpc Function()? listingFactory,
    SupabaseClient? client,
  }) : _auth = auth,
       _listing = listing,
       _listingFactory = listingFactory,
       _client = client;

  final StaffAuthService _auth;
  final ListingRpc? _listing;
  final ListingRpc Function()? _listingFactory;
  final SupabaseClient? _client;

  SupabaseClient get _supabase {
    final injected = _client;
    if (injected != null) return injected;
    return AppSupabase.client;
  }

  ListingRpc get _listingRpc {
    return _listing ?? _listingFactory?.call() ?? ListingRpc(_supabase);
  }

  Future<StaffUser> createStore(CreateStoreInput input) async {
    if (!_auth.isConfigured) {
      throw StateError('Staff sign-in is not configured');
    }

    final storeUser = await _auth.ensureStoreUser();
    if (storeUser.hasStore) {
      throw StateError('Store already exists for this owner');
    }

    final created = await _insertStoreWithUniqueSlug(
      ownerId: storeUser.id,
      input: input,
    );

    final assigned = await _assignStore(storeUser.id, created.id);
    await _seedSystemCategories(created.id);
    return assigned;
  }

  Future<_CreatedStore> _insertStoreWithUniqueSlug({
    required String ownerId,
    required CreateStoreInput input,
  }) async {
    var base = toSlug(input.slug?.trim().isNotEmpty == true ? input.slug! : input.name);
    if (base.isEmpty) base = 'pharmacy';
    if (isReservedStoreSlug(base)) base = '$base-store';

    PostgrestException? lastUnique;
    for (var attempt = 0; attempt < 20; attempt++) {
      final slug = attempt == 0 ? base : '$base-$attempt';
      if (isReservedStoreSlug(slug)) continue;

      try {
        final row = await _supabase
            .from('stores')
            .insert(<String, dynamic>{
              'owner_id': ownerId,
              'name': input.name.trim(),
              'slug': slug,
              'address': input.address.trim(),
              'city': input.city.trim(),
              'state': input.state.trim(),
              'pincode': input.pincode.trim(),
              if (_optional(input.phone) != null) 'phone': _optional(input.phone),
              if (_optional(input.email) != null) 'email': _optional(input.email),
              if (_optional(input.whatsappNumber) != null)
                'whatsapp_number': _optional(input.whatsappNumber),
              if (_optional(input.description) != null)
                'description': _optional(input.description),
              if (_optional(input.gstNumber) != null)
                'gst_number': _optional(input.gstNumber),
              if (_optional(input.drugLicenseNumber) != null)
                'drug_license_number': _optional(input.drugLicenseNumber),
            })
            .select('id, slug')
            .single();

        final map = Map<String, dynamic>.from(row as Map);
        return _CreatedStore(
          id: '${map['id']}',
          slug: '${map['slug']}',
        );
      } on PostgrestException catch (error) {
        if (error.code == '23505') {
          lastUnique = error;
          continue;
        }
        rethrow;
      }
    }

    throw lastUnique ?? StateError('Could not allocate a store URL');
  }

  Future<StaffUser> _assignStore(String storeUserId, String storeId) async {
    final updated = await _supabase
        .from('store_users')
        .update(<String, dynamic>{'store_id': storeId})
        .eq('id', storeUserId)
        .select()
        .single();
    return StaffUser.fromJson(Map<String, dynamic>.from(updated as Map));
  }

  Future<void> _seedSystemCategories(String storeId) async {
    final categories = await _listingRpc.listSystemCategories();
    if (categories.isEmpty) return;

    final rows = categories
        .map(
          (category) => <String, dynamic>{
            'store_id': storeId,
            'category_id': category.id,
          },
        )
        .toList();

    await _supabase.from('store_categories').upsert(
      rows,
      onConflict: 'store_id,category_id',
      ignoreDuplicates: true,
    );
  }

  String? _optional(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class _CreatedStore {
  const _CreatedStore({required this.id, required this.slug});

  final String id;
  final String slug;
}

final storeOnboardingServiceProvider = Provider<StoreOnboardingService>((
  Ref ref,
) {
  return StoreOnboardingService(
    auth: ref.watch(staffAuthServiceProvider),
    listingFactory: () => ListingRpc(AppSupabase.client),
  );
});
