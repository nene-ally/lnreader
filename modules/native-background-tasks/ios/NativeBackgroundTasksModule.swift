import ExpoModulesCore

// ponytail: iOS stub — all methods reject with NOT_IMPLEMENTED.
// Background tasks are Android-only; iOS callers should guard with Platform.OS.
public class NativeBackgroundTasksModule: Module {
  public func definition() -> ModuleDefinition {
    Name("NativeBackgroundTasks")

    AsyncFunction("enqueue") { (type: String, payload: String, title: String, description: String, allowsDuplicates: Bool, queueName: String) -> String in
      // Fake id: the TS layer runs the task in the foreground on iOS
      // (see BackgroundTaskQueue). Returning an id keeps queue bookkeeping
      // consistent without a real scheduler.
      return "ios-\(Int(Date().timeIntervalSince1970 * 1000))"
    }

    AsyncFunction("getTasks") { () -> [[String: Any]] in
      return []
    }

    AsyncFunction("pause") { (taskId: String) in }
    AsyncFunction("resume") { (taskId: String) in }
    AsyncFunction("cancel") { (taskId: String) in }
    AsyncFunction("updateProgress") { (taskId: String, progress: Double, progressText: String) in }
    AsyncFunction("updateCheckpoint") { (taskId: String, checkpoint: String) in }
    AsyncFunction("complete") { (taskId: String, completionText: String) in }
    AsyncFunction("fail") { (taskId: String, error: String, shouldRetry: Bool) in }

    AsyncFunction("scheduleLibraryUpdates") { (intervalHours: Double, title: String, description: String) in
      throw NSError(domain: "NativeBackgroundTasks", code: 1, userInfo: [NSLocalizedDescriptionKey: "Scheduled library updates not available on iOS"])
    }

    AsyncFunction("cancelLibraryUpdates") { }

    AsyncFunction("scheduleAutomaticBackups") { (intervalHours: Double, title: String, description: String, directoryUri: String) in
      throw NSError(domain: "NativeBackgroundTasks", code: 1, userInfo: [NSLocalizedDescriptionKey: "Scheduled automatic backups not available on iOS"])
    }

    AsyncFunction("cancelAutomaticBackups") { }
  }
}