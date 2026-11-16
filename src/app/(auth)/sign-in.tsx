import { router } from 'expo-router';
import { useState } from 'react';
import { AuthScreen } from '@/components/AuthScreen';
import { Button, ErrorBanner, Field } from '@/components/ui';
import { supabase } from '@/lib/supabase';
import { friendlyAuthError, validateEmail } from '@/lib/validation';

export default function SignIn() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit() {
    const emailError = validateEmail(email);
    if (emailError || !password) {
      setError(emailError ?? 'Enter your password.');
      return;
    }
    setBusy(true);
    setError(null);
    const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    setBusy(false);
    // On success the AuthProvider sees the new session and the root layout
    // switches to the signed-in screens automatically.
    if (error) setError(friendlyAuthError(error.message));
  }

  return (
    <AuthScreen title="Log in" subtitle="Welcome back. Your logbook is waiting.">
      <ErrorBanner>{error}</ErrorBanner>
      <Field
        label="Email"
        value={email}
        onChangeText={setEmail}
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
        secureTextEntry
        autoComplete="current-password"
        textContentType="password"
        onSubmitEditing={onSubmit}
      />
      <Button title="Log in" onPress={onSubmit} busy={busy} />
      <Button title="New here? Create an account" variant="secondary" onPress={() => router.replace('/sign-up')} />
    </AuthScreen>
  );
}
