import Foundation

struct FuelMath {
    /// Calculate fuel consumption in L/100km or MPG
    static func calculateConsumption(
        currentMileage: Double,
        previousMileage: Double,
        liters: Double,
        isMetric: Bool
    ) -> Double {
        guard currentMileage > previousMileage, liters > 0 else {
            return 0.0
        }
        
        let distance = currentMileage - previousMileage
        
        if isMetric {
            // L/100km
            return (liters / distance) * 100.0
        } else {
            // MPG (miles per gallon)
            let gallons = liters * 0.264172 // Convert liters to gallons
            return distance / gallons
        }
    }
    
    /// Calculate cost per kilometer or mile
    static func calculateCostPerDistance(
        totalCost: Double,
        distance: Double,
        isMetric: Bool
    ) -> Double {
        guard distance > 0 else {
            return 0.0
        }
        
        if isMetric {
            // Cost per km
            return totalCost / distance
        } else {
            // Cost per mile
            return totalCost / distance
        }
    }
    
    /// Format consumption based on units
    static func formatConsumption(_ consumption: Double, isMetric: Bool) -> String {
        if isMetric {
            return String(format: "%.2f L/100km", consumption)
        } else {
            return String(format: "%.2f MPG", consumption)
        }
    }
    
    /// Format distance based on units
    static func formatDistance(_ distance: Double, isMetric: Bool) -> String {
        if isMetric {
            return String(format: "%.1f km", distance)
        } else {
            return String(format: "%.1f miles", distance)
        }
    }
    
    /// Format volume based on units
    static func formatVolume(_ liters: Double, isMetric: Bool) -> String {
        if isMetric {
            return String(format: "%.2f L", liters)
        } else {
            let gallons = liters * 0.264172
            return String(format: "%.2f gal", gallons)
        }
    }
    
    /// Format currency based on currency code
    static func formatCurrency(_ value: Double, currency: String = "USD") -> String {
        let symbol: String
        switch currency {
        case "EUR":
            symbol = "€"
        case "GBP":
            symbol = "£"
        case "RUB":
            symbol = "₽"
        default:
            symbol = "$"
        }
        return String(format: "\(symbol)%.2f", value)
    }
}
