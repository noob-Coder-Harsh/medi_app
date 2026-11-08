import '../../../core/packaging.dart';
import '../../../data/models/pos_checkout.dart';

class PosSettlement {
  const PosSettlement({
    required this.discountType,
    required this.discountValue,
    required this.paidAmount,
    required this.dueAmount,
    required this.billTotal,
    required this.grandTotal,
  });

  final String discountType;
  final double discountValue;
  final double paidAmount;
  final double dueAmount;
  final double billTotal;
  final double grandTotal;
}

/// Cash/UPI/card/mixed: underpayment becomes fixed discount.
/// Credit: unpaid remainder is customer due.
PosSettlement derivePosSettlement({
  required double subtotal,
  required double receivedAmount,
  required PosPaymentMethod paymentMethod,
}) {
  final bill = roundMoney(subtotal < 0 ? 0 : subtotal);
  final received = roundMoney(receivedAmount.isFinite && receivedAmount > 0
      ? receivedAmount
      : 0);

  if (paymentMethod == PosPaymentMethod.credit) {
    final paid = roundMoney(received > bill ? bill : received);
    return PosSettlement(
      discountType: 'none',
      discountValue: 0,
      paidAmount: paid,
      dueAmount: roundMoney(bill - paid),
      billTotal: bill,
      grandTotal: bill,
    );
  }

  final paid = roundMoney(received > bill ? bill : received);
  final discountAmount = roundMoney(bill - paid);
  return PosSettlement(
    discountType: discountAmount > 0 ? 'fixed' : 'none',
    discountValue: discountAmount,
    paidAmount: paid,
    dueAmount: 0,
    billTotal: bill,
    grandTotal: paid,
  );
}

bool isValidPosPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  var mobile = digits;
  if (mobile.startsWith('91') && mobile.length >= 12) {
    mobile = mobile.substring(2);
  } else if (mobile.startsWith('0') && mobile.length == 11) {
    mobile = mobile.substring(1);
  }
  mobile = mobile.length > 10 ? mobile.substring(mobile.length - 10) : mobile;
  return mobile.length == 10 && RegExp(r'^[6-9]').hasMatch(mobile);
}

String normalizePosPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return '+91$digits';
  if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
  if (digits.length == 11 && digits.startsWith('0')) {
    return '+91${digits.substring(1)}';
  }
  if (raw.trim().startsWith('+') && digits.length >= 10) return '+$digits';
  return '+91$digits';
}

String posPhoneDigits(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('91')) digits = digits.substring(2);
  if (digits.startsWith('0') && digits.length == 11) {
    digits = digits.substring(1);
  }
  if (digits.length > 10) digits = digits.substring(digits.length - 10);
  return digits;
}
