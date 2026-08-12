import { Alert, Platform, ToastAndroid } from 'react-native';

/**
 * Lightweight feedback. Android: native toast. iOS: ToastAndroid is a no-op,
 * so show a brief non-blocking banner via Alert only for error-style toasts
 * (marked with showErrorToast), and log everything else in dev.
 */
export const showToast = (...message: string[]) => {
  const text = message.join(' ');
  if (Platform.OS === 'android') {
    ToastAndroid.show(text, ToastAndroid.SHORT);
    return;
  }
  if (__DEV__) {
    // eslint-disable-next-line no-console
    console.log('Toast: ', text);
  }
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
