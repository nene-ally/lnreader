import ExpoModulesCore
import Foundation

public class NativeVolumeButtonListenerModule: Module {
  public func definition() -> ModuleDefinition {
    Name("NativeVolumeButtonListener")

    Events("VolumeUp", "VolumeDown")

    Function("setActive") { (active: Bool) in
      // iOS volume keys are controlled by the system; nothing to activate.
      // Kept as a no-op so the JS API never throws on iOS.
    }
  }
}
