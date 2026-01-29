import Foundation
import SwiftData

@Model
final class AppSettings {
    var isMetric: Bool
    var currency: String
    var themeMode: String // "light", "dark", "system"
    
    init(isMetric: Bool = true, currency: String = "USD", themeMode: String = "system") {
        self.isMetric = isMetric
        self.currency = currency
        self.themeMode = themeMode
    }
}
