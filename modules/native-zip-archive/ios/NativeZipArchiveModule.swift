import ExpoModulesCore
import Foundation

public class NativeZipArchiveModule: Module {
  public func definition() -> ModuleDefinition {
    Name("NativeZipArchive")

    AsyncFunction("unzip") { (sourceFilePath: String, distDirPath: String, promise: Promise) in
      do {
        try FileManager.default.createDirectory(atPath: distDirPath, withIntermediateDirectories: true)
        var error: NSError?
        let ok = NativeZipArchiveHelper.unzipFile(atPath: sourceFilePath, toDirectory: distDirPath, error: &error)
        if ok {
          promise.resolve()
        } else {
          promise.reject("UNZIP_FAILED", error?.localizedDescription ?? "unzip failed")
        }
      } catch {
        promise.reject("UNZIP_FAILED", error.localizedDescription)
      }
    }

    AsyncFunction("zip") { (sourceDirPath: String, zipFilePath: String, promise: Promise) in
      if FileManager.default.fileExists(atPath: zipFilePath) {
        try? FileManager.default.removeItem(atPath: zipFilePath)
      }
      var error: NSError?
      let ok = NativeZipArchiveHelper.createZip(atPath: zipFilePath, fromDirectory: sourceDirPath, error: &error)
      if ok {
        promise.resolve()
      } else {
        promise.reject("ZIP_FAILED", error?.localizedDescription ?? "zip failed")
      }
    }

    AsyncFunction("remoteUnzip") { (distDirPath: String, url: String, headers: [String: String], promise: Promise) in
      // ponytail: cloud backup (Google Drive / self-hosted) — requires
      // authenticated streaming; not ported. Local backup/restore + EPUB
      // import all work via unzip/zip above.
      promise.reject("NOT_IMPLEMENTED", "remoteUnzip is not implemented on iOS")
    }

    AsyncFunction("remoteZip") { (sourceDirPath: String, url: String, headers: [String: String], promise: Promise) in
      promise.reject("NOT_IMPLEMENTED", "remoteZip is not implemented on iOS")
    }
  }
}
