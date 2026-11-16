import './installLocalStorage';
import { createClient } from '@supabase/supabase-js';
import { AppState, Platform } from 'react-native';
import { SUPABASE_PUBLISHABLE_KEY, SUPABASE_URL, missingEnv } from './env';

// Placeholder values keep the app from crashing when .env is missing;
// the root layout shows a setup message instead (see missingEnv()).
export const supabase = createClient(
  SUPABASE_URL || 'https://missing-env.invalid',
  SUPABASE_PUBLISHABLE_KEY || 'missing-env',
  {
    auth: {
      storage: localStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  },
);

// Only refresh tokens while the app is in the foreground (Supabase's recommendation).
if (Platform.OS !== 'web' && missingEnv().length === 0) {
  AppState.addEventListener('change', (state) => {
    if (state === 'active') supabase.auth.startAutoRefresh();
    else supabase.auth.stopAutoRefresh();
  });
}
