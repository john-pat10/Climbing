// EXPO_PUBLIC_* values are inlined at build time, so they must be read with
// static `process.env.NAME` expressions (no destructuring or dynamic keys).
export const SUPABASE_URL = process.env.EXPO_PUBLIC_SUPABASE_URL ?? '';
export const SUPABASE_PUBLISHABLE_KEY = process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? '';

export function missingEnv(): string[] {
  const missing: string[] = [];
  if (!SUPABASE_URL) missing.push('EXPO_PUBLIC_SUPABASE_URL');
  if (!SUPABASE_PUBLISHABLE_KEY) missing.push('EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY');
  return missing;
}
