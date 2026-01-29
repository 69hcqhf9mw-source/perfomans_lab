import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge")
                }
            
            FuelLogView()
                .tabItem {
                    Label("Fuel Log", systemImage: "list.bullet")
                }
            
            TripCalculatorView()
                .tabItem {
                    Label("Calculator", systemImage: "sum")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
            updateTheme()
        }
        .onChange(of: settings.first?.themeMode) { _, _ in
            updateTheme()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ThemeChanged"))) { _ in
            updateTheme()
        }
    }
    
    private func updateTheme() {
        if let settings = settings.first {
            themeManager.updateTheme(from: settings)
        }
    }
}
