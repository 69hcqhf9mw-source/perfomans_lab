import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: \RefuelEntry.date) private var entries: [RefuelEntry]
    @Query private var settings: [AppSettings]
    @Query private var vehicles: [VehicleInfo]
    
    private var isMetric: Bool {
        settings.first?.isMetric ?? true
    }
    
    private var totalEntries: Int {
        entries.count
    }
    
    private var totalSpent: Double {
        entries.reduce(0) { $0 + $1.totalCost }
    }
    
    private var totalLiters: Double {
        entries.reduce(0) { $0 + $1.liters }
    }
    
    private var averageConsumption: Double {
        guard entries.count > 1 else { return 0.0 }
        // Сортируем по пробегу для правильного расчета потребления
        let sortedEntries = entries.sorted { $0.mileage < $1.mileage }
        var totalConsumption = 0.0
        var validCalculations = 0
        
        for i in 1..<sortedEntries.count {
            let current = sortedEntries[i]
            let previous = sortedEntries[i - 1]
            
            // Проверяем, что пробег увеличился
            guard current.mileage > previous.mileage else { continue }
            
            let consumption = FuelMath.calculateConsumption(
                currentMileage: current.mileage,
                previousMileage: previous.mileage,
                liters: current.liters,
                isMetric: isMetric
            )
            if consumption > 0 {
                totalConsumption += consumption
                validCalculations += 1
            }
        }
        
        return validCalculations > 0 ? totalConsumption / Double(validCalculations) : 0.0
    }
    
    private var bestConsumption: Double {
        guard entries.count > 1 else { return 0.0 }
        // Сортируем по пробегу для правильного расчета потребления
        let sortedEntries = entries.sorted { $0.mileage < $1.mileage }
        var best = Double.greatestFiniteMagnitude
        
        for i in 1..<sortedEntries.count {
            let current = sortedEntries[i]
            let previous = sortedEntries[i - 1]
            
            // Проверяем, что пробег увеличился
            guard current.mileage > previous.mileage else { continue }
            
            let consumption = FuelMath.calculateConsumption(
                currentMileage: current.mileage,
                previousMileage: previous.mileage,
                liters: current.liters,
                isMetric: isMetric
            )
            if consumption > 0 && consumption < best {
                best = consumption
            }
        }
        
        return best == Double.greatestFiniteMagnitude ? 0.0 : best
    }
    
    private var worstConsumption: Double {
        guard entries.count > 1 else { return 0.0 }
        // Сортируем по пробегу для правильного расчета потребления
        let sortedEntries = entries.sorted { $0.mileage < $1.mileage }
        var worst = 0.0
        
        for i in 1..<sortedEntries.count {
            let current = sortedEntries[i]
            let previous = sortedEntries[i - 1]
            
            // Проверяем, что пробег увеличился
            guard current.mileage > previous.mileage else { continue }
            
            let consumption = FuelMath.calculateConsumption(
                currentMileage: current.mileage,
                previousMileage: previous.mileage,
                liters: current.liters,
                isMetric: isMetric
            )
            if consumption > worst {
                worst = consumption
            }
        }
        
        return worst
    }
    
    private var totalDistance: Double {
        guard entries.count > 1 else { return 0.0 }
        // Сортируем по пробегу для правильного расчета расстояния
        let sortedEntries = entries.sorted { $0.mileage < $1.mileage }
        
        // Суммируем все валидные расстояния между последовательными записями
        var totalDistance = 0.0
        for i in 1..<sortedEntries.count {
            let current = sortedEntries[i]
            let previous = sortedEntries[i - 1]
            
            // Учитываем только случаи, когда пробег увеличился
            if current.mileage > previous.mileage {
                totalDistance += (current.mileage - previous.mileage)
            }
        }
        
        return totalDistance
    }
    
    private var averagePrice: Double {
        guard !entries.isEmpty else { return 0.0 }
        return entries.reduce(0) { $0 + $1.pricePerLiter } / Double(entries.count)
    }
    
    private var costPerDistance: Double {
        guard totalDistance > 0 else { return 0.0 }
        return totalSpent / totalDistance
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if entries.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No Statistics Available",
                        message: "Add refuel entries to see detailed statistics and insights."
                    )
                } else {
                    // Overview Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Total Entries",
                            value: "\(totalEntries)",
                            icon: "list.number",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Spent",
                            value: FuelMath.formatCurrency(totalSpent, currency: settings.first?.currency ?? "USD"),
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Total Distance",
                            value: FuelMath.formatDistance(totalDistance, isMetric: isMetric),
                            icon: "road.lanes",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Total Fuel",
                            value: FuelMath.formatVolume(totalLiters, isMetric: isMetric),
                            icon: "fuelpump.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                    
                    // Consumption Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fuel Consumption")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            StatRow(
                                label: "Average",
                                value: FuelMath.formatConsumption(averageConsumption, isMetric: isMetric),
                                icon: "chart.line.uptrend.xyaxis"
                            )
                            
                            if bestConsumption > 0 {
                                StatRow(
                                    label: "Best",
                                    value: FuelMath.formatConsumption(bestConsumption, isMetric: isMetric),
                                    icon: "star.fill",
                                    color: .green
                                )
                            }
                            
                            if worstConsumption > 0 {
                                StatRow(
                                    label: "Worst",
                                    value: FuelMath.formatConsumption(worstConsumption, isMetric: isMetric),
                                    icon: "exclamationmark.triangle.fill",
                                    color: .red
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Cost Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cost Analysis")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            StatRow(
                                label: "Average Price",
                                value: FuelMath.formatCurrency(averagePrice, currency: settings.first?.currency ?? "USD"),
                                icon: "tag.fill"
                            )
                            
                            StatRow(
                                label: "Cost per \(isMetric ? "km" : "mile")",
                                value: FuelMath.formatCurrency(costPerDistance, currency: settings.first?.currency ?? "USD"),
                                icon: "dollarsign.circle"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Insights
                    if entries.count >= 5 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Insights")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            InsightCard(
                                icon: "lightbulb.fill",
                                title: "Tracking Progress",
                                message: "You've tracked \(totalEntries) refuel entries. Keep it up!",
                                color: .yellow
                            )
                            
                            if averageConsumption > 0 {
                                InsightCard(
                                    icon: "chart.bar.fill",
                                    title: "Consumption Trend",
                                    message: "Your average consumption is \(FuelMath.formatConsumption(averageConsumption, isMetric: isMetric)).",
                                    color: .blue
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = .accentColor
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
