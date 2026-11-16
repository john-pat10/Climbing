import { router } from 'expo-router';
import { useState } from 'react';
import { AuthScreen } from '@/components/AuthScreen';
import { Button, ErrorBanner, Field } from '@/components/ui';
import { supabase } from '@/lib/supabase';
import {
  friendlyAuthError,
  normalizeUsername,
  validateEmail,
  validatePassword,
  validateUsername,
} from '@/lib/validation';

type Errors = { username?: string | null; email?: string | null; password?: string | null };

export default function SignUp() {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<Errors>({});
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit() {
    const fieldErrors: Errors = {
      username: validateUsername(username),
      email: validateEmail(email),
      password: validatePassword(password),
    };
    setErrors(fieldErrors);
    setError(null);
    if (fieldErrors.username || fieldErrors.email || fieldErrors.password) return;

    setBusy(true);
    const name = normalizeUsername(username);
    const { data: available, error: checkError } = await supabase.rpc('username_available', { name });
    if (checkError) {
      setBusy(false);
      setError(friendlyAuthError(checkError.message));
      return;
    }
    if (!available) {
      setBusy(false);
      setErrors({ username: 'That username is taken.' });
      return;
    }

    // The database trigger creates the profile row from this `username` metadata.
    const { data, error } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: { data: { username: name } },
    });
    setBusy(false);
    if (error) {
      setError(friendlyAuthError(error.message));
      return;
    }
    if (!data.session) {
      // Email confirmation is turned on in Supabase.
      setNotice('Account created. Check your email to confirm it, then log in.');
    }
    // If there is a session, the root layout switches to the app automatically.
  }

  if (notice) {
    return (
      <AuthScreen title="Check your email" subtitle={notice}>
        <Button title="Go to log in" onPress={() => router.replace('/sign-in')} />
      </AuthScreen>
    );
  }

  return (
    <AuthScreen title="Create account" subtitle="Start your climbing logbook.">
      <ErrorBanner>{error}</ErrorBanner>
      <Field
        label="Username"
        value={username}
        onChangeText={setUsername}
        error={errors.username}
        autoCapitalize="none"
        autoCorrect={false}
        autoComplete="username-new"
        placeholder="e.g. crimp_queen"
      />
      <Field
        label="Email"
        value={email}
        onChangeText={setEmail}
        error={errors.email}
        autoCapitalize="none"
        autoComplete="email"
        keyboardType="email-address"
        textContentType="emailAddress"
        placeholder="you@example.com"
      />
      <Field
        label="Password"
        value={password}
        onChangeText={setPassword}
        error={errors.password}
        secureTextEntry
        autoComplete="new-password"
        textContentType="newPassword"
        placeholder="At least 6 characters"
        onSubmitEditing={onSubmit}
      />
      <Button title="Create account" onPress={onSubmit} busy={busy} />
      <Button title="Already have an account? Log in" variant="secondary" onPress={() => router.replace('/sign-in')} />
    </AuthScreen>
  );
}
