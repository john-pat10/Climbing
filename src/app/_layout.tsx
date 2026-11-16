import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { colors } from '@/components/ui';
import { AuthProvider, useAuth } from '@/lib/auth';
import { missingEnv } from '@/lib/env';

export default function RootLayout() {
  const missing = missingEnv();
  if (missing.length > 0) return <SetupNeeded missing={missing} />;
  return (
    <AuthProvider>
      <RootNavigator />
      <StatusBar style="dark" />
    </AuthProvider>
  );
}

function RootNavigator() {
  const { session, loading } = useAuth();
  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.primary} />
      </View>
    );
  }
  const signedIn = session !== null;
  // Protected groups: signed-out users only see (auth); signed-in users only see (tabs).
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="index" />
      <Stack.Protected guard={signedIn}>
        <Stack.Screen name="(tabs)" />
      </Stack.Protected>
      <Stack.Protected guard={!signedIn}>
        <Stack.Screen name="(auth)" />
      </Stack.Protected>
    </Stack>
  );
}

function SetupNeeded({ missing }: { missing: string[] }) {
  return (
    <View style={styles.center}>
      <Text style={styles.title}>Setup needed</Text>
      <Text style={styles.body}>
        Copy .env.example to .env, fill in your Supabase values, then restart with{' '}
        <Text style={styles.code}>npx expo start --clear</Text>.
      </Text>
      <Text style={styles.body}>Missing: {missing.join(', ')}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24, backgroundColor: colors.bg },
  title: { fontSize: 22, fontWeight: '700', marginBottom: 12, color: colors.text },
  body: { fontSize: 15, color: colors.muted, textAlign: 'center', marginBottom: 8 },
  code: { fontFamily: 'Courier', color: colors.text },
});
