
import SwiftUI
import SwiftData

// This file is kept for compatibility but MainTabView is now the root view
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RefuelEntry.self, VehicleInfo.self, AppSettings.self], inMemory: true)
}
