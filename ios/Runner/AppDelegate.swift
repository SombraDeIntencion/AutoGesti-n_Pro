import Flutter
import UIKit
import AVFoundation
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.mahondev.autogestionmax/native_helper",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "checkPermission":
        if let args = call.arguments as? [String: Any],
           let permission = args["permission"] as? String {
          result(self?.checkPermission(permission) ?? "denied")
        } else {
          result("denied")
        }
      case "requestPermission":
        if let args = call.arguments as? [String: Any],
           let permission = args["permission"] as? String {
          self?.requestPermission(permission, result: result)
        } else {
          result("denied")
        }
      case "openAppSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(true)
      case "openFile":
        if let args = call.arguments as? [String: Any],
           let path = args["path"] as? String {
          result(self?.openFile(path))
        } else {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func checkPermission(_ type: String) -> String {
    switch type {
    case "camera":
      let status = AVCaptureDevice.authorizationStatus(for: .video)
      switch status {
      case .authorized: return "granted"
      case .denied, .restricted: return "permanentlyDenied"
      case .notDetermined: return "denied"
      @unknown default: return "denied"
      }
    case "photos":
      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .authorized, .limited: return "granted"
      case .denied, .restricted: return "permanentlyDenied"
      case .notDetermined: return "denied"
      @unknown default: return "denied"
      }
    default:
      return "granted"
    }
  }

  private func requestPermission(_ type: String, result: @escaping FlutterResult) {
    switch type {
    case "camera":
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          result(granted ? "granted" : "permanentlyDenied")
        }
      }
    case "photos":
      PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async {
          switch status {
          case .authorized, .limited:
            result("granted")
          default:
            result("permanentlyDenied")
          }
        }
      }
    default:
      result("granted")
    }
  }

  private func openFile(_ path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else { return false }
    let controller = UIDocumentInteractionController(url: url)
    guard let viewController = window?.rootViewController else { return false }
    return controller.presentPreview(animated: true)
  }
}

extension AppDelegate: UIDocumentInteractionControllerDelegate {
  func documentInteractionControllerViewControllerForPreview(
    _ controller: UIDocumentInteractionController
  ) -> UIViewController {
    return window!.rootViewController!
  }
}
