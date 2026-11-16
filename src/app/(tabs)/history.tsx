import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { Button, ErrorBanner, colors } from '@/components/ui';
import { useAuth } from '@/lib/auth';
import { supabase } from '@/lib/supabase';

// History tab. For step 1 it just proves auth + database access work
// (reads your profile through row-level security). Session list comes in step 4.
export default function History() {
  const { session } = useAuth();
  const [username, setUsername] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!session) return;
    supabase
      .from('profiles')
      .select('username')
      .eq('id', session.user.id)
      .single()
      .then(({ data, error }) => {
        if (error) setError(`Couldn’t load your profile: ${error.message}`);
        else setUsername(data.username);
      });
  }, [session]);

  return (
    <View style={styles.container}>
      <ErrorBanner>{error}</ErrorBanner>
      <Text style={styles.hello}>{username ? `Signed in as @${username}` : 'Loading your profile…'}</Text>
      <Text style={styles.muted}>{session?.user.email}</Text>
      <Text style={styles.placeholder}>Your session history will appear here.</Text>
      <Button title="Sign out" variant="secondary" onPress={() => supabase.auth.signOut()} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, backgroundColor: colors.bg },
  hello: { fontSize: 20, fontWeight: '700', color: colors.text },
  muted: { color: colors.muted, marginTop: 4 },
  placeholder: { color: colors.muted, marginTop: 32, marginBottom: 16 },
});
