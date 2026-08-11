import { NitroModules } from 'react-native-nitro-modules'
import type { Epub } from './specs/Epub.nitro'

// Creating the hybrid object at module scope would throw if the native
// C++ side failed to register (e.g. on a platform where the pod was not
// linked). Lazily resolve it and fall back to a stub so app startup never
// depends on this optional capability.
let cachedEpub: Epub | null | undefined

export function getEpub(): Epub | null {
  if (cachedEpub === undefined) {
    try {
      cachedEpub = NitroModules.createHybridObject<Epub>('Epub')
    } catch {
      cachedEpub = null
    }
  }
  return cachedEpub
}

export const epub = getEpub()

export type { Epub } from './specs/Epub.nitro'
export type { EpubChapter } from './types/EpubChapter'
export type { EpubExportChapter } from './types/EpubExportChapter'
export type { EpubExportMetadata } from './types/EpubExportMetadata'
export type { EpubExportResult } from './types/EpubExportResult'
export type { EpubNovel } from './types/EpubNovel'
