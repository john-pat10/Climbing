import { StyleSheet, Text, View } from 'react-native';

// Placeholder home screen. Replaced by the auth gate and tabs in step 1.
export default function Home() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Climb Log</Text>
      <Text style={styles.subtitle}>Scaffold is running.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' },
  title: { fontSize: 28, fontWeight: '700' },
  subtitle: { marginTop: 8, color: '#555' },
});
