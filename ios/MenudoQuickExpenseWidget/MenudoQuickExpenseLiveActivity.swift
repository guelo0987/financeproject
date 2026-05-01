import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 16.1, *)
struct MenudoQuickExpenseLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: MenudoQuickExpenseActivityAttributes.self) { context in
      HStack(spacing: 12) {
        Image(systemName: context.state.isQueued ? "clock.fill" : "checkmark.circle.fill")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(context.state.isQueued ? Color.orange : Color(red: 0.09, green: 0.56, blue: 0.36))

        VStack(alignment: .leading, spacing: 3) {
          Text(context.state.status)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)

          Text(context.attributes.merchant)
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 8)

        Text(amountText(context.attributes.amount, currency: context.attributes.currencyCode))
          .font(.system(size: 15, weight: .heavy, design: .rounded))
          .foregroundStyle(Color(red: 0.92, green: 0.36, blue: 0.12))
          .lineLimit(1)
          .minimumScaleFactor(0.76)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .activityBackgroundTint(Color(red: 0.98, green: 0.97, blue: 0.94))
      .activitySystemActionForegroundColor(Color(red: 0.92, green: 0.36, blue: 0.12))
      .widgetURL(URL(string: "menudo://shortcut/quick-expense"))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          VStack(alignment: .leading, spacing: 4) {
            Label(
              context.state.status,
              systemImage: context.state.isQueued ? "clock.fill" : "checkmark.circle.fill"
            )
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(context.state.isQueued ? Color.orange : Color.green)

            Text(context.attributes.categoryName)
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        DynamicIslandExpandedRegion(.trailing) {
          Text(amountText(context.attributes.amount, currency: context.attributes.currencyCode))
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.orange)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }

        DynamicIslandExpandedRegion(.bottom) {
          Text(context.attributes.merchant)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      } compactLeading: {
        Image(systemName: context.state.isQueued ? "clock.fill" : "checkmark.circle.fill")
          .foregroundStyle(context.state.isQueued ? Color.orange : Color.green)
      } compactTrailing: {
        Text(shortAmountText(context.attributes.amount, currency: context.attributes.currencyCode))
          .font(.system(size: 12, weight: .bold, design: .rounded))
          .foregroundStyle(Color.orange)
          .minimumScaleFactor(0.7)
      } minimal: {
        Image(systemName: context.state.isQueued ? "clock.fill" : "checkmark")
          .foregroundStyle(context.state.isQueued ? Color.orange : Color.green)
      }
      .widgetURL(URL(string: "menudo://shortcut/quick-expense"))
      .keylineTint(Color.orange)
    }
  }

  private func amountText(_ amount: Double, currency: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2

    if currency.uppercased() == "DOP" {
      formatter.locale = Locale(identifier: "en_US")
      formatter.currencySymbol = "RD$"
    }

    return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(amount)"
  }

  private func shortAmountText(_ amount: Double, currency: String) -> String {
    let rounded = amount >= 100 ? Int(amount.rounded()) : Int(amount)
    if currency.uppercased() == "DOP" {
      return "RD$\(rounded)"
    }
    return "\(currency.uppercased()) \(rounded)"
  }
}
