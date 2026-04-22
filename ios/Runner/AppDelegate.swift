import Flutter
import UIKit

#if canImport(AppIntents)
import AppIntents
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if canImport(AppIntents)
    if #available(iOS 16.0, *) {
      MenudoAppShortcutsProvider.updateAppShortcutParameters()
    }
    #endif

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    MenudoShortcutsBridge.shared.configure(with: engineBridge.pluginRegistry)

    #if canImport(AppIntents)
    if #available(iOS 16.0, *) {
      MenudoAppShortcutsProvider.updateAppShortcutParameters()
    }
    #endif
  }
}
