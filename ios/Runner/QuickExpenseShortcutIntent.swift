import Foundation

#if canImport(AppIntents)
import AppIntents

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
  static let title: LocalizedStringResource = "Registrar gasto rápido"
  static let description = IntentDescription(
    "Registra un gasto en Menudo sin abrir la app."
  )

  @Parameter(title: "Monto")
  var amount: Double

  @Parameter(title: "Categoría")
  var category: ShortcutCategoryEntity

  @Parameter(title: "Nota")
  var note: String?

  static var parameterSummary: some ParameterSummary {
    Summary("Registrar un gasto de \(\.$amount) en \(\.$category)")
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard amount > 0 else {
      return .result(dialog: "Escribe un monto mayor que cero.")
    }

    guard let context = QuickExpenseShortcutContextStore.load() else {
      return .result(dialog: "Abre Menudo una vez para preparar este atajo.")
    }

    guard let endpoint = URL(string: normalizedBaseUrl(context.apiBaseUrl) + "/transactions") else {
      return .result(dialog: "No pudimos preparar el gasto rápido.")
    }

    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(context.authToken)", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 20

    let payload: [String: Any?] = [
      "fecha": currentDateString(),
      "descripcion": category.name,
      "monto": amount,
      "tipo": "gasto",
      "budgetId": nil,
      "catKey": category.slug,
      "walletId": context.defaultWallet.id,
      "nota": normalizedNote(note),
      "moneda": context.defaultWallet.currency,
    ]

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 })
      let (_, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        return .result(dialog: "No pudimos confirmar el gasto.")
      }

      guard (200 ... 299).contains(httpResponse.statusCode) else {
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
          return .result(dialog: "Vuelve a abrir Menudo para actualizar tu sesión.")
        }
        return .result(dialog: "No pudimos registrar el gasto.")
      }

      return .result(dialog: "Gasto registrado.")
    } catch {
      return .result(dialog: "No pudimos registrar el gasto.")
    }
  }

  private func normalizedBaseUrl(_ raw: String) -> String {
    raw.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
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
}

@available(iOS 16.0, *)
struct MenudoAppShortcutsProvider: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    let shortcut = AppShortcut(
      intent: QuickExpenseShortcutIntent(),
      phrases: [
        "Registrar gasto rápido en \(.applicationName)",
        "Nuevo gasto en \(.applicationName)",
        "Gasto rápido en \(.applicationName)",
      ],
      shortTitle: "Gasto rápido",
      systemImageName: "plus.circle.fill"
    )

    return [shortcut]
  }
}
#endif
