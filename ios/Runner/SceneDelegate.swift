import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let url = connectionOptions.urlContexts.first?.url {
      _ = handleMenudoURL(url)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    let handledShortcutURL = URLContexts.contains { handleMenudoURL($0.url) }
    if handledShortcutURL { return }
    super.scene(scene, openURLContexts: URLContexts)
  }

  @discardableResult
  private func handleMenudoURL(_ url: URL) -> Bool {
    guard url.scheme?.lowercased() == "menudo" else { return false }

    let host = url.host?.lowercased()
    let path = url.path.lowercased()
    if host == "shortcut" && path == "/quick-expense" {
      PendingShortcutStore.storeQuickExpense(source: "live_activity_tap")
      return true
    }

    return false
  }
}
