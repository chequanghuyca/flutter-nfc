import Flutter
import ImageIO
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var portraitDecoderChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.example.nfc_ekyc_demo/portrait_decoder",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "decodeToPng" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let bytes = call.arguments as? FlutterStandardTypedData else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Portrait bytes are required.",
            details: nil
          )
        )
        return
      }
      guard
        let source = CGImageSourceCreateWithData(bytes.data as CFData, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
        let pngData = UIImage(cgImage: image).pngData()
      else {
        result(
          FlutterError(
            code: "unsupported_image",
            message: "ImageIO could not decode the DG2 portrait.",
            details: nil
          )
        )
        return
      }
      result(FlutterStandardTypedData(bytes: pngData))
    }
    portraitDecoderChannel = channel
  }
}
