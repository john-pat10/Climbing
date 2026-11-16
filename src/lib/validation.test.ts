import { describe, expect, it } from '@jest/globals';
import {
  friendlyAuthError,
  normalizeUsername,
  validateEmail,
  validatePassword,
  validateUsername,
} from './validation';

describe('validateUsername', () => {
  it('accepts lowercase letters, numbers, underscores (3-24 chars)', () => {
    expect(validateUsername('crimp_queen')).toBeNull();
    expect(validateUsername('abc')).toBeNull();
    expect(validateUsername('a'.repeat(24))).toBeNull();
  });
  it('normalizes case and whitespace before validating', () => {
    expect(normalizeUsername('  Alex_99 ')).toBe('alex_99');
    expect(validateUsername('  Alex_99 ')).toBeNull();
  });
  it('rejects too short, too long, and bad characters', () => {
    expect(validateUsername('ab')).toMatch(/at least 3/);
    expect(validateUsername('a'.repeat(25))).toMatch(/24/);
    expect(validateUsername('no spaces')).toMatch(/letters, numbers/);
    expect(validateUsername('dash-name')).toMatch(/letters, numbers/);
  });
});

describe('validateEmail', () => {
  it('accepts normal addresses', () => {
    expect(validateEmail('a@b.co')).toBeNull();
    expect(validateEmail('  climber@example.com ')).toBeNull();
  });
  it('rejects empty and malformed input', () => {
    expect(validateEmail('')).toMatch(/Enter/);
    expect(validateEmail('climber@')).not.toBeNull();
    expect(validateEmail('climber.example.com')).not.toBeNull();
  });
});

describe('validatePassword', () => {
  it('requires at least 6 characters', () => {
    expect(validatePassword('12345')).not.toBeNull();
    expect(validatePassword('123456')).toBeNull();
  });
});

describe('friendlyAuthError', () => {
  it('maps common Supabase errors', () => {
    expect(friendlyAuthError('Invalid login credentials')).toBe('Wrong email or password.');
    expect(friendlyAuthError('Email not confirmed')).toMatch(/Confirm your email/);
    expect(friendlyAuthError('User already registered')).toMatch(/already exists/);
    expect(friendlyAuthError('Database error saving new user')).toMatch(/username/);
    expect(friendlyAuthError('TypeError: Network request failed')).toMatch(/reach the server/);
  });
  it('passes through unknown messages', () => {
    expect(friendlyAuthError('Something odd')).toBe('Something odd');
  });
});
