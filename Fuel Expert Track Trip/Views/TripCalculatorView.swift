import SwiftUI
import SwiftData

struct TripCalculatorView: View {
    @Query(sort: \RefuelEntry.date, order: .reverse) private var entries: [RefuelEntry]
    @Query private var settings: [AppSettings]
    @State private var distance: String = ""
    @State private var avgConsumption: String = ""
    
    private var isMetric: Bool {
        settings.first?.isMetric ?? true
    }
    
    private var averagePrice: Double {
        guard !entries.isEmpty else { return 1.5 } // Default price
        let totalPrice = entries.reduce(0.0) { $0 + $1.pricePerLiter }
        return totalPrice / Double(entries.count)
    }
    
    private var requiredFuel: Double {
        guard let distanceValue = Double(distance),
              let consumptionValue = Double(avgConsumption),
              distanceValue > 0,
              consumptionValue > 0 else {
            return 0.0
        }
        
        if isMetric {
            // L/100km format
            return (distanceValue / 100.0) * consumptionValue
        } else {
            // MPG format
            let gallons = distanceValue / consumptionValue
            return gallons * 3.78541 // Convert to liters
        }
    }
    
    private var estimatedCost: Double {
        guard requiredFuel > 0 else { return 0.0 }
        return requiredFuel * averagePrice
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField(isMetric ? "km" : "miles", text: $distance)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Avg Consumption")
                        Spacer()
                        TextField(isMetric ? "L/100km" : "MPG", text: $avgConsumption)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Trip Details")
                }
                
                Section {
                    HStack {
                        Text("Required Fuel")
                        Spacer()
                        Text(FuelMath.formatVolume(requiredFuel, isMetric: isMetric))
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                    
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text(FuelMath.formatCurrency(estimatedCost, currency: settings.first?.currency ?? "USD"))
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                } header: {
                    Text("Results")
                }
            }
            .navigationTitle("Trip Calculator")
        }
    }
}
