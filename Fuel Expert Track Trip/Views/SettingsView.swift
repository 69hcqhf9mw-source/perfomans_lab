import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @State private var showResetAlert = false
    @State private var showAbout = false
    
    private var appSettings: AppSettings {
        if let existing = settings.first {
            return existing
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            return newSettings
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: VehicleInfoView()) {
                        HStack {
                            Image(systemName: "car.fill")
                            Text("Vehicle Information")
                        }
                    }
                    
                    NavigationLink(destination: AnalyticsView()) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Analytics")
                        }
                    }
                }
                
                Section {
                    Toggle(isOn: Binding(
                        get: { appSettings.isMetric },
                        set: { newValue in
                            appSettings.isMetric = newValue
                            try? modelContext.save()
                        }
                    )) {
                        HStack {
                            Image(systemName: "ruler.fill")
                            Text("Units")
                        }
                    }
                    
                    NavigationLink(destination: CurrencyPickerView(selectedCurrency: Binding(
                        get: { appSettings.currency },
                        set: { newValue in
                            appSettings.currency = newValue
                            try? modelContext.save()
                        }
                    ))) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                            Text("Currency")
                            Spacer()
                            Text(appSettings.currency)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: ThemePickerView(selectedTheme: Binding(
                        get: { appSettings.themeMode },
                        set: { newValue in
                            appSettings.themeMode = newValue
                            try? modelContext.save()
                            // Update theme immediately
                            NotificationCenter.default.post(name: .init("ThemeChanged"), object: nil)
                        }
                    ))) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                            Text("Appearance")
                            Spacer()
                            Text(themeDisplayName(appSettings.themeMode))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Preferences")
                }
                
                Section {
                    NavigationLink(destination: ExportDataView()) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("Export Data")
                        }
                    }
                    
                    NavigationLink(destination: StatisticsView()) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Statistics & Insights")
                        }
                    }
                } header: {
                    Text("Data & Analytics")
                }
                
                Section {
                    Button(action: {
                        showAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("About App")
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset All Data")
                        }
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will permanently delete all refuel entries and vehicle information. This action cannot be undone.")
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("Are you sure you want to delete all data? This action cannot be undone.")
            }
            .sheet(isPresented: $showAbout) {
                NavigationStack {
                    AboutView()
                }
            }
        }
    }
    
    private func resetAllData() {
        // Delete all refuel entries
        let entryDescriptor = FetchDescriptor<RefuelEntry>()
        if let entries = try? modelContext.fetch(entryDescriptor) {
            for entry in entries {
                modelContext.delete(entry)
            }
        }
        
        // Delete vehicle info
        let vehicleDescriptor = FetchDescriptor<VehicleInfo>()
        if let vehicles = try? modelContext.fetch(vehicleDescriptor) {
            for vehicle in vehicles {
                modelContext.delete(vehicle)
            }
        }
        
        // Reset settings to default
        if let settings = settings.first {
            settings.isMetric = true
            settings.currency = "USD"
            settings.themeMode = "system"
        }
        
        try? modelContext.save()
    }
    
    private func themeDisplayName(_ theme: String) -> String {
        switch theme {
        case "light":
            return "Light"
        case "dark":
            return "Dark"
        default:
            return "System"
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Fuel Expert")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track & Trip")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Version")
                        .font(.headline)
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("Description")
                        .font(.headline)
                    Text("Fuel Expert helps you track your vehicle's fuel consumption, manage refuel entries, calculate trip costs, and analyze your spending patterns.")
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("Features")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "list.bullet", text: "Track all refuel entries")
                        FeatureRow(icon: "calculator", text: "Calculate trip costs")
                        FeatureRow(icon: "chart.bar", text: "View consumption analytics")
                        FeatureRow(icon: "car.fill", text: "Manage vehicle information")
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(text)
        }
    }
}

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) private var dismiss
    
    private let currencies = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("RUB", "₽", "Russian Ruble")
    ]
    
    var body: some View {
        List {
            ForEach(currencies, id: \.0) { currency in
                Button(action: {
                    selectedCurrency = currency.0
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(currency.1) \(currency.0)")
                                .font(.headline)
                            Text(currency.2)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedCurrency == currency.0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }
}
