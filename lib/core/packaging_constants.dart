// Packaging enums + dosage → pack defaults — port of web `lib/packaging/`.

class PackagingDefaults {
  const PackagingDefaults({
    required this.baseUnit,
    required this.primaryPackType,
    required this.primaryPackQuantity,
    required this.packQuantityEditable,
    required this.allowedPackTypes,
  });

  final String baseUnit;
  final String primaryPackType;
  final int primaryPackQuantity;
  final bool packQuantityEditable;
  final List<String> allowedPackTypes;
}

/// Smallest sellable unit — inventory is always counted in these.
const List<String> kBaseUnitValues = <String>[
  'tablet',
  'capsule',
  'piece',
  'bottle',
  'vial',
  'tube',
  'inhaler',
];

/// Legacy inventory units still present on older rows; not offered in the form.
const List<String> kLegacyBaseUnitValues = <String>['ml', 'gram', 'dose'];

const List<String> kPrimaryPackTypeValues = <String>[
  'strip',
  'bottle',
  'tube',
  'vial',
  'blister',
  'sachet',
  'pen',
  'inhaler',
  'jar',
  'box',
];

const Map<String, String> kBaseUnitLabels = <String, String>{
  'tablet': 'Tablet',
  'capsule': 'Capsule',
  'piece': 'Piece',
  'bottle': 'Bottle',
  'vial': 'Vial',
  'tube': 'Tube',
  'inhaler': 'Inhaler',
  'ml': 'ml',
  'gram': 'Gram',
  'dose': 'Dose',
};

const Map<String, String> kPrimaryPackTypeLabels = <String, String>{
  'strip': 'Strip',
  'bottle': 'Bottle',
  'tube': 'Tube',
  'vial': 'Vial',
  'blister': 'Blister',
  'sachet': 'Sachet',
  'pen': 'Pen',
  'inhaler': 'Inhaler',
  'jar': 'Jar',
  'box': 'Box',
};

/// Dosage → sellable unit + allowed pack types.
/// Inventory is always the sellable unit (never gm/ml/doses).
const Map<String, PackagingDefaults> kDosageFormPackagingMap =
    <String, PackagingDefaults>{
  'tablet': PackagingDefaults(
    baseUnit: 'tablet',
    primaryPackType: 'strip',
    primaryPackQuantity: 10,
    packQuantityEditable: true,
    allowedPackTypes: <String>['strip', 'blister', 'bottle', 'box'],
  ),
  'capsule': PackagingDefaults(
    baseUnit: 'capsule',
    primaryPackType: 'strip',
    primaryPackQuantity: 10,
    packQuantityEditable: true,
    allowedPackTypes: <String>['strip', 'blister', 'bottle', 'box'],
  ),
  'syrup': PackagingDefaults(
    baseUnit: 'bottle',
    primaryPackType: 'bottle',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['bottle'],
  ),
  'injection': PackagingDefaults(
    baseUnit: 'vial',
    primaryPackType: 'vial',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['vial'],
  ),
  'cream': PackagingDefaults(
    baseUnit: 'tube',
    primaryPackType: 'tube',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['tube'],
  ),
  'ointment': PackagingDefaults(
    baseUnit: 'tube',
    primaryPackType: 'tube',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['tube'],
  ),
  'drops': PackagingDefaults(
    baseUnit: 'bottle',
    primaryPackType: 'bottle',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['bottle'],
  ),
  'inhaler': PackagingDefaults(
    baseUnit: 'inhaler',
    primaryPackType: 'inhaler',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['inhaler'],
  ),
  'powder': PackagingDefaults(
    baseUnit: 'piece',
    primaryPackType: 'box',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['box', 'sachet', 'bottle'],
  ),
  'suspension': PackagingDefaults(
    baseUnit: 'bottle',
    primaryPackType: 'bottle',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['bottle'],
  ),
  'gel': PackagingDefaults(
    baseUnit: 'tube',
    primaryPackType: 'tube',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['tube'],
  ),
  'spray': PackagingDefaults(
    baseUnit: 'bottle',
    primaryPackType: 'bottle',
    primaryPackQuantity: 1,
    packQuantityEditable: false,
    allowedPackTypes: <String>['bottle'],
  ),
};

const PackagingDefaults kFallbackPackagingDefaults = PackagingDefaults(
  baseUnit: 'piece',
  primaryPackType: 'box',
  primaryPackQuantity: 1,
  packQuantityEditable: false,
  allowedPackTypes: <String>['box', 'sachet', 'bottle'],
);

PackagingDefaults getPackagingDefaultsForDosageForm(String? dosageForm) {
  if (dosageForm == null || dosageForm.isEmpty) {
    return kFallbackPackagingDefaults;
  }
  return kDosageFormPackagingMap[dosageForm] ?? kFallbackPackagingDefaults;
}

List<String> getAllowedPackTypesForDosageForm(String? dosageForm) {
  return getPackagingDefaultsForDosageForm(dosageForm).allowedPackTypes;
}

bool isPackQuantityEditable(String? dosageForm, [String? baseUnit]) {
  final defaults = getPackagingDefaultsForDosageForm(dosageForm);
  if (baseUnit == 'tablet' || baseUnit == 'capsule' || baseUnit == 'piece') {
    return true;
  }
  return defaults.packQuantityEditable;
}
