import Foundation
import SwiftData

@Model
final class RefuelEntry {
    var id: UUID
    var date: Date
    var mileage: Double
    var liters: Double
    var pricePerLiter: Double
    
    init(id: UUID = UUID(), date: Date = Date(), mileage: Double, liters: Double, pricePerLiter: Double) {
        self.id = id
        self.date = date
        self.mileage = mileage
        self.liters = liters
        self.pricePerLiter = pricePerLiter
    }
    
    var totalCost: Double {
        liters * pricePerLiter
    }
    
    // Note: Fuel consumption is calculated using FuelService.calculateConsumptionForEntry()
    // or FuelMath.calculateConsumption() as it requires access to previous entries
}
