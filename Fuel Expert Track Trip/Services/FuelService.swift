import Foundation
import SwiftData

class FuelService {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAllEntries() -> [RefuelEntry] {
        let descriptor = FetchDescriptor<RefuelEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchVehicleInfo() -> VehicleInfo? {
        let descriptor = FetchDescriptor<VehicleInfo>()
        let vehicles = (try? modelContext.fetch(descriptor)) ?? []
        return vehicles.first
    }
    
    func saveVehicleInfo(_ vehicle: VehicleInfo) {
        modelContext.insert(vehicle)
        try? modelContext.save()
    }
    
    func updateVehicleInfo(_ vehicle: VehicleInfo) {
        try? modelContext.save()
    }
    
    func saveEntry(_ entry: RefuelEntry) {
        modelContext.insert(entry)
        try? modelContext.save()
    }
    
    func updateEntry(_ entry: RefuelEntry) {
        try? modelContext.save()
    }
    
    func deleteEntry(_ entry: RefuelEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
    
    func deleteAllEntries() {
        let entries = fetchAllEntries()
        for entry in entries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
    
    func calculateConsumptionForEntry(_ entry: RefuelEntry, allEntries: [RefuelEntry]) -> Double {
        let sortedEntries = allEntries.sorted { $0.date < $1.date }
        guard let currentIndex = sortedEntries.firstIndex(where: { $0.id == entry.id }),
              currentIndex > 0 else {
            return 0.0
        }
        
        let previousEntry = sortedEntries[currentIndex - 1]
        // For now, using metric. In real app, get from settings
        return FuelMath.calculateConsumption(
            currentMileage: entry.mileage,
            previousMileage: previousEntry.mileage,
            liters: entry.liters,
            isMetric: true
        )
    }
}
