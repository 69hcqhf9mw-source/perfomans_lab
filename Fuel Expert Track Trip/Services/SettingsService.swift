import Foundation
import SwiftData

class SettingsService {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchSettings() -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        let settings = (try? modelContext.fetch(descriptor)) ?? []
        
        if let existing = settings.first {
            return existing
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            return newSettings
        }
    }
    
    func updateSettings(_ settings: AppSettings) {
        try? modelContext.save()
    }
}
