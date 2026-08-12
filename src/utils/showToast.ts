import { Alert, Platform, ToastAndroid } from 'react-native';

/**
 * Lightweight feedback.
 * - Android: native toast.
 * - iOS: ToastAndroid is a no-op and there is no built-in toast, so use
 *   Alert.alert — without visible feedback every operation looked dead
 *   (downloads, exports, imports silently "did nothing").
 */
export const showToast = (...message: string[]) => {
  const text = message.join(' ');
  if (Platform.OS === 'android') {
    ToastAndroid.show(text, ToastAndroid.SHORT);
    return;
  }
  Alert.alert(text);
};

/** Error feedback that must be visible on every platform. */
export const showErrorToast = (...message: string[]) => {
  const text = message.join(' ');
  if (Platform.OS === 'android') {
    ToastAndroid.show(text, ToastAndroid.LONG);
    return;
  }
  Alert.alert('Error', text);
};
