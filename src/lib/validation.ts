// Mirrors the check constraint on profiles.username in 0001_init.sql.
export const USERNAME_PATTERN = /^[a-z0-9_]{3,24}$/;
export const MIN_PASSWORD_LENGTH = 6; // Supabase's default minimum

export function normalizeUsername(input: string): string {
  return input.trim().toLowerCase();
}

export function validateUsername(input: string): string | null {
  const name = normalizeUsername(input);
  if (name.length < 3) return 'Username must be at least 3 characters.';
  if (name.length > 24) return 'Username must be 24 characters or fewer.';
  if (!USERNAME_PATTERN.test(name)) return 'Use only letters, numbers and underscores.';
  return null;
}

export function validateEmail(input: string): string | null {
  const email = input.trim();
  if (!email) return 'Enter your email.';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return 'That doesn’t look like an email address.';
  return null;
}

export function validatePassword(input: string): string | null {
  if (input.length < MIN_PASSWORD_LENGTH) return `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`;
  return null;
}

// Turns Supabase auth errors into messages a climber can act on.
export function friendlyAuthError(message: string): string {
  const m = message.toLowerCase();
  if (m.includes('invalid login credentials')) return 'Wrong email or password.';
  if (m.includes('email not confirmed')) return 'Confirm your email first (check your inbox), then log in.';
  if (m.includes('already registered') || m.includes('already been registered')) return 'An account with that email already exists. Try logging in.';
  if (m.includes('database error saving new user')) return 'Could not create your profile. That username may have just been taken; try another.';
  if (m.includes('network request failed') || m.includes('failed to fetch')) return 'Can’t reach the server. Check your connection and your Supabase URL in .env.';
  if (m.includes('rate limit')) return 'Too many attempts. Wait a minute and try again.';
  return message;
}
