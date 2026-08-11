import { NitroModules } from 'react-native-nitro-modules';
import type { TtsFactory } from './specs/TtsFactory.nitro';

// Lazily resolve; module-scope createHybridObject would throw and kill the
// whole bundle if the native side failed to register.
let cachedTts: TtsFactory | null | undefined;

export function getTts(): TtsFactory | null {
  if (cachedTts === undefined) {
    try {
      cachedTts = NitroModules.createHybridObject<TtsFactory>('TtsFactory');
    } catch {
      cachedTts = null;
    }
  }
  return cachedTts;
}

export type { TtsFactory } from './specs/TtsFactory.nitro';
export type { TtsSession } from './specs/TtsSession.nitro';
export type { ListenerSubscription } from './types/ListenerSubscription';
export type { TtsEngine } from './types/TtsEngine';
export type { TtsMetadata } from './types/TtsMetadata';
export type { TtsParagraph } from './types/TtsParagraph';
export type { TtsPlaybackState } from './types/TtsPlaybackState';
export type { TtsProgress } from './types/TtsProgress';
export type { TtsSettings } from './types/TtsSettings';
export type { TtsVoice } from './types/TtsVoice';
