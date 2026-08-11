import { requireOptionalNativeModule } from 'expo-modules-core';
import type { NativeBackgroundTaskRecord } from './src/NativeBackgroundTasksModule';

/**
 * Background tasks are Android-only. On iOS (and web) the native module does
 * not exist; requireOptionalNativeModule returns null instead of throwing.
 * The proxy below returns harmless no-ops for every method so callers on
 * unsupported platforms never crash — tasks simply never run there.
 */
export type { NativeBackgroundTaskRecord };

type NativeBackgroundTasksModuleType = {
  enqueue(
    type: string,
    payload: string,
    title: string,
    description: string,
    allowsDuplicates: boolean,
    queueName: string,
  ): Promise<string>;
  getTasks(): Promise<NativeBackgroundTaskRecord[]>;
  pause(taskId: string): Promise<void>;
  resume(taskId: string): Promise<void>;
  cancel(taskId: string): Promise<void>;
  updateProgress(taskId: string, progress: number, progressText: string): Promise<void>;
  updateCheckpoint(taskId: string, checkpoint: string): Promise<void>;
  complete(taskId: string, completionText: string): Promise<void>;
  fail(taskId: string, error: string, shouldRetry: boolean): Promise<void>;
  scheduleLibraryUpdates(intervalHours: number, title: string, description: string): Promise<void>;
  cancelLibraryUpdates(): Promise<void>;
  scheduleAutomaticBackups(
    intervalHours: number,
    title: string,
    description: string,
    directoryUri: string,
  ): Promise<void>;
  cancelAutomaticBackups(): Promise<void>;
};

const nativeModule =
  requireOptionalNativeModule<NativeBackgroundTasksModuleType>('NativeBackgroundTasks');

const makeNoop = (method: keyof NativeBackgroundTasksModuleType) => {
  switch (method) {
    case 'getTasks':
      return async () => [] as NativeBackgroundTaskRecord[];
    case 'enqueue':
      // Unique fake id keeps queue bookkeeping consistent.
      return async () => `ios-noop-${Date.now()}`;
    default:
      return async () => undefined;
  }
};

/** Null-safe wrapper: real module when present, silent no-ops otherwise. */
const NativeBackgroundTasks: NativeBackgroundTasksModuleType = new Proxy(
  {} as NativeBackgroundTasksModuleType,
  {
    get(_target, prop: keyof NativeBackgroundTasksModuleType) {
      const real = nativeModule?.[prop];
      return real ? real.bind(nativeModule) : makeNoop(prop);
    },
  },
);

export default NativeBackgroundTasks;
