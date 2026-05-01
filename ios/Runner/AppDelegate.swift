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
    QuickExpenseNotificationCategoryRegistry.register()

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

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let actionIdentifier = response.actionIdentifier
    
    if actionIdentifier.hasPrefix("CAT_") {
      let categorySlug = String(actionIdentifier.dropFirst(4))
      let userInfo = response.notification.request.content.userInfo
      handleNotificationAction(
        categorySlug: categorySlug,
        userInfo: userInfo,
        completionHandler: completionHandler
      )
      return
    }
    
    // Si no es una de nuestras acciones, dejamos que FlutterAppDelegate maneje el comportamiento por defecto
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  private func handleNotificationAction(
    categorySlug: String,
    userInfo: [AnyHashable: Any],
    completionHandler: @escaping () -> Void
  ) {
    guard let amount = userInfo["amount"] as? Double,
          let description = userInfo["description"] as? String,
          let idempotencyKey = userInfo["idempotencyKey"] as? String else {
      completionHandler()
      return
    }
    
    Task {
      defer { completionHandler() }
      if let context = QuickExpenseShortcutContextStore.load() {
        let categoryName = context.categories.first { $0.slug == categorySlug }?.name ?? categorySlug
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
          let response = try await QuickExpenseNetworkClient.post(expense: expense, context: context)
          guard (200 ... 299).contains(response.statusCode) else {
            if QuickExpenseNetworkClient.shouldQueue(statusCode: response.statusCode) {
              QueuedQuickExpenseStore.enqueue(expense)
              MenudoShortcutFeedback.expenseSaved(
                amount: amount,
                merchant: description,
                categoryName: categoryName,
                currencyCode: context.defaultWallet.currency,
                queued: true
              )
            }
            return
          }
          QuickExpenseIdempotencyStore.mark(idempotencyKey)
          PendingShortcutStore.storeQuickExpense(source: "notification_action")
          MenudoShortcutFeedback.expenseSaved(
            amount: amount,
            merchant: description,
            categoryName: categoryName,
            currencyCode: context.defaultWallet.currency
          )
        } catch {
          QueuedQuickExpenseStore.enqueue(expense)
          MenudoShortcutFeedback.expenseSaved(
            amount: amount,
            merchant: description,
            categoryName: categoryName,
            currencyCode: context.defaultWallet.currency,
            queued: true
          )
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
