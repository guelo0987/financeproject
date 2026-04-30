import Flutter
import UIKit
import UserNotifications

#if canImport(AppIntents)
import AppIntents
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    registerNotificationCategories()

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

  private func registerNotificationCategories() {
    let center = UNUserNotificationCenter.current()
    
    let foodAction = UNNotificationAction(identifier: "CAT_comida", title: "Comida 🍔", options: .foreground)
    let shoppingAction = UNNotificationAction(identifier: "CAT_compras", title: "Compras 🛍️", options: .foreground)
    let transportAction = UNNotificationAction(identifier: "CAT_transporte", title: "Transporte 🚗", options: .foreground)
    let miscAction = UNNotificationAction(identifier: "CAT_varios", title: "Otros 📦", options: .foreground)
    
    let category = UNNotificationCategory(
      identifier: "EXPENSE_MISSING_CATEGORY",
      actions: [foodAction, shoppingAction, transportAction, miscAction],
      intentIdentifiers: [],
      options: .customDismissAction
    )
    
    center.setNotificationCategories([category])
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let actionIdentifier = response.actionIdentifier
    
    if actionIdentifier.hasPrefix("CAT_") {
      let categorySlug = String(actionIdentifier.dropFirst(4))
      let userInfo = response.notification.request.content.userInfo
      handleNotificationAction(categorySlug: categorySlug, userInfo: userInfo)
    }
    
    // Si no es una de nuestras acciones, dejamos que FlutterAppDelegate maneje el comportamiento por defecto
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  private func handleNotificationAction(categorySlug: String, userInfo: [AnyHashable: Any]) {
    guard let amount = userInfo["amount"] as? Double,
          let description = userInfo["description"] as? String,
          let idempotencyKey = userInfo["idempotencyKey"] as? String else {
      return
    }
    
    Task {
      if let context = QuickExpenseShortcutContextStore.load() {
        let expense = QueuedQuickExpense(
          idempotencyKey: idempotencyKey,
          fecha: currentDateString(),
          descripcion: description,
          monto: amount,
          tipo: "gasto",
          catKey: categorySlug,
          walletId: context.defaultWallet.id,
          nota: description,
          moneda: context.defaultWallet.currency,
          createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
          _ = try await QuickExpenseNetworkClient.post(expense: expense, context: context)
          QuickExpenseIdempotencyStore.mark(idempotencyKey)
        } catch {
          QueuedQuickExpenseStore.enqueue(expense)
        }
      }
    }
  }

  private func currentDateString() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
  }
}
