import Foundation
import UserNotifications

#if canImport(ActivityKit)
import ActivityKit
#endif

enum MenudoShortcutFeedback {
  static func requestNotificationAuthorizationIfNeeded() {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      switch settings.authorizationStatus {
      case .notDetermined:
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
      default:
        break
      }
    }
  }

  static func expenseSaved(
    amount: Double,
    merchant: String?,
    categoryName: String,
    currencyCode: String,
    queued: Bool = false,
    displayDuration: TimeInterval = 30
  ) async {
    scheduleNotification(
      amount: amount,
      merchant: merchant,
      categoryName: categoryName,
      currencyCode: currencyCode,
      queued: queued
    )
    await startLiveActivity(
      amount: amount,
      merchant: merchant,
      categoryName: categoryName,
      currencyCode: currencyCode,
      queued: queued,
      displayDuration: displayDuration
    )
  }

  private static func scheduleNotification(
    amount: Double,
    merchant: String?,
    categoryName: String,
    currencyCode: String,
    queued: Bool
  ) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      let authorized = settings.authorizationStatus == .authorized ||
        settings.authorizationStatus == .provisional

      guard authorized else {
        if settings.authorizationStatus == .notDetermined {
          requestNotificationAuthorizationIfNeeded()
        }
        return
      }

      let content = UNMutableNotificationContent()
      content.title = queued ? "Gasto preparado" : "Gasto registrado"
      content.body = notificationBody(
        amount: amount,
        merchant: merchant,
        categoryName: categoryName,
        currencyCode: currencyCode,
        queued: queued
      )
      content.sound = nil
      if #available(iOS 15.0, *) {
        content.interruptionLevel = .passive
      }

      let request = UNNotificationRequest(
        identifier: "menudo.shortcut.feedback.\(UUID().uuidString)",
        content: content,
        trigger: nil
      )
      center.add(request)
    }
  }

  private static func notificationBody(
    amount: Double,
    merchant: String?,
    categoryName: String,
    currencyCode: String,
    queued: Bool
  ) -> String {
    let place = normalizedText(merchant) ?? categoryName
    let amountText = formattedAmount(amount, currencyCode: currencyCode)
    if queued {
      return "\(amountText) en \(place). Menudo lo sincronizará cuando vuelva la conexión."
    }
    return "\(amountText) en \(place) quedó guardado."
  }

  private static func normalizedText(_ raw: String?) -> String? {
    let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let value, !value.isEmpty { return value }
    return nil
  }

  static func formattedAmount(_ amount: Double, currencyCode: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2

    if currencyCode.uppercased() == "DOP" {
      formatter.locale = Locale(identifier: "en_US")
      formatter.currencySymbol = "RD$"
    }

    return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyCode) \(amount)"
  }

  private static func startLiveActivity(
    amount: Double,
    merchant: String?,
    categoryName: String,
    currencyCode: String,
    queued: Bool,
    displayDuration: TimeInterval
  ) async {
    #if canImport(ActivityKit)
    if #available(iOS 16.2, *) {
      guard ActivityAuthorizationInfo().areActivitiesEnabled else {
        print("[shortcuts] live activity skipped: activities disabled")
        return
      }

      let attributes = MenudoQuickExpenseActivityAttributes(
        amount: amount,
        merchant: normalizedText(merchant) ?? categoryName,
        categoryName: categoryName,
        currencyCode: currencyCode
      )
      let initialState = MenudoQuickExpenseActivityAttributes.ContentState(
        status: queued ? "Pendiente" : "Procesando",
        savedAt: Date(),
        isQueued: queued
      )
      let finalState = MenudoQuickExpenseActivityAttributes.ContentState(
        status: queued ? "Pendiente" : "Guardado",
        savedAt: Date(),
        isQueued: queued
      )
      let content = ActivityContent(
        state: initialState,
        staleDate: Date().addingTimeInterval(max(displayDuration + 45, 120))
      )

      do {
        for activity in Activity<MenudoQuickExpenseActivityAttributes>.activities {
          await activity.end(nil, dismissalPolicy: .immediate)
        }

        let activity: Activity<MenudoQuickExpenseActivityAttributes>
        if #available(iOS 18.0, *), !queued {
          do {
            activity = try Activity.request(
              attributes: attributes,
              content: content,
              pushType: nil,
              style: .transient
            )
          } catch {
            activity = try Activity.request(
              attributes: attributes,
              content: content,
              pushType: nil
            )
          }
        } else {
          activity = try Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
          )
        }
        if !queued {
          try? await Task.sleep(nanoseconds: 850_000_000)
          await activity.update(
            ActivityContent(
              state: finalState,
              staleDate: Date().addingTimeInterval(max(displayDuration + 45, 120))
            )
          )
        }

        Task.detached(priority: .background) {
          let seconds = UInt64(max(displayDuration, 12) * 1_000_000_000)
          try? await Task.sleep(nanoseconds: seconds)
          await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .after(Date().addingTimeInterval(10))
          )
        }
      } catch {
        print("[shortcuts] live activity failed: \(error.localizedDescription)")
      }
    }
    #endif
  }
}

enum QuickExpenseNotificationCategoryRegistry {
  static func register() {
    let choices = notificationChoices()
    let actions = choices.map { choice in
      UNNotificationAction(
        identifier: "CAT_\(choice.slug)",
        title: choice.name,
        options: []
      )
    }

    let category = UNNotificationCategory(
      identifier: "EXPENSE_MISSING_CATEGORY",
      actions: actions,
      intentIdentifiers: [],
      options: .customDismissAction
    )

    UNUserNotificationCenter.current().setNotificationCategories([category])
  }

  private static func notificationChoices() -> [ShortcutCategoryContext] {
    if let context = QuickExpenseShortcutContextStore.load() {
      let frequent = Array(context.frequentCategories.prefix(4))
      if !frequent.isEmpty { return frequent }

      let categories = Array(context.categories.prefix(4))
      if !categories.isEmpty { return categories }
    }

    return [
      ShortcutCategoryContext(slug: "comida", name: "Comida", icon: nil),
      ShortcutCategoryContext(slug: "compras", name: "Compras", icon: nil),
      ShortcutCategoryContext(slug: "transporte", name: "Transporte", icon: nil),
      ShortcutCategoryContext(slug: "varios", name: "Otros", icon: nil),
    ]
  }
}
