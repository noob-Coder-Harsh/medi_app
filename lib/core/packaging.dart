import 'packaging_constants.dart';

/// Pack math — port of web `lib/packaging/helpers.ts` (POS needs).
class PackagingInfo {
  const PackagingInfo({
    this.baseUnit,
    this.primaryPackType,
    this.primaryPackQuantity,
  });

  final String? baseUnit;
  final String? primaryPackType;
  final double? primaryPackQuantity;
}

class PackDisplay {
  const PackDisplay({
    required this.packs,
    required this.remainder,
    required this.packQuantity,
    required this.display,
  });

  final int packs;
  final int remainder;
  final int packQuantity;
  final String display;
}

int normalizePackQuantity(num? value) {
  if (value == null || !value.isFinite || value < 1) return 1;
  return value.floor();
}

bool hasRetailPack(PackagingInfo? packaging) {
  if (packaging == null) return false;
  final qty = packaging.primaryPackQuantity;
  if (qty != null && qty > 1) return true;
  final type = packaging.primaryPackType?.trim();
  return type != null && type.isNotEmpty;
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String getBaseUnitLabel(String? unit) {
  if (unit == null || unit.isEmpty) return 'unit';
  return kBaseUnitLabels[unit] ?? _titleCase(unit);
}

String getPrimaryPackTypeLabel(String? packType) {
  if (packType == null || packType.isEmpty) return 'Pack';
  return kPrimaryPackTypeLabels[packType] ?? _titleCase(packType);
}

bool _isWholeContainerPack(String? packType) {
  return packType == 'inhaler' ||
      packType == 'bottle' ||
      packType == 'tube' ||
      packType == 'vial' ||
      packType == 'pen' ||
      packType == 'jar';
}

bool _isWholeContainerUnit(String? baseUnit) {
  return baseUnit == 'bottle' ||
      baseUnit == 'vial' ||
      baseUnit == 'tube' ||
      baseUnit == 'inhaler' ||
      baseUnit == 'ml' ||
      baseUnit == 'gram' ||
      baseUnit == 'dose';
}

/// Human-readable pack label, e.g. "Strip of 10 Tablets", "Tube", "Inhaler".
String formatPackLabel(PackagingInfo? packaging) {
  if (packaging == null) return 'Unit';

  final packType = packaging.primaryPackType?.trim();
  final baseUnit = packaging.baseUnit?.trim();
  final qty = normalizePackQuantity(packaging.primaryPackQuantity);
  final packLabel = getPrimaryPackTypeLabel(packType);
  final unitLabel = getBaseUnitLabel(baseUnit);

  final hasPack = packType != null && packType.isNotEmpty;
  final hasUnit = baseUnit != null && baseUnit.isNotEmpty;
  if (!hasPack && !hasUnit) return 'Unit';

  if (qty == 1 ||
      _isWholeContainerUnit(baseUnit) ||
      _isWholeContainerPack(packType)) {
    if (hasPack && (!hasUnit || packType == baseUnit)) return packLabel;
    if (hasPack && hasUnit) return '$packLabel of 1 $unitLabel';
    return unitLabel;
  }

  if (baseUnit == 'ml' || baseUnit == 'gram') {
    final shortUnit = baseUnit == 'gram' ? 'g' : 'ml';
    return '$packLabel of $qty $shortUnit';
  }

  final plural = unitLabel.toLowerCase().endsWith('s') ||
          unitLabel.toLowerCase() == 'ml'
      ? unitLabel
      : '${unitLabel}s';
  return '$packLabel of $qty $plural';
}

double calculatePackPrice(num? unitPrice, PackagingInfo? packaging) {
  final price = (unitPrice ?? 0).toDouble();
  final qty = normalizePackQuantity(packaging?.primaryPackQuantity);
  return (price * qty * 100).round() / 100;
}

int convertPackToBaseQuantity(num packCount, PackagingInfo? packaging) {
  final packs = packCount.isFinite ? packCount.floor().clamp(0, 1 << 30) : 0;
  final perPack = normalizePackQuantity(packaging?.primaryPackQuantity);
  return packs * perPack;
}

bool canSellLoose(PackagingInfo? packaging) {
  final packType = packaging?.primaryPackType?.trim();
  if (packType == 'inhaler' ||
      packType == 'bottle' ||
      packType == 'tube' ||
      packType == 'vial' ||
      packType == 'pen' ||
      packType == 'jar') {
    return false;
  }
  final base = packaging?.baseUnit?.trim();
  return base == 'tablet' || base == 'capsule' || base == 'piece';
}

String resolveEffectiveSalePolicy(
  String? storePolicy,
  PackagingInfo? packaging,
) {
  final policy = storePolicy ?? 'loose_allowed';
  if (policy == 'pack_only' || policy == 'whole_only') return policy;
  return canSellLoose(packaging) ? 'loose_allowed' : 'whole_only';
}

/// Step size in base units for POS ±.
int getSaleStepQuantity(
  String? storePolicy,
  PackagingInfo? packaging, {
  bool preferPack = false,
}) {
  final effective = resolveEffectiveSalePolicy(storePolicy, packaging);
  final packQty = normalizePackQuantity(packaging?.primaryPackQuantity);
  if (effective == 'pack_only' || effective == 'whole_only') {
    return packQty < 1 ? 1 : packQty;
  }
  if (preferPack && hasRetailPack(packaging)) {
    return packQty < 1 ? 1 : packQty;
  }
  return 1;
}

/// POS card tap / + adds one retail pack when configured, else one base unit.
int getPosAddQuantity(PackagingInfo? packaging) {
  if (hasRetailPack(packaging)) {
    return convertPackToBaseQuantity(1, packaging);
  }
  return 1;
}

String formatPosPackMeta(PackagingInfo? packaging) {
  final qty = normalizePackQuantity(packaging?.primaryPackQuantity);
  final base = packaging?.baseUnit?.trim();
  if (base == 'ml' || base == 'gram') {
    final short = base == 'gram' ? 'g' : 'ml';
    return '$qty $short';
  }
  final unitLabel = getBaseUnitLabel(base);
  if (base == null || base.isEmpty) return unitLabel;
  if (qty == 1) return '1 $unitLabel';
  final plural = unitLabel.toLowerCase().endsWith('s') || unitLabel.toLowerCase() == 'ml'
      ? unitLabel
      : '${unitLabel}s';
  return '$qty $plural';
}

PackDisplay convertBaseToPackDisplay(
  num baseQuantity,
  PackagingInfo? packaging,
) {
  final qty = baseQuantity.isFinite ? baseQuantity.floor().clamp(0, 1 << 30) : 0;
  final packQuantity = normalizePackQuantity(packaging?.primaryPackQuantity);
  final unitLabel = getBaseUnitLabel(packaging?.baseUnit);
  final packLabel = getPrimaryPackTypeLabel(packaging?.primaryPackType);
  final packLabelPlural =
      packLabel.toLowerCase().endsWith('s') ? packLabel : '${packLabel}s';
  final unitPlural =
      unitLabel.toLowerCase().endsWith('s') || unitLabel.toLowerCase() == 'ml'
      ? unitLabel
      : '${unitLabel}s';

  if (!hasRetailPack(packaging) || packQuantity <= 1) {
    return PackDisplay(
      packs: 0,
      remainder: qty,
      packQuantity: 1,
      display: '$qty ${qty == 1 ? unitLabel : unitPlural}',
    );
  }

  final packs = qty ~/ packQuantity;
  final remainder = qty % packQuantity;

  final String display;
  if (packs > 0 && remainder == 0) {
    display =
        '$packs ${packs == 1 ? packLabel : packLabelPlural} ($qty $unitPlural)';
  } else if (packs > 0 && remainder > 0) {
    display =
        '$packs ${packs == 1 ? packLabel : packLabelPlural} + $remainder ${remainder == 1 ? unitLabel : unitPlural}';
  } else {
    display = '$qty ${qty == 1 ? unitLabel : unitPlural}';
  }

  return PackDisplay(
    packs: packs,
    remainder: remainder,
    packQuantity: packQuantity,
    display: display,
  );
}

double roundMoney(num value) {
  if (!value.isFinite) return 0;
  return (value.toDouble() * 100).round() / 100;
}

double lineAmount(num unitPrice, num quantity) {
  return roundMoney(unitPrice * quantity);
}

double cartSubtotal(Iterable<({double unitPrice, double quantity})> items) {
  var sum = 0.0;
  for (final item in items) {
    sum += lineAmount(item.unitPrice, item.quantity);
  }
  return roundMoney(sum);
}
