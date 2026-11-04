import 'package:flutter/material.dart';

import 'otp_sheet.dart';

/// Guest Sign in CTA. Opens OTP sheet (Firebase wired in Step 15).
Future<void> showSignInStub(BuildContext context) async {
  await showOtpSheet(context);
}
