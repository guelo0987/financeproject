import SwiftUI
import WidgetKit

private struct MenudoFinanceSnapshot {
  let balanceText: String
  let balanceLabel: String
  let lastExpenseTitle: String
  let lastExpenseAmountText: String
  let lastExpenseSubtitle: String
  let updatedAt: String

  static let placeholder = MenudoFinanceSnapshot(
    balanceText: "RD$0",
    balanceLabel: "Patrimonio actual",
    lastExpenseTitle: "Sin gastos recientes",
    lastExpenseAmountText: "Listo",
    lastExpenseSubtitle: "Abre Menudo para actualizar",
    updatedAt: ""
  )

  static func load() -> MenudoFinanceSnapshot {
    let defaults = UserDefaults(suiteName: "group.com.miguelcruz.financeapp")
    guard let raw = defaults?.dictionary(forKey: "menudo.widget.snapshot") else {
      return placeholder
    }

    return MenudoFinanceSnapshot(
      balanceText: raw["balanceText"] as? String ?? placeholder.balanceText,
      balanceLabel: raw["balanceLabel"] as? String ?? placeholder.balanceLabel,
      lastExpenseTitle: raw["lastExpenseTitle"] as? String ?? placeholder.lastExpenseTitle,
      lastExpenseAmountText: raw["lastExpenseAmountText"] as? String ?? placeholder.lastExpenseAmountText,
      lastExpenseSubtitle: raw["lastExpenseSubtitle"] as? String ?? placeholder.lastExpenseSubtitle,
      updatedAt: raw["updatedAt"] as? String ?? ""
    )
  }
}

private struct MenudoFinanceEntry: TimelineEntry {
  let date: Date
  let snapshot: MenudoFinanceSnapshot
}

private struct MenudoFinanceProvider: TimelineProvider {
  func placeholder(in context: Context) -> MenudoFinanceEntry {
    MenudoFinanceEntry(date: Date(), snapshot: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (MenudoFinanceEntry) -> Void) {
    completion(MenudoFinanceEntry(date: Date(), snapshot: MenudoFinanceSnapshot.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<MenudoFinanceEntry>) -> Void) {
    let entry = MenudoFinanceEntry(date: Date(), snapshot: MenudoFinanceSnapshot.load())
    let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }
}

struct MenudoFinanceSummaryWidget: Widget {
  let kind = "MenudoFinanceSummaryWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MenudoFinanceProvider()) { entry in
      MenudoFinanceSummaryView(entry: entry)
        .menudoWidgetBackground()
    }
    .configurationDisplayName("Balance de Menudo")
    .description("Mira tu patrimonio y tu último gasto sin abrir la app.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

private extension View {
  @ViewBuilder
  func menudoWidgetBackground() -> some View {
    let background = LinearGradient(
      colors: [
        Color(red: 0.06, green: 0.23, blue: 0.18),
        Color(red: 0.96, green: 0.47, blue: 0.18)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )

    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) {
        background
      }
    } else {
      self.background(background)
    }
  }
}

private struct MenudoFinanceSummaryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: MenudoFinanceEntry

  var body: some View {
    switch family {
    case .systemMedium:
      mediumView
    default:
      smallView
    }
  }

  private var smallView: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
      Spacer(minLength: 2)
      Text(entry.snapshot.balanceText)
        .font(.system(size: 25, weight: .heavy, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.62)
      Text(entry.snapshot.lastExpenseTitle)
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.white.opacity(0.78))
        .lineLimit(1)
      Text(entry.snapshot.lastExpenseAmountText)
        .font(.system(size: 13, weight: .heavy, design: .rounded))
        .foregroundStyle(Color(red: 1.0, green: 0.89, blue: 0.72))
        .lineLimit(1)
    }
    .padding(15)
  }

  private var mediumView: some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        header
        Spacer(minLength: 4)
        Text(entry.snapshot.balanceText)
          .font(.system(size: 30, weight: .heavy, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.65)
        Text(entry.snapshot.balanceLabel)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.white.opacity(0.76))
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Último gasto")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.white.opacity(0.72))
        Text(entry.snapshot.lastExpenseTitle)
          .font(.system(size: 16, weight: .heavy, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(2)
          .minimumScaleFactor(0.8)
        Text(entry.snapshot.lastExpenseAmountText)
          .font(.system(size: 17, weight: .heavy, design: .rounded))
          .foregroundStyle(Color(red: 1.0, green: 0.89, blue: 0.72))
          .lineLimit(1)
        Text(entry.snapshot.lastExpenseSubtitle)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(.white.opacity(0.68))
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(16)
  }

  private var header: some View {
    HStack(spacing: 7) {
      Image(systemName: "wallet.pass.fill")
        .font(.system(size: 14, weight: .bold))
      Text("Menudo")
        .font(.system(size: 13, weight: .heavy, design: .rounded))
    }
    .foregroundStyle(.white.opacity(0.92))
  }
}
