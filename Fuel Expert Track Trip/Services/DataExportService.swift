import Foundation
import SwiftData

class DataExportService {
    static func exportToCSV(entries: [RefuelEntry]) -> String {
        var csv = "Date,Mileage,Liters,Price per Liter,Total Cost\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for entry in entries.sorted(by: { $0.date < $1.date }) {
            let dateString = formatter.string(from: entry.date)
            csv += "\(dateString),\(entry.mileage),\(entry.liters),\(entry.pricePerLiter),\(entry.totalCost)\n"
        }
        
        return csv
    }
    
    static func exportToJSON(entries: [RefuelEntry], vehicle: VehicleInfo?) -> Data? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let entriesData = entries.map { entry in
            [
                "id": entry.id.uuidString,
                "date": formatter.string(from: entry.date),
                "mileage": entry.mileage,
                "liters": entry.liters,
                "pricePerLiter": entry.pricePerLiter,
                "totalCost": entry.totalCost
            ] as [String: Any]
        }
        
        var json: [String: Any] = [
            "exportDate": formatter.string(from: Date()),
            "entries": entriesData
        ]
        
        if let vehicle = vehicle {
            json["vehicle"] = [
                "brand": vehicle.brand,
                "model": vehicle.model,
                "year": vehicle.year,
                "tankCapacity": vehicle.tankCapacity
            ]
        }
        
        return try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }
}
