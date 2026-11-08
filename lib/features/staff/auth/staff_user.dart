/// Owner row from `store_users`. Read (and self-ensure) under RLS.
class StaffUser {
  const StaffUser({
    required this.id,
    required this.authUserId,
    this.storeId,
    this.email,
    this.fullName,
    this.phone,
    this.role = 'owner',
    this.isActive = true,
  });

  final String id;
  final String authUserId;
  final String? storeId;
  final String? email;
  final String? fullName;
  final String? phone;
  final String role;
  final bool isActive;

  bool get hasStore => storeId != null && storeId!.isNotEmpty;

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: '${json['id'] ?? ''}',
      authUserId: '${json['auth_user_id'] ?? ''}',
      storeId: _nullableString(json['store_id']),
      email: _nullableString(json['email']),
      fullName: _nullableString(json['full_name']),
      phone: _nullableString(json['phone']),
      role: _nullableString(json['role']) ?? 'owner',
      isActive: json['is_active'] != false,
    );
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }
}
