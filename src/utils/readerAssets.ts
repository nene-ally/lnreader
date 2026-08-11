import { NativeModules, Platform } from 'react-native';

// Shared helper: resolves where in-app reader assets (css/js/fonts) live on
// the current platform.
//   - dev          → Metro serves them from localhost:8081/assets
//   - Android      → packaged into the APK's assets (file:///android_asset)
//   - iOS          → copied into the .app bundle under assets/reader
//                    (file://<bundle path>/assets/reader)
export const getAssetsUriPrefix = (): string => {
  if (__DEV__) {
    return 'http://localhost:8081/assets';
  }
  if (Platform.OS === 'android') {
    return 'file:///android_asset';
  }
  // iOS: derive the .app bundle path from the JS bundle location.
  // NativeModules.SourceCode.scriptURL looks like
  // file:///.../LNReader.app/main.jsbundle → strip the filename.
  const scriptURL =
    NativeModules.SourceCode?.scriptURL ||
    NativeModules.RCTSourceCode?.scriptURL ||
    '';
  if (scriptURL.startsWith('file://')) {
    const bundleDir = scriptURL.replace(/[^/]*$/, '');
    return `file://${bundleDir}assets/reader`;
  }
  // Fallback: standard iOS simulator/device bundle path. Note: a broken
  // scriptURL here means reader css/fonts will 404 — check the value above.
  return 'file:///';
};
