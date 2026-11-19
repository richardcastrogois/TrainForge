import Flutter
import UIKit
import zlib

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
    let catalogChannel = FlutterMethodChannel(
      name: "trainforge/catalog_assets",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    catalogChannel.setMethodCallHandler { call, result in
      guard call.method == "copyAsset" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let arguments = call.arguments as? [String: Any],
            let asset = arguments["asset"] as? String,
            let destination = arguments["destination"] as? String,
            asset.range(of: "^assets/food_catalog/[A-Za-z0-9_.-]+$", options: .regularExpression) != nil else {
        result(FlutterError(code: "invalid_catalog_asset", message: "Invalid catalog file", details: nil))
        return
      }
      let lookup = engineBridge.applicationRegistrar.lookupKey(forAsset: asset)
      let decompressGzip = (arguments["decompressGzip"] as? Bool) == true
      let maxBytes = (arguments["maxBytes"] as? NSNumber)?.int64Value ?? Int64.max
      DispatchQueue.global(qos: .utility).async {
        var partialTarget: URL?
        do {
          let manager = FileManager.default
          let root = try manager.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                     appropriateFor: nil, create: true).resolvingSymlinksInPath()
          let target = URL(fileURLWithPath: destination).standardized.resolvingSymlinksInPath()
          guard maxBytes > 0, (!decompressGzip || asset.hasSuffix(".gz")),
                target.path.hasPrefix(root.path + "/"),
                !manager.fileExists(atPath: target.path),
                let source = Bundle.main.path(forResource: lookup, ofType: nil) else {
            throw CocoaError(.fileWriteInvalidFileName)
          }
          partialTarget = target
          if decompressGzip {
            guard let input = gzopen(source, "rb") else {
              throw CocoaError(.fileReadUnknown)
            }
            defer { gzclose(input) }
            guard manager.createFile(atPath: target.path, contents: nil) else {
              throw CocoaError(.fileWriteUnknown)
            }
            let output = try FileHandle(forWritingTo: target)
            defer { try? output.close() }
            var buffer = [UInt8](repeating: 0, count: 65536)
            var count: Int64 = 0
            while true {
              let read = gzread(input, &buffer, UInt32(buffer.count))
              if read == 0 { break }
              guard read > 0 else { throw CocoaError(.fileReadCorruptFile) }
              count += Int64(read)
              guard count <= maxBytes else { throw CocoaError(.fileReadCorruptFile) }
              try output.write(contentsOf: Data(buffer.prefix(Int(read))))
            }
            guard maxBytes == Int64.max || count == maxBytes else {
              throw CocoaError(.fileReadCorruptFile)
            }
            try output.synchronize()
          } else {
            // Foundation copies without materializing the whole catalog in Dart.
            try manager.copyItem(at: URL(fileURLWithPath: source), to: target)
          }
          let size = try manager.attributesOfItem(atPath: target.path)[.size] as? NSNumber
          DispatchQueue.main.async { result(size?.int64Value ?? 0) }
        } catch {
          if let target = partialTarget { try? FileManager.default.removeItem(at: target) }
          DispatchQueue.main.async {
            result(FlutterError(code: "catalog_copy_failed", message: "Catalog file could not be copied", details: nil))
          }
        }
      }
    }
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
    let localeChannel = FlutterMethodChannel(
      name: "trainforge/locale",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    localeChannel.setMethodCallHandler { call, result in
      let key = "trainforge.locale.language"
      switch call.method {
      case "read":
        result(UserDefaults.standard.string(forKey: key) ?? "system")
      case "write":
        guard let language = call.arguments as? String,
              ["system", "pt-BR", "pt-PT", "en", "es"].contains(language) else {
          result(FlutterError(code: "invalid_locale", message: "Unsupported locale", details: nil))
          return
        }
        UserDefaults.standard.set(language, forKey: key)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
