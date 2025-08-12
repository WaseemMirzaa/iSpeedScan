import Foundation
import Flutter

class FlutterPluginRegistrant: NSObject {
    static func registerPlugins(with registry: FlutterPluginRegistry) {
        // Register our scanner locale plugin
        ScannerLocalePlugin.register(with: registry as! FlutterPluginRegistrar)
    }
}