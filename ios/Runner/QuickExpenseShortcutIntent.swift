import UserNotifications
import Foundation

#if canImport(AppIntents)
import AppIntents

private struct ResolvedQuickExpenseCategory {
  let slug: String
  let name: String
}

@available(iOS 16.0, *)
struct ShortcutCategoryEntity: AppEntity, Identifiable, Hashable {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Categoría")
  static let defaultQuery = ShortcutCategoryQuery()

  let id: String
  let slug: String
  let name: String

  init(context: ShortcutCategoryContext) {
    self.id = context.slug
    self.slug = context.slug
    self.name = context.name
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: .init(stringLiteral: name))
  }
}

@available(iOS 16.0, *)
struct ShortcutCategoryQuery: EntityStringQuery {
  func entities(for identifiers: [ShortcutCategoryEntity.ID]) async throws -> [ShortcutCategoryEntity] {
    allCategories().filter { identifiers.contains($0.id) }
  }

  func entities(matching string: String) async throws -> [ShortcutCategoryEntity] {
    let term = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if term.isEmpty { return allCategories() }

    return allCategories().filter {
      $0.name.lowercased().contains(term) || $0.slug.lowercased().contains(term)
    }
  }

  func suggestedEntities() async throws -> [ShortcutCategoryEntity] {
    allCategories()
  }

  private func allCategories() -> [ShortcutCategoryEntity] {
    QuickExpenseShortcutContextStore.load()?.categories
      .map(ShortcutCategoryEntity.init(context:))
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } ?? []
  }
}

@available(iOS 16.0, *)
struct QuickExpenseShortcutIntent: AppIntent {
  static let title: LocalizedStringResource = "Registrar Gasto"
  static let description = IntentDescription(
    "Registra un gasto en Menudo sin abrir la app."
  )
  static var isDiscoverable = true
  static var openAppWhenRun = false

  @Parameter(
    title: "Monto",
    requestValueDialog: "¿Cuánto fue el gasto?"
  )
  var amount: Double

  @Parameter(title: "Comercio")
  var merchant: String?

  @Parameter(
    title: "Categoría",
    requestValueDialog: "¿Qué categoría quieres usar para este gasto?"
  )
  var category: ShortcutCategoryEntity?

  @Parameter(title: "Nota")
  var note: String?

  static var parameterSummary: some ParameterSummary {
    Summary("Registrar un gasto de \(\.$amount)") {
      \.$merchant
      \.$category
      \.$note
    }
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard amount > 0 else {
      throw $amount.needsValueError(IntentDialog("¿Cuánto fue el gasto?"))
    }

    guard let context = QuickExpenseShortcutContextStore.load() else {
      return .result(
        dialog: IntentDialog("Abre Menudo una vez con tu sesión iniciada para preparar este atajo.")
      )
    }

    guard !context.categories.isEmpty else {
      return .result(
        dialog: IntentDialog("Crea o sincroniza una categoría de gasto en Menudo antes de usar este atajo.")
      )
    }

    let merchantName = normalizedMerchant(merchant)
    let resolvedCategory: ResolvedQuickExpenseCategory
    do {
      resolvedCategory = try await resolveCategory(
        merchantName: merchantName,
        context: context
      )
    } catch {
      // If we are in a context where we can show a notification (e.g. background automation)
      // we trigger the interactive notification instead of just failing.
      triggerMissingCategoryNotification(amount: amount, merchant: merchantName, context: context)
      return .result(
        dialog: IntentDialog("Te enviamos una notificación para elegir la categoría de este gasto de \(amount).")
      )
    }
    let idempotencyKey = makeIdempotencyKey(
      amount: amount,
      merchantName: merchantName,
      categorySlug: resolvedCategory.slug,
      walletId: context.defaultWallet.id
    )

    if QuickExpenseIdempotencyStore.contains(idempotencyKey) {
      return .result(dialog: IntentDialog("Ese gasto ya estaba registrado en Menudo."))
    }

    let expense = QueuedQuickExpense(
      idempotencyKey: idempotencyKey,
      fecha: currentDateString(),
      descripcion: merchantName ?? resolvedCategory.name,
      monto: amount,
      tipo: "gasto",
      catKey: resolvedCategory.slug,
      walletId: context.defaultWallet.id,
      nota: normalizedNote(note) ?? merchantName,
      moneda: context.defaultWallet.currency,
      createdAt: ISO8601DateFormatter().string(from: Date())
    )

    do {
      let httpResponse = try await QuickExpenseNetworkClient.post(
        expense: expense,
        context: context
      )

      guard (200 ... 299).contains(httpResponse.statusCode) else {
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
          return .result(
            dialog: IntentDialog("Vuelve a abrir Menudo para actualizar tu sesión.")
          )
        }
        if QuickExpenseNetworkClient.shouldQueue(statusCode: httpResponse.statusCode) {
          QueuedQuickExpenseStore.enqueue(expense)
          return .result(
            dialog: IntentDialog("No había conexión estable. Menudo guardará este gasto cuando vuelva a conectarse.")
          )
        }
        return .result(
          dialog: IntentDialog("No pudimos registrar el gasto. Inténtalo otra vez en un momento.")
        )
      }

      QuickExpenseIdempotencyStore.mark(idempotencyKey)
      return .result(dialog: IntentDialog("Gasto registrado en Menudo."))
    } catch {
      QueuedQuickExpenseStore.enqueue(expense)
      return .result(
        dialog: IntentDialog("No había conexión estable. Menudo guardará este gasto cuando vuelva a conectarse.")
      )
    }
  }

  private func resolveCategory(
    merchantName: String?,
    context: QuickExpenseShortcutRuntimeContext
  ) async throws -> ResolvedQuickExpenseCategory {
    if let category {
      return ResolvedQuickExpenseCategory(slug: category.slug, name: category.name)
    }

    if let merchantName,
       let hinted = categoryHint(for: merchantName, context: context) {
      return hinted
    }

    let requested = try await $category.requestValue(
      IntentDialog("¿Categoría para \(merchantName ?? "este gasto")?")
    )
    return ResolvedQuickExpenseCategory(slug: requested.slug, name: requested.name)
  }

  private func categoryHint(
    for merchantName: String,
    context: QuickExpenseShortcutRuntimeContext
  ) -> ResolvedQuickExpenseCategory? {
    let normalized = Self.normalizedMerchantKey(merchantName)
    guard !normalized.isEmpty else { return nil }

    if let exact = context.merchantHints.first(where: { $0.merchantKey == normalized }) {
      return ResolvedQuickExpenseCategory(slug: exact.categorySlug, name: exact.categoryName)
    }

    let fuzzy = context.merchantHints
      .filter {
        normalized.contains($0.merchantKey) ||
          $0.merchantKey.contains(normalized) ||
          normalized.localizedCaseInsensitiveContains($0.merchantName)
      }
      .sorted {
        if $0.confidence != $1.confidence { return $0.confidence > $1.confidence }
        return $0.count > $1.count
      }
      .first

    if let fuzzy, fuzzy.confidence >= 0.55 {
      return ResolvedQuickExpenseCategory(slug: fuzzy.categorySlug, name: fuzzy.categoryName)
    }

    return nil
  }

  private func currentDateString() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
  }

  private func normalizedNote(_ raw: String?) -> String? {
    let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let value, !value.isEmpty {
      return value
    }
    return nil
  }

  private func normalizedMerchant(_ raw: String?) -> String? {
    let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let value, !value.isEmpty {
      return value
    }
    return nil
  }

  private func makeIdempotencyKey(
    amount: Double,
    merchantName: String?,
    categorySlug: String,
    walletId: Int
  ) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyyMMddHHmm"
    let minuteBucket = formatter.string(from: Date())
    let amountCents = Int((amount * 100).rounded())
    let merchantKey = Self.normalizedMerchantKey(merchantName ?? categorySlug)
    return "\(minuteBucket)-\(walletId)-\(amountCents)-\(merchantKey)-\(categorySlug)"
  }

  private func triggerMissingCategoryNotification(
    amount: Double,
    merchant: String?,
    context: QuickExpenseShortcutRuntimeContext
  ) {
    let content = UNMutableNotificationContent()
    content.title = "Gasto sin categoría"
    content.body = "\(merchant ?? "Nuevo gasto") por \(amount). Toca para elegir categoría."
    content.categoryIdentifier = "EXPENSE_MISSING_CATEGORY"
    content.userInfo = [
      "amount": amount,
      "description": merchant ?? "Gasto vía Atajo",
      "idempotencyKey": makeIdempotencyKey(
        amount: amount,
        merchantName: merchant,
        categorySlug: "pending",
        walletId: context.defaultWallet.id
      )
    ]
    
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    
    UNUserNotificationCenter.current().add(request)
  }

  static func normalizedMerchantKey(_ raw: String) -> String {
    raw
      .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
      .lowercased()
      .components(separatedBy: CharacterSet.alphanumerics.inverted)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }
}

@available(iOS 16.0, *)
struct MenudoAppShortcutsProvider: AppShortcutsProvider {
  @AppShortcutsBuilder
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: QuickExpenseShortcutIntent(),
      phrases: [
        "Registrar gasto en \(.applicationName)",
        "Registrar Gasto en \(.applicationName)",
        "Nuevo gasto en \(.applicationName)",
        "Gasto en \(.applicationName)",
        "Registrar un gasto con \(.applicationName)",
      ],
      shortTitle: "Registrar Gasto",
      systemImageName: "plus.circle.fill"
    )
  }

  static var shortcutTileColor: ShortcutTileColor {
    .orange
  }
}
#endif
