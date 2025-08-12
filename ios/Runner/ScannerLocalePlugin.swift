import Foundation
import Flutter

class ScannerLocalePlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.tevineighdesigns.ispeedscan1/scanner_locale", binaryMessenger: registrar.messenger())
        let instance = ScannerLocalePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "setScannerLocale" {
            guard let args = call.arguments as? [String: Any],
                  let localeString = args["locale"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            // Store the locale in UserDefaults for the scanner to access
            UserDefaults.standard.set(localeString, forKey: "scanner_locale")
            
            // Set environment variable that the scanner might check
            setenv("CUNNING_SCANNER_LOCALE", localeString, 1)
            
            result(true)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}