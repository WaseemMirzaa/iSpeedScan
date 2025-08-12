import UIKit
import Flutter

extension AppDelegate {
    // This is called by the Flutter framework
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Call super to ensure existing functionality is preserved
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Register our plugin registrant handler
        if let controller = window?.rootViewController as? FlutterViewController {
            PluginRegistrantHandler.register(with: self.registrar(forPlugin: "PluginRegistrantHandler")!)
        }
    }
}