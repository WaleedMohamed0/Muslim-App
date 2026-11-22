import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let shareChannel = FlutterMethodChannel(
        name: "com.muslim/quran_share",
        binaryMessenger: controller.binaryMessenger
      )
      shareChannel.setMethodCallHandler { [weak controller] call, result in
        guard call.method == "shareText" || call.method == "shareImage" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let arguments = call.arguments as? [String: Any], let controller = controller else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Share details are required", details: nil))
          return
        }

        let title = arguments["title"] as? String ?? ""
        let item: Any
        if call.method == "shareText", let text = arguments["text"] as? String, !text.isEmpty {
          item = text
        } else if call.method == "shareImage", let path = arguments["path"] as? String, let image = UIImage(contentsOfFile: path) {
          item = image
        } else {
          result(FlutterError(code: "INVALID_SHARE_ITEM", message: "Share item is unavailable", details: nil))
          return
        }
        let activityController = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        activityController.setValue(title, forKey: "subject")
        if let popover = activityController.popoverPresentationController {
          popover.sourceView = controller.view
          popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 0, height: 0)
          popover.permittedArrowDirections = []
        }
        controller.present(activityController, animated: true) {
          result(nil)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
