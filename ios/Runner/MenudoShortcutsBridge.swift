import Flutter
import Foundation
import SwiftUI
import UIKit

#if canImport(AppIntents)
import AppIntents
#endif

private struct PendingShortcutPayload: Codable {
  let action: String
  let source: String
  let createdAt: String

  var dictionary: [String: Any] {
    [
      "action": action,
      "source": source,
      "createdAt": createdAt,
    ]
  }
}

private enum MenudoShortcutsSharedStore {
  static let appGroupId = "group.com.miguelcruz.financeapp"

  static var defaults: UserDefaults {
    UserDefaults(suiteName: appGroupId) ?? .standard
  }
}

struct ShortcutWalletContext: Codable {
  let id: Int
  let name: String
  let currency: String
}

struct ShortcutCategoryContext: Codable {
  let slug: String
  let name: String
  let icon: String?
}

struct QuickExpenseShortcutContext: Codable {
  let apiBaseUrl: String
  let authToken: String
  let defaultWallet: ShortcutWalletContext
  let categories: [ShortcutCategoryContext]
}

enum QuickExpenseShortcutContextStore {
  private static let key = "menudo.quickExpenseContext"

  static func save(rawPayload: Any?) {
    guard let rawPayload else { return }
    guard JSONSerialization.isValidJSONObject(rawPayload) else {
      print("[shortcuts] invalid quick expense context payload")
      return
    }

    do {
      let data = try JSONSerialization.data(withJSONObject: rawPayload)
      let context = try JSONDecoder().decode(QuickExpenseShortcutContext.self, from: data)
      let encoded = try JSONEncoder().encode(context)
      MenudoShortcutsSharedStore.defaults.set(encoded, forKey: key)
      MenudoShortcutsSharedStore.defaults.synchronize()
      print("[shortcuts] synced quick expense context")
    } catch {
      print("[shortcuts] failed to sync quick expense context: \(error.localizedDescription)")
    }
  }

  static func load() -> QuickExpenseShortcutContext? {
    guard let data = MenudoShortcutsSharedStore.defaults.data(forKey: key) else {
      print("[shortcuts] no quick expense context found")
      return nil
    }

    do {
      let context = try JSONDecoder().decode(QuickExpenseShortcutContext.self, from: data)
      return context
    } catch {
      print("[shortcuts] failed to decode quick expense context: \(error.localizedDescription)")
      return nil
    }
  }

  static func clear() {
    MenudoShortcutsSharedStore.defaults.removeObject(forKey: key)
    MenudoShortcutsSharedStore.defaults.synchronize()
    print("[shortcuts] cleared quick expense context")
  }
}

enum PendingShortcutStore {
  private static let key = "menudo.pendingShortcutPayload"

  static func storeQuickExpense(source: String) {
    let payload = PendingShortcutPayload(
      action: "quick_expense",
      source: source,
      createdAt: ISO8601DateFormatter().string(from: Date())
    )

    guard let data = try? JSONEncoder().encode(payload) else { return }
    MenudoShortcutsSharedStore.defaults.set(data, forKey: key)
    MenudoShortcutsSharedStore.defaults.synchronize()
    print("[shortcuts] stored pending shortcut payload from \(source)")
    MenudoShortcutsBridge.shared.notifyPendingShortcutIfPossible()
  }

  static func peek() -> [String: Any]? {
    guard
      let data = MenudoShortcutsSharedStore.defaults.data(forKey: key),
      let payload = try? JSONDecoder().decode(PendingShortcutPayload.self, from: data)
    else {
      print("[shortcuts] no pending shortcut payload found")
      return nil
    }

    print("[shortcuts] found pending shortcut payload")
    return payload.dictionary
  }

  static func consume() -> [String: Any]? {
    let payload = peek()
    clear()
    return payload
  }

  static func clear() {
    MenudoShortcutsSharedStore.defaults.removeObject(forKey: key)
    MenudoShortcutsSharedStore.defaults.synchronize()
    print("[shortcuts] cleared pending shortcut payload")
  }
}

final class MenudoShortcutsBridge: NSObject {
  static let shared = MenudoShortcutsBridge()

  private var channel: FlutterMethodChannel?

  func configure(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "MenudoShortcutsBridge") else {
      assertionFailure("MenudoShortcutsBridge registrar unavailable")
      return
    }

    let channel = FlutterMethodChannel(
      name: "menudo/shortcuts",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }

    self.channel = channel
  }

  func notifyPendingShortcutIfPossible() {
    guard let payload = PendingShortcutStore.peek() else { return }

    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod("shortcutTriggered", arguments: payload)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "presentShortcutSetup":
      presentShortcutSetup()
      result(nil)
    case "syncQuickExpenseContext":
      QuickExpenseShortcutContextStore.save(rawPayload: call.arguments)
      result(nil)
    case "clearQuickExpenseContext":
      QuickExpenseShortcutContextStore.clear()
      result(nil)
    case "consumePendingShortcut":
      result(PendingShortcutStore.consume())
    case "clearPendingShortcut":
      PendingShortcutStore.clear()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentShortcutSetup() {
    DispatchQueue.main.async { [weak self] in
      guard let presenter = self?.topViewController() else { return }

      #if canImport(AppIntents)
      if #available(iOS 16.0, *) {
        let controller = UIHostingController(rootView: MenudoShortcutSetupNativeView())
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
          sheet.detents = [.medium(), .large()]
          sheet.prefersGrabberVisible = true
          sheet.preferredCornerRadius = 28
        }
        presenter.present(controller, animated: true)
        return
      }
      #endif

      let alert = UIAlertController(
        title: "Atajos de iPhone",
        message: "El shortcut de Menudo ya está disponible. Abre Shortcuts y busca “Registrar gasto rápido” de Menudo para usarlo con doble toque atrás, Action Button o una automatización por transacción.",
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "Listo", style: .default))
      presenter.present(alert, animated: true)
    }
  }

  private func topViewController(
    from controller: UIViewController? = UIApplication.shared
      .connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
  ) -> UIViewController? {
    if let navigation = controller as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tab = controller as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    if let presented = controller?.presentedViewController {
      return topViewController(from: presented)
    }
    return controller
  }
}

#if canImport(AppIntents)
@available(iOS 16.0, *)
private struct MenudoShortcutSetupNativeView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          VStack(alignment: .leading, spacing: 10) {
            Text("Ver en Shortcuts")
              .font(.system(size: 28, weight: .bold, design: .rounded))
              .foregroundStyle(Color(red: 0.09, green: 0.36, blue: 0.27))

            Text("El atajo ya viene listo. Desde aquí solo abres Shortcuts para verlo.")
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }

          VStack(spacing: 14) {
            ShortcutsLink()
              .frame(maxWidth: .infinity)
              .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 10) {
              nativeSimpleStep("1", "Abre Menudo una vez con tu sesión iniciada.")
              nativeSimpleStep("2", "Busca “Registrar gasto rápido” en Shortcuts.")
              nativeSimpleStep("3", "Ese atajo registra monto, categoría y nota.")
            }
          }
          .padding(20)
          .frame(maxWidth: .infinity)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(20)
      }
      .background(Color(red: 0.97, green: 0.98, blue: 0.98))
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Listo") {
            dismiss()
          }
          .font(.system(size: 16, weight: .semibold))
        }
      }
    }
  }

  @ViewBuilder
  private func nativeSimpleStep(_ index: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      ZStack {
        Circle()
          .fill(Color(red: 0.92, green: 0.97, blue: 0.95))
          .frame(width: 24, height: 24)
        Text(index)
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(Color(red: 0.09, green: 0.36, blue: 0.27))
      }

      Text(text)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
#endif
