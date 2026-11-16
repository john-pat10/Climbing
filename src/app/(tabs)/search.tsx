import { StyleSheet, Text, View } from 'react-native';
import { colors } from '@/components/ui';

// Placeholder: crag/route search arrives in step 2.
export default function Search() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>Crag and route search is coming in the next step.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, backgroundColor: colors.bg },
  text: { color: colors.muted },
});
