import Foundation
import SwiftData

@Model
final class VehicleInfo {
    var brand: String
    var model: String
    var year: Int
    var tankCapacity: Double
    
    init(brand: String = "", model: String = "", year: Int = Calendar.current.component(.year, from: Date()), tankCapacity: Double = 0.0) {
        self.brand = brand
        self.model = model
        self.year = year
        self.tankCapacity = tankCapacity
    }
    
    var displayName: String {
        if brand.isEmpty && model.isEmpty {
            return "My Vehicle"
        }
        return "\(brand) \(model)".trimmingCharacters(in: .whitespaces)
    }
}
