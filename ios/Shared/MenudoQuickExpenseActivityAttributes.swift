import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct MenudoQuickExpenseActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    let status: String
    let savedAt: Date
    let isQueued: Bool
  }

  let amount: Double
  let merchant: String
  let categoryName: String
  let currencyCode: String
}
#endif
