import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "trainforge/appearance",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      let key = "trainforge.appearance.mode"
      switch call.method {
      case "read":
        result(UserDefaults.standard.string(forKey: key) ?? "system")
      case "write":
        guard let mode = call.arguments as? String,
              ["system", "light", "dark"].contains(mode) else {
          result(FlutterError(code: "invalid_mode", message: "Unsupported appearance", details: nil))
          return
        }
        UserDefaults.standard.set(mode, forKey: key)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
