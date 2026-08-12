import ExpoModulesCore
import Foundation
import UIKit

public class NativeFileModule: Module {
  public func definition() -> ModuleDefinition {
    Name("NativeFile")

    AsyncFunction("shareFile") { (filePath: String, promise: Promise) in
      // iOS share sheet (Save to Files / AirDrop / etc). Android uses SAF.
      // Delay past any dismissing modal: presenting while another VC is
      // mid-dismiss is silently dropped by UIKit.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
        guard let top = NativeFileModule.topViewController() else {
          promise.reject("NO_VIEW_CONTROLLER", "No active view controller")
          return
        }
        let url: URL
        if filePath.hasPrefix("file://") {
          // URI from copyFileToDirectory may be percent-encoded (spaces →
          // %20); URL(string:) decodes it.
          url = URL(string: filePath) ?? URL(fileURLWithPath: filePath)
        } else {
          url = URL(fileURLWithPath: filePath)
        }
        let controller = UIActivityViewController(
          activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
          promise.resolve()
        }
        // If UIKit drops the present (rare), the promise would never settle
        // and the export task would hang. Timeout: the file already lives in
        // Documents (visible in the Files app), so resolve anyway.
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
          promise.resolve()
        }
        if let popover = controller.popoverPresentationController {
          popover.sourceView = top.view
          popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
          popover.permittedArrowDirections = []
        }
        // If something is still presented (e.g. the export dialog finishing
        // its dismiss animation), UIKit drops the present — retry once.
        if top.presentedViewController != nil {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            top.present(controller, animated: true)
          }
        } else {
          top.present(controller, animated: true)
        }
      }
    }

    AsyncFunction("createDocument") { (filename: String, mimeType: String) -> String in
      // iOS has no SAF "create file at user-chosen location" flow; the backup
      // task writes asynchronously to the returned path, so it must be
      // immediately writable. Use the app's Documents dir, which is visible
      // in the system Files app when UIFileSharingEnabled is set.
      let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
      let dest = (docs as NSString).appendingPathComponent(filename)
      if !FileManager.default.fileExists(atPath: dest) {
        FileManager.default.createFile(atPath: dest, contents: nil)
      }
      return dest
    }

    AsyncFunction("pickDocument") { (mimeType: String, promise: Promise) in
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
      picker.modalPresentationStyle = .fullScreen
      picker.allowsMultipleSelection = false
      NativeFileModule.presentPicker(picker) { url in
        // Files-app picked URLs are security-scoped; keep access alive so
        // later readFile/copyFile calls don't hit EACCES.
        _ = url.startAccessingSecurityScopedResource()
        promise.resolve(url.path)
      }
    }

    AsyncFunction("pickDirectory") { (promise: Promise) in
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
      picker.modalPresentationStyle = .fullScreen
      picker.allowsMultipleSelection = false
      NativeFileModule.presentPicker(picker) { url in
        // Ask the system to keep access to this folder so writes succeed later.
        let didStart = url.startAccessingSecurityScopedResource()
        promise.resolve(["uri": url.path, "name": url.lastPathComponent])
        _ = didStart
      }
    }

    Function("writeFile") { (path: String, content: String) in
      try content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    Function("readFile") { (path: String) in
      try String(contentsOfFile: path, encoding: .utf8)
    }

    Function("copyFile") { (sourcePath: String, destPath: String) in
      let stripFileScheme = { (p: String) -> String in
        p.hasPrefix("file://") ? String(p.dropFirst(7)) : p
      }
      try FileManager.default.copyItem(
        atPath: stripFileScheme(sourcePath),
        toPath: stripFileScheme(destPath),
      )
    }

    AsyncFunction("copyFileToDirectory") { (sourcePath: String, directoryUri: String, fileName: String, mimeType: String, replace: Bool) -> [String: Any] in
      _ = mimeType
      guard !fileName.isEmpty,
            fileName != ".",
            fileName != "..",
            !fileName.contains("/"),
            !fileName.contains("\\") else {
        throw NSError(
          domain: "NativeFile",
          code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Invalid destination file name"]
        )
      }

      let fileManager = FileManager.default
      let directoryURL: URL
      if let parsedURL = URL(string: directoryUri), parsedURL.isFileURL {
        directoryURL = parsedURL
      } else {
        directoryURL = URL(fileURLWithPath: directoryUri, isDirectory: true)
      }
      let sourceURL = URL(fileURLWithPath: sourcePath)
      let destinationURL = directoryURL.appendingPathComponent(fileName)
      let stagingURL = directoryURL.appendingPathComponent(".\(fileName).\(UUID().uuidString).tmp")

      guard fileManager.fileExists(atPath: directoryURL.path) else {
        throw NSError(
          domain: "NativeFile",
          code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Destination directory does not exist"]
        )
      }
      if fileManager.fileExists(atPath: destinationURL.path) && !replace {
        throw CocoaError(.fileWriteFileExists)
      }

      defer { try? fileManager.removeItem(at: stagingURL) }
      try fileManager.copyItem(at: sourceURL, to: stagingURL)
      let attributes = try fileManager.attributesOfItem(atPath: stagingURL.path)
      let copiedSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0

      if fileManager.fileExists(atPath: destinationURL.path) {
        _ = try fileManager.replaceItemAt(destinationURL, withItemAt: stagingURL)
      } else {
        try fileManager.moveItem(at: stagingURL, to: destinationURL)
      }
      return ["uri": destinationURL.absoluteString, "size": copiedSize]
    }

    Function("moveFile") { (sourcePath: String, destPath: String) in
      let stripFileScheme = { (p: String) -> String in
        p.hasPrefix("file://") ? String(p.dropFirst(7)) : p
      }
      try FileManager.default.moveItem(
        atPath: stripFileScheme(sourcePath),
        toPath: stripFileScheme(destPath),
      )
    }

    Function("exists") { (filePath: String) in
      FileManager.default.fileExists(atPath: filePath)
    }

    Function("mkdir") { (filePath: String) in
      try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
    }

    Function("unlink") { (filePath: String) in
      try FileManager.default.removeItem(atPath: filePath)
    }

    Function("readDir") { (dirPath: String) -> [[String: Any]] in
      let contents = try FileManager.default.contentsOfDirectory(atPath: dirPath)
      return contents.map { fileName in
        let path = (dirPath as NSString).appendingPathComponent(fileName)
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return [
          "name": fileName,
          "path": path,
          "isDirectory": isDirectory.boolValue
        ]
      }
    }

    AsyncFunction("downloadFile") { (url: String, destPath: String, method: String, headers: [String: String], body: String?, promise: Promise) in
      guard let downloadURL = URL(string: url) else {
        promise.reject("INVALID_URL", "Invalid URL: \(url)")
        return
      }
      var request = URLRequest(url: downloadURL)
      request.httpMethod = method.isEmpty ? "GET" : method.uppercased()
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
      if let body {
        request.httpBody = body.data(using: .utf8)
      }
      // Ensure the destination directory exists.
      let fileManager = FileManager.default
      let destDir = (destPath as NSString).deletingLastPathComponent
      try? fileManager.createDirectory(atPath: destDir, withIntermediateDirectories: true)

      URLSession.shared.dataTask(with: request) { data, response, error in
        if let error {
          promise.reject("DOWNLOAD_FAILED", error.localizedDescription)
          return
        }
        guard let data, let response = response as? HTTPURLResponse else {
          promise.reject("DOWNLOAD_FAILED", "No data received")
          return
        }
        guard (200..<300).contains(response.statusCode) else {
          promise.reject(
            "HTTP_ERROR",
            "HTTP \(response.statusCode) for \(url)"
          )
          return
        }
        do {
          try data.write(to: URL(fileURLWithPath: destPath), options: .atomic)
          promise.resolve()
        } catch {
          promise.reject("WRITE_FAILED", error.localizedDescription)
        }
      }.resume()
    }

    Constant("DocumentDirectoryPath") {
      let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
      return paths.first ?? ""
    }

    Constant("ExternalDirectoryPath") {
      let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
      return paths.first ?? ""
    }

    Constant("ExternalCachesDirectoryPath") {
      let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
      return paths.first ?? ""
    }
  }

  // MARK: - Document picker helpers

  private static var pickerDelegate: PickerDelegate?

  static func presentPicker(_ picker: UIDocumentPickerViewController, completion: @escaping (URL) -> Void) {
    let delegate = PickerDelegate()
    delegate.onPick = completion
    pickerDelegate = delegate
    picker.delegate = delegate
    DispatchQueue.main.async {
      topViewController()?.present(picker, animated: true)
    }
  }

  static func topViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive })
    else { return nil }
    var top = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }

  private class PickerDelegate: NSObject, UIDocumentPickerDelegate {
    var onPick: ((URL) -> Void)?

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      if let url = urls.first {
        onPick?(url)
      }
      NativeFileModule.pickerDelegate = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
      NativeFileModule.pickerDelegate = nil
    }
  }
}
