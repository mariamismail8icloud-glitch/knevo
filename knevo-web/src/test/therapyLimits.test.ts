import { describe, it, expect } from 'vitest';
import { validateTherapyLimits } from '../utils/therapyLimits';
import type { TherapyDefaults } from '../api/doctorApi';

const defaults: TherapyDefaults = {
  maxSpeed: { defaultValue: 5, min: 1, max: 12 },
  maxExtensionAngleDeg: { defaultValue: 5, min: 1, max: 5 },
  maxFlexionAngleDeg: { defaultValue: 60, min: 30, max: 65 },
};

describe('validateTherapyLimits', () => {
  it('accepts in-range values', () => {
    expect(validateTherapyLimits({ maxSpeed: '5', maxExtension: '3', maxFlexion: '60' }, defaults)).toBeNull();
  });

  it('accepts the range boundaries', () => {
    expect(validateTherapyLimits({ maxSpeed: '1', maxExtension: '1', maxFlexion: '30' }, defaults)).toBeNull();
    expect(validateTherapyLimits({ maxSpeed: '12', maxExtension: '5', maxFlexion: '65' }, defaults)).toBeNull();
  });

  it('rejects a missing field', () => {
    expect(validateTherapyLimits({ maxSpeed: '', maxExtension: '5', maxFlexion: '60' }, defaults))
      .toMatch(/Max speed is required/);
  });

  it('rejects speed above max', () => {
    expect(validateTherapyLimits({ maxSpeed: '13', maxExtension: '5', maxFlexion: '60' }, defaults))
      .toMatch(/Max speed must be between 1 and 12/);
  });

  it('rejects extension above its max of 5', () => {
    expect(validateTherapyLimits({ maxSpeed: '5', maxExtension: '6', maxFlexion: '60' }, defaults))
      .toMatch(/Max extension must be between 1 and 5/);
  });

  it('rejects flexion below its min of 30', () => {
    expect(validateTherapyLimits({ maxSpeed: '5', maxExtension: '5', maxFlexion: '20' }, defaults))
      .toMatch(/Max flexion must be between 30 and 65/);
  });

  it('rejects a non-numeric value', () => {
    expect(validateTherapyLimits({ maxSpeed: 'abc', maxExtension: '5', maxFlexion: '60' }, defaults))
      .toMatch(/Max speed must be a number/);
  });
});
