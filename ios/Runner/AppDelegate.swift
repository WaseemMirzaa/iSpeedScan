import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentInteractionControllerDelegate {
    var documentInteractionController: UIDocumentInteractionController?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.ispeedscan/share", binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "shareFileOnIpad" {
                guard let args = call.arguments as? [String: Any],
                      let filePath = args["filePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", 
                                      message: "Missing filePath argument", 
                                      details: nil))
                    return
                }
                
                self.shareFile(filePath: filePath, controller: controller, result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func shareFile(filePath: String, controller: FlutterViewController, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            NSLog("🟡 iPad Sharing: Attempting to share file at path: %@", filePath)
            
            let fileURL = URL(fileURLWithPath: filePath)
            
            guard FileManager.default.fileExists(atPath: filePath) else {
                NSLog("🔴 iPad Sharing: File does not exist at path: %@", filePath)
                result(FlutterError(code: "FILE_NOT_FOUND",
                                  message: "File not found at specified path",
                                  details: nil))
                return
            }
            
            let activityViewController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // Configure for iPad
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = controller.view
                popoverController.sourceRect = CGRect(x: controller.view.bounds.midX,
                                                    y: controller.view.bounds.midY,
                                                    width: 0,
                                                    height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
                if completed {
                    NSLog("🟢 iPad Sharing: Share completed successfully")
                    result(true)
                } else {
                    NSLog("🔴 iPad Sharing: Share cancelled or failed")
                    if let error = error {
                        NSLog("🔴 iPad Sharing Error: %@", error.localizedDescription)
                    }
                    result(false)
                }
            }
            
            controller.present(activityViewController, animated: true) {
                NSLog("🟢 iPad Sharing: Share sheet presented")
            }
        }
    }
    
    // MARK: - UIDocumentInteractionControllerDelegate
    
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return window?.rootViewController ?? UIViewController()
    }
}
