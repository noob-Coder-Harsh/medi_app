import type { DosageFormValue } from "@/lib/constants/dosage-forms";
import type { SalePolicy } from "@/lib/packaging/constants";

export const PRODUCT_KIND_VALUES = [
  "tablet_capsule",
  "liquid",
  "topical",
  "injectable",
  "device",
  "surgical",
  "fmcg",
] as const;

export type ProductKind = (typeof PRODUCT_KIND_VALUES)[number];

export const DRUG_SCHEDULE_VALUES = ["none", "otc", "h", "h1", "x", "c"] as const;

export type DrugSchedule = (typeof DRUG_SCHEDULE_VALUES)[number];

export const STORAGE_VALUES = ["ambient", "refrigerated"] as const;

export type ProductStorage = (typeof STORAGE_VALUES)[number];

const KIND_FROM_DOSAGE: Partial<Record<DosageFormValue, ProductKind>> = {
  tablet: "tablet_capsule",
  capsule: "tablet_capsule",
  syrup: "liquid",
  drops: "liquid",
  suspension: "liquid",
  spray: "liquid",
  cream: "topical",
  ointment: "topical",
  gel: "topical",
  injection: "injectable",
  inhaler: "device",
  powder: "fmcg",
};

export function inferProductKind(dosageForm: string | null | undefined): ProductKind {
  if (!dosageForm) return "tablet_capsule";
  return KIND_FROM_DOSAGE[dosageForm as DosageFormValue] ?? "tablet_capsule";
}

export function defaultTrackBatch(kind: ProductKind): boolean {
  return kind !== "device" && kind !== "fmcg";
}

export function defaultSalePolicyForKind(kind: ProductKind): Exclude<SalePolicy, "inherit"> {
  if (kind === "tablet_capsule") return "loose_allowed";
  if (kind === "surgical") return "pack_only";
  return "whole_only";
}

export function isPrescriptionRequired(schedule: string | null | undefined): boolean {
  return schedule === "h" || schedule === "h1" || schedule === "x" || schedule === "c";
}

export function scheduleFromRxFlag(requiresPrescription: boolean | undefined): DrugSchedule {
  return requiresPrescription ? "h" : "otc";
}
