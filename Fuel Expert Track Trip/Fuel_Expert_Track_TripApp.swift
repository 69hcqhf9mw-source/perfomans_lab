import SwiftUI
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.fuelexpert", category: "App")

@main
struct Fuel_Expert_Track_TripApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    let modelContainer: ModelContainer
    
    init() {
        logger.info("🚀 App initializing...")
        
        do {
            let schema = Schema([
                RefuelEntry.self,
                VehicleInfo.self,
                AppSettings.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            logger.info("✅ ModelContainer created successfully")
            
            // Log the database path
            if let url = modelContainer.configurations.first?.url {
                logger.info("📁 Database path: \(url.path)")
            }
            
        } catch {
            logger.error("❌ Failed to create ModelContainer: \(error.localizedDescription)")
            logger.error("🔄 Attempting to delete old database and recreate...")
            
            // Try to delete the old database and recreate
            do {
                // Delete existing store
                let fileManager = FileManager.default
                let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                let storeURL = appSupport.appendingPathComponent("default.store")
                
                if fileManager.fileExists(atPath: storeURL.path) {
                    try fileManager.removeItem(at: storeURL)
                    logger.info("🗑️ Old database deleted")
                }
                
                // Also try to delete .sqlite files
                let contents = try? fileManager.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil)
                for url in contents ?? [] {
                    if url.lastPathComponent.contains("default") || url.pathExtension == "sqlite" {
                        try? fileManager.removeItem(at: url)
                    }
                }
                
                // Recreate container
                let schema = Schema([
                    RefuelEntry.self,
                    VehicleInfo.self,
                    AppSettings.self
                ])
                
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
                
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                
                logger.info("✅ ModelContainer recreated successfully after cleanup")
                
            } catch {
                logger.error("❌ Failed to recreate ModelContainer: \(error.localizedDescription)")
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    logger.info("📱 MainTabView appeared")
                }
        }
        .modelContainer(modelContainer)
    }
}
