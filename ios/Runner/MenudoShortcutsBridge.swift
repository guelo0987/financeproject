import Flutter
import Foundation
import Security
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

struct ShortcutMerchantHint: Codable {
  let merchantKey: String
  let merchantName: String
  let categorySlug: String
  let categoryName: String
  let confidence: Double
  let count: Int
}

struct IncomingQuickExpenseShortcutContext: Codable {
  let apiBaseUrl: String
  let authToken: String
  let defaultWallet: ShortcutWalletContext
  let categories: [ShortcutCategoryContext]
  let merchantHints: [ShortcutMerchantHint]?
  let frequentCategories: [ShortcutCategoryContext]?
}

struct QuickExpenseShortcutContext: Codable {
  let apiBaseUrl: String
  let defaultWallet: ShortcutWalletContext
  let categories: [ShortcutCategoryContext]
  let merchantHints: [ShortcutMerchantHint]
  let frequentCategories: [ShortcutCategoryContext]
}

struct QuickExpenseShortcutRuntimeContext {
  let apiBaseUrl: String
  let authToken: String
  let defaultWallet: ShortcutWalletContext
  let categories: [ShortcutCategoryContext]
  let merchantHints: [ShortcutMerchantHint]
  let frequentCategories: [ShortcutCategoryContext]
}

private enum ShortcutCredentialStore {
  private static let service = "com.miguelcruz.financeapp.quickExpense"
  private static let account = "authToken"

  static func saveAuthToken(_ token: String) throws {
    let data = Data(token.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecSuccess { return }
    if status == errSecItemNotFound {
      var insertQuery = query
      insertQuery.merge(attributes) { _, new in new }
      let insertStatus = SecItemAdd(insertQuery as CFDictionary, nil)
      guard insertStatus == errSecSuccess else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(insertStatus))
      }
      return
    }

    throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
  }

  static func loadAuthToken() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  static func clearAuthToken() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)
  }
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
      let incoming = try JSONDecoder().decode(IncomingQuickExpenseShortcutContext.self, from: data)
      try ShortcutCredentialStore.saveAuthToken(incoming.authToken)
      let context = QuickExpenseShortcutContext(
        apiBaseUrl: incoming.apiBaseUrl,
        defaultWallet: incoming.defaultWallet,
        categories: incoming.categories,
        merchantHints: incoming.merchantHints ?? [],
        frequentCategories: incoming.frequentCategories ?? Array(incoming.categories.prefix(5))
      )
      let encoded = try JSONEncoder().encode(context)
      MenudoShortcutsSharedStore.defaults.set(encoded, forKey: key)
      MenudoShortcutsSharedStore.defaults.synchronize()
      #if canImport(AppIntents)
      if #available(iOS 16.0, *) {
        MenudoAppShortcutsProvider.updateAppShortcutParameters()
      }
      #endif
      QuickExpenseNotificationCategoryRegistry.register()
      print("[shortcuts] synced quick expense context")
    } catch {
      print("[shortcuts] failed to sync quick expense context: \(error.localizedDescription)")
    }
  }

  static func load() -> QuickExpenseShortcutRuntimeContext? {
    guard let data = MenudoShortcutsSharedStore.defaults.data(forKey: key) else {
      print("[shortcuts] no quick expense context found")
      return nil
    }

    do {
      let context = try JSONDecoder().decode(QuickExpenseShortcutContext.self, from: data)
      guard let authToken = ShortcutCredentialStore.loadAuthToken(), !authToken.isEmpty else {
        print("[shortcuts] no quick expense auth token found")
        return nil
      }
      return QuickExpenseShortcutRuntimeContext(
        apiBaseUrl: context.apiBaseUrl,
        authToken: authToken,
        defaultWallet: context.defaultWallet,
        categories: context.categories,
        merchantHints: context.merchantHints,
        frequentCategories: context.frequentCategories
      )
    } catch {
      print("[shortcuts] failed to decode quick expense context: \(error.localizedDescription)")
      return nil
    }
  }

  static func clear() {
    MenudoShortcutsSharedStore.defaults.removeObject(forKey: key)
    ShortcutCredentialStore.clearAuthToken()
    MenudoShortcutsSharedStore.defaults.synchronize()
    #if canImport(AppIntents)
    if #available(iOS 16.0, *) {
      MenudoAppShortcutsProvider.updateAppShortcutParameters()
    }
    #endif
    QuickExpenseNotificationCategoryRegistry.register()
    print("[shortcuts] cleared quick expense context")
  }
}

struct QueuedQuickExpense: Codable {
  let idempotencyKey: String
  let fecha: String
  let descripcion: String
  let monto: Double
  let tipo: String
  let catKey: String
  let walletId: Int
  let nota: String?
  let moneda: String
  let createdAt: String

  var body: [String: Any?] {
    [
      "fecha": fecha,
      "descripcion": descripcion,
      "monto": monto,
      "tipo": tipo,
      "budgetId": nil,
      "catKey": catKey,
      "walletId": walletId,
      "nota": nota,
      "moneda": moneda,
      "idempotencyKey": idempotencyKey,
    ]
  }
}

enum QuickExpenseIdempotencyStore {
  private static let key = "menudo.quickExpenseProcessedKeys"
  private static let ttl: TimeInterval = 10 * 60

  static func contains(_ idempotencyKey: String) -> Bool {
    prune()
    let values = MenudoShortcutsSharedStore.defaults.dictionary(forKey: key) as? [String: TimeInterval] ?? [:]
    return values[idempotencyKey] != nil
  }

  static func mark(_ idempotencyKey: String) {
    prune()
    var values = MenudoShortcutsSharedStore.defaults.dictionary(forKey: key) as? [String: TimeInterval] ?? [:]
    values[idempotencyKey] = Date().timeIntervalSince1970
    MenudoShortcutsSharedStore.defaults.set(values, forKey: key)
    MenudoShortcutsSharedStore.defaults.synchronize()
  }

  private static func prune() {
    var values = MenudoShortcutsSharedStore.defaults.dictionary(forKey: key) as? [String: TimeInterval] ?? [:]
    let cutoff = Date().timeIntervalSince1970 - ttl
    values = values.filter { $0.value >= cutoff }
    MenudoShortcutsSharedStore.defaults.set(values, forKey: key)
  }
}

enum QueuedQuickExpenseStore {
  private static let key = "menudo.queuedQuickExpenses"
  private static let maxItems = 20

  static func enqueue(_ expense: QueuedQuickExpense) {
    var items = load()
    guard !items.contains(where: { $0.idempotencyKey == expense.idempotencyKey }) else { return }
    items.insert(expense, at: 0)
    if items.count > maxItems {
      items = Array(items.prefix(maxItems))
    }
    save(items)
    QuickExpenseIdempotencyStore.mark(expense.idempotencyKey)
    print("[shortcuts] queued quick expense \(expense.idempotencyKey)")
  }

  static func load() -> [QueuedQuickExpense] {
    guard let data = MenudoShortcutsSharedStore.defaults.data(forKey: key) else { return [] }
    return (try? JSONDecoder().decode([QueuedQuickExpense].self, from: data)) ?? []
  }

  static func save(_ items: [QueuedQuickExpense]) {
    guard let data = try? JSONEncoder().encode(items) else { return }
    MenudoShortcutsSharedStore.defaults.set(data, forKey: key)
    MenudoShortcutsSharedStore.defaults.synchronize()
  }

  static func clear() {
    MenudoShortcutsSharedStore.defaults.removeObject(forKey: key)
    MenudoShortcutsSharedStore.defaults.synchronize()
  }
}

enum QuickExpenseNetworkClient {
  static func post(
    expense: QueuedQuickExpense,
    context: QuickExpenseShortcutRuntimeContext
  ) async throws -> HTTPURLResponse {
    guard let endpoint = URL(string: normalizedBaseUrl(context.apiBaseUrl) + "/transactions") else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(context.authToken)", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 20
    request.httpBody = try JSONSerialization.data(withJSONObject: expense.body.compactMapValues { $0 })

    let (_, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }
    return httpResponse
  }

  static func normalizedBaseUrl(_ raw: String) -> String {
    raw.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
  }

  static func shouldQueue(statusCode: Int) -> Bool {
    statusCode == 408 || statusCode == 429 || statusCode >= 500
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
      MenudoShortcutFeedback.requestNotificationAuthorizationIfNeeded()
      presentShortcutSetup()
      result(nil)
    case "openShortcutsApp":
      openShortcutsApp(result: result)
    case "requestShortcutNotificationAuthorization":
      MenudoShortcutFeedback.requestNotificationAuthorizationIfNeeded()
      result(nil)
    case "previewShortcutFeedback":
      MenudoShortcutFeedback.requestNotificationAuthorizationIfNeeded()
      MenudoShortcutFeedback.expenseSaved(
        amount: 250,
        merchant: "Apple Pay",
        categoryName: "Comida",
        currencyCode: "DOP"
      )
      result(nil)
    case "syncQuickExpenseContext":
      QuickExpenseShortcutContextStore.save(rawPayload: call.arguments)
      result(nil)
    case "clearQuickExpenseContext":
      QuickExpenseShortcutContextStore.clear()
      result(nil)
    case "flushQueuedQuickExpenses":
      Task {
        await self.flushQueuedQuickExpenses()
        result(nil)
      }
    case "consumePendingShortcut":
      result(PendingShortcutStore.consume())
    case "clearPendingShortcut":
      PendingShortcutStore.clear()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func openShortcutsApp(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard let url = URL(string: "shortcuts://") else {
        result(false)
        return
      }

      UIApplication.shared.open(url, options: [:]) { success in
        result(success)
      }
    }
  }

  private func flushQueuedQuickExpenses() async {
    guard let context = QuickExpenseShortcutContextStore.load() else { return }
    let queued = QueuedQuickExpenseStore.load()
    guard !queued.isEmpty else { return }

    let processingQueue = Array(queued.reversed())
    var remaining: [QueuedQuickExpense] = []
    for (index, expense) in processingQueue.enumerated() {
      do {
        let response = try await QuickExpenseNetworkClient.post(
          expense: expense,
          context: context
        )
        if (200 ... 299).contains(response.statusCode) {
          QuickExpenseIdempotencyStore.mark(expense.idempotencyKey)
          continue
        }
        if response.statusCode == 401 || response.statusCode == 403 {
          remaining.append(expense)
          remaining.append(contentsOf: processingQueue.dropFirst(index + 1))
          break
        }
        if QuickExpenseNetworkClient.shouldQueue(statusCode: response.statusCode) {
          remaining.append(expense)
        }
      } catch {
        remaining.append(expense)
      }
    }

    QueuedQuickExpenseStore.save(Array(remaining.reversed()))
    if remaining.count != queued.count {
      print("[shortcuts] flushed \(queued.count - remaining.count) queued quick expenses")
    }
  }

  private func presentShortcutSetup() {
    DispatchQueue.main.async { [weak self] in
      guard let presenter = self?.topViewController() else { return }

      #if canImport(AppIntents)
      if #available(iOS 16.0, *) {
        MenudoAppShortcutsProvider.updateAppShortcutParameters()
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
        message: "Menudo ya publica el App Shortcut “Registrar Gasto”. Puedes verlo en Shortcuts, Siri o Spotlight y enlazarlo a una automatización de Apple Pay sin crear una acción nueva desde cero.",
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
  @State private var displaySiriTip = true

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          VStack(alignment: .leading, spacing: 10) {
            Text("App Shortcut listo")
              .font(.system(size: 28, weight: .bold, design: .rounded))
              .foregroundStyle(Color(red: 0.09, green: 0.36, blue: 0.27))

            Text("“Registrar Gasto” aparece automáticamente con Menudo. Solo enlázalo a Apple Pay cuando iOS te pida elegir una acción.")
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }

          VStack(spacing: 14) {
            SiriTipView(
              intent: QuickExpenseShortcutIntent(),
              isVisible: $displaySiriTip
            )
            .frame(maxWidth: .infinity)

            ShortcutsLink()
              .frame(maxWidth: .infinity)
              .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 10) {
              nativeSimpleStep("1", "Abre Menudo una vez con tu sesión iniciada.")
              nativeSimpleStep("2", "En la automatización de Apple Pay, elige “Registrar Gasto”.")
              nativeSimpleStep("3", "Siri puede pedir monto o categoría sin abrir Flutter.")
              nativeSimpleStep("4", "Opcional: Ajustes > Accesibilidad > Tocar > Toque posterior > Tocar dos veces > Registrar Gasto.")
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
