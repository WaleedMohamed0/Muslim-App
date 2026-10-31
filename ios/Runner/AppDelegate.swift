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
        guard call.method == "shareText" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let arguments = call.arguments as? [String: Any],
          let text = arguments["text"] as? String,
          !text.isEmpty,
          let controller = controller
        else {
          result(FlutterError(code: "INVALID_TEXT", message: "Text to share is required", details: nil))
          return
        }

        let title = arguments["title"] as? String ?? ""
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
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
