import Flutter
import StoreKit

@objc class AppStoreReceiptHandler: NSObject {
    private var pendingResult: FlutterResult?
    
    @objc static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "app_store_receipt", binaryMessenger: registrar.messenger())
        let instance = AppStoreReceiptHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
}

extension AppStoreReceiptHandler: FlutterPlugin {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getReceipt" {
            pendingResult = result
            
            if let receiptURL = Bundle.main.appStoreReceiptURL {
                print("📍 Initial Receipt URL: \(receiptURL.absoluteString)")
                
                // Try to read the receipt
                if let receiptData = try? Data(contentsOf: receiptURL) {
                    let receipt = receiptData.base64EncodedString()
                    print("✅ Receipt found with size: \(receiptData.count) bytes")
                    result(receipt)
                    return
                }
            }
            
            print("🔄 No valid receipt found - Requesting refresh")
            
            // Force refresh the receipt
            let request = SKReceiptRefreshRequest(receiptProperties: nil)
            request.delegate = self
            request.start()
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}

extension AppStoreReceiptHandler: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        print("✅ Receipt refresh completed")
        
        // Add a small delay to ensure the receipt is written to disk
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            if let receiptURL = Bundle.main.appStoreReceiptURL,
               let receiptData = try? Data(contentsOf: receiptURL) {
                let receipt = receiptData.base64EncodedString()
                print("📝 Receipt generated successfully")
                print("📍 Receipt Location: \(receiptURL.absoluteString)")
                print("📦 Receipt Size: \(receiptData.count) bytes")
                self.pendingResult?(receipt)
            } else {
                print("❌ Still no receipt after refresh")
                // Try one more time with explicit sandbox receipt generation
                self.generateSandboxReceipt()
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("❌ Receipt refresh failed: \(error.localizedDescription)")
        pendingResult?(nil)
    }
    
    private func generateSandboxReceipt() {
        #if DEBUG
        print("🔄 Attempting explicit sandbox receipt generation")
        
        // Create a temporary in-app purchase request to force receipt generation
        if let product = SKProduct() as? SKProduct {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
            
            // Immediately remove the transaction since we don't actually want to process it
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                SKPaymentQueue.default().restoreCompletedTransactions()
            }
            
            // Check for receipt one final time after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if let receiptURL = Bundle.main.appStoreReceiptURL,
                   let receiptData = try? Data(contentsOf: receiptURL) {
                    let receipt = receiptData.base64EncodedString()
                    print("✅ Sandbox receipt finally generated")
                    self?.pendingResult?(receipt)
                } else {
                    print("❌ Final attempt to generate receipt failed")
                    self?.pendingResult?(nil)
                }
            }
        } else {
            print("❌ Could not create test product for receipt generation")
            pendingResult?(nil)
        }
        #else
        pendingResult?(nil)
        #endif
    }
}


