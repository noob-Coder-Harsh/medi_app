import 'package:flutter/material.dart';

import '../../../core/brand.dart';

/// Default circular staff avatar until a user photo is available.
class StaffDefaultAvatar extends StatelessWidget {
  const StaffDefaultAvatar({super.key, this.radius = 28});

  static const String assetPath = 'assets/images/default_staff_avatar.png';

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Brand.themeColor.withValues(alpha: 0.12),
      backgroundImage: const AssetImage(assetPath),
    );
  }
}
