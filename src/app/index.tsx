import { Redirect } from 'expo-router';
import { useAuth } from '@/lib/auth';

// The app opens at "/": send people to their logbook or to log in.
export default function Index() {
  const { session } = useAuth();
  return <Redirect href={session ? '/history' : '/sign-in'} />;
}
