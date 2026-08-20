import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let protectionChannel = "priyatam_kavya/gallery_protection"
  private var protectionEnabled = false
  private var captureObserver: NSObjectProtocol?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: protectionChannel,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setProtected" else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.protectionEnabled = call.arguments as? Bool ?? false
      self?.updateCaptureObserver(channel: channel)
      result(UIScreen.main.isCaptured)
    }
  }

  private func updateCaptureObserver(channel: FlutterMethodChannel) {
    if protectionEnabled && captureObserver == nil {
      captureObserver = NotificationCenter.default.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: UIScreen.main,
        queue: .main
      ) { _ in
        channel.invokeMethod("captureChanged", arguments: UIScreen.main.isCaptured)
      }
    } else if !protectionEnabled, let captureObserver {
      NotificationCenter.default.removeObserver(captureObserver)
      self.captureObserver = nil
    }
  }
}
