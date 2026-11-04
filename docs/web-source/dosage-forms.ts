export const DOSAGE_FORM_VALUES = [
  "tablet",
  "capsule",
  "syrup",
  "injection",
  "cream",
  "ointment",
  "drops",
  "inhaler",
  "powder",
  "suspension",
  "gel",
  "spray",
] as const;

export type DosageFormValue = (typeof DOSAGE_FORM_VALUES)[number];

export const DOSAGE_FORM_OPTIONS: { value: "" | DosageFormValue; label: string }[] = [
  { value: "", label: "Not specified" },
  { value: "tablet", label: "Tablet" },
  { value: "capsule", label: "Capsule" },
  { value: "syrup", label: "Syrup" },
  { value: "injection", label: "Injection" },
  { value: "cream", label: "Cream" },
  { value: "ointment", label: "Ointment" },
  { value: "drops", label: "Drops" },
  { value: "inhaler", label: "Inhaler" },
  { value: "powder", label: "Powder" },
  { value: "suspension", label: "Suspension" },
  { value: "gel", label: "Gel" },
  { value: "spray", label: "Spray" },
];

export function getDosageFormLabel(value: string | null | undefined): string {
  if (!value) return "Not specified";
  return DOSAGE_FORM_OPTIONS.find((option) => option.value === value)?.label ?? value;
}
