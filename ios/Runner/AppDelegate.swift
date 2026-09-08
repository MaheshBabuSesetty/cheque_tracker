import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var privacyOverlay: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if !DEBUG
    // Blurs the app-switcher snapshot so Emirates ID scans, cheque images,
    // and cheque amounts aren't visible there — iOS has no API to block
    // screenshots outright, unlike Android's FLAG_SECURE (see
    // MainActivity.kt). Skipped in debug builds so the team can still
    // screenshot while developing/testing. See the security audit's F-6.
    NotificationCenter.default.addObserver(
      self, selector: #selector(addPrivacyOverlay),
      name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(removePrivacyOverlay),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func currentKeyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  @objc private func addPrivacyOverlay() {
    guard privacyOverlay == nil, let window = currentKeyWindow() else { return }
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    blur.frame = window.bounds
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(blur)
    privacyOverlay = blur
  }

  @objc private func removePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
