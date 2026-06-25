import type { TherapyDefaults } from '../api/doctorApi';

export interface TherapyLimitValues {
  maxSpeed: string;
  maxExtension: string;
  maxFlexion: string;
}

const FIELD_LABELS = {
  maxSpeed: 'Max speed',
  maxExtensionAngleDeg: 'Max extension',
  maxFlexionAngleDeg: 'Max flexion',
} as const;

/**
 * Validates the doctor-tunable safety limits against the backend-defined ranges.
 * Returns the first user-friendly error message, or null when all three are
 * present and in range. Mirrors the backend Bean Validation so the doctor gets
 * immediate feedback; the backend remains the authoritative validator.
 */
export function validateTherapyLimits(
  values: TherapyLimitValues,
  defaults: TherapyDefaults
): string | null {
  const checks: Array<[string, keyof typeof FIELD_LABELS]> = [
    [values.maxSpeed, 'maxSpeed'],
    [values.maxExtension, 'maxExtensionAngleDeg'],
    [values.maxFlexion, 'maxFlexionAngleDeg'],
  ];

  for (const [raw, key] of checks) {
    const label = FIELD_LABELS[key];
    const range = defaults[key];
    if (raw === undefined || raw === null || raw.trim() === '') {
      return `${label} is required.`;
    }
    const value = Number(raw);
    if (Number.isNaN(value)) {
      return `${label} must be a number.`;
    }
    if (value < range.min || value > range.max) {
      return `${label} must be between ${range.min} and ${range.max}.`;
    }
  }
  return null;
}
