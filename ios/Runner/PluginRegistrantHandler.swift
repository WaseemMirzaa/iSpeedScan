import Foundation
import Flutter

class PluginRegistrantHandler: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.tevineighdesigns.ispeedscan1/plugin_registrant", binaryMessenger: registrar.messenger())
        let instance = PluginRegistrantHandler(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private let registrar: FlutterPluginRegistrar
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "registerPlugins" {
            // Register our scanner locale plugin
            ScannerLocalePlugin.register(with: registrar)
            result.success(true)
        } else {
            result.notImplemented()
        }
    }
}