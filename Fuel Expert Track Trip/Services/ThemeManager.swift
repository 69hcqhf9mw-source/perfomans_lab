import SwiftUI
import SwiftData
import Combine

@MainActor
class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme?
    
    func updateTheme(from settings: AppSettings) {
        switch settings.themeMode {
        case "light":
            colorScheme = .light
        case "dark":
            colorScheme = .dark
        default:
            colorScheme = nil // System
        }
    }
}
