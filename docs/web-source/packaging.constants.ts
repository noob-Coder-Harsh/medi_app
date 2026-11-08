/** Smallest sellable unit — inventory is always counted in these. gm/ml/doses are label content only. */
export const BASE_UNIT_VALUES = [
  "tablet",
  "capsule",
  "piece",
  "bottle",
  "vial",
  "tube",
  "inhaler",
] as const;

export type BaseUnit = (typeof BASE_UNIT_VALUES)[number];

/** Legacy inventory units still present on older rows; not offered in the catalog form. */
export const LEGACY_BASE_UNIT_VALUES = ["ml", "gram", "dose"] as const;

export type LegacyBaseUnit = (typeof LEGACY_BASE_UNIT_VALUES)[number];

/** How the medicine is packed for retail (metadata only). */
export const PRIMARY_PACK_TYPE_VALUES = [
  "strip",
  "bottle",
  "tube",
  "vial",
  "blister",
  "sachet",
  "pen",
  "inhaler",
  "jar",
  "box",
] as const;

export type PrimaryPackType = (typeof PRIMARY_PACK_TYPE_VALUES)[number];

export const SECONDARY_PACK_TYPE_VALUES = ["box", "carton", "case"] as const;

export type SecondaryPackType = (typeof SECONDARY_PACK_TYPE_VALUES)[number];

/** Store-level rule for how customers can buy. Does not affect inventory. */
export const SALE_POLICY_VALUES = [
  "inherit",
  "loose_allowed",
  "pack_only",
  "whole_only",
] as const;

/** Store-level policy cannot inherit. SKU rows may. */

export type SalePolicy = (typeof SALE_POLICY_VALUES)[number];

export const DEFAULT_SALE_POLICY: SalePolicy = "loose_allowed";

export const BASE_UNIT_OPTIONS: { value: BaseUnit; label: string }[] = [
  { value: "tablet", label: "Tablet" },
  { value: "capsule", label: "Capsule" },
  { value: "piece", label: "Piece" },
  { value: "bottle", label: "Bottle" },
  { value: "vial", label: "Vial" },
  { value: "tube", label: "Tube" },
  { value: "inhaler", label: "Inhaler" },
];

export const PRIMARY_PACK_TYPE_OPTIONS: { value: PrimaryPackType; label: string }[] = [
  { value: "strip", label: "Strip" },
  { value: "bottle", label: "Bottle" },
  { value: "tube", label: "Tube" },
  { value: "vial", label: "Vial" },
  { value: "blister", label: "Blister" },
  { value: "sachet", label: "Sachet" },
  { value: "pen", label: "Pen" },
  { value: "inhaler", label: "Inhaler" },
  { value: "jar", label: "Jar" },
  { value: "box", label: "Box" },
];

export const SECONDARY_PACK_TYPE_OPTIONS: { value: "" | SecondaryPackType; label: string }[] = [
  { value: "", label: "None" },
  { value: "box", label: "Box" },
  { value: "carton", label: "Carton" },
  { value: "case", label: "Case" },
];

export const SALE_POLICY_OPTIONS: { value: SalePolicy; label: string; hint: string }[] = [
  {
    value: "loose_allowed",
    label: "Loose + pack",
    hint: "Customers can buy full packs or custom quantities (common for tablets).",
  },
  {
    value: "pack_only",
    label: "Pack only",
    hint: "Sell only in full primary packs (e.g. whole strips).",
  },
  {
    value: "whole_only",
    label: "Whole container only",
    hint: "Sell only complete bottles, tubes, vials, etc.",
  },
  {
    value: "inherit",
    label: "Smart (by medicine type)",
    hint: "Tablets/capsules allow loose; liquids and tubes sell as whole packs.",
  },
];
