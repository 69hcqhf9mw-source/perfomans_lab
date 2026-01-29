import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \RefuelEntry.date) private var entries: [RefuelEntry]
    @Query private var settings: [AppSettings]
    
    private var isMetric: Bool {
        settings.first?.isMetric ?? true
    }
    
    private var currency: String {
        settings.first?.currency ?? "USD"
    }
    
    private var consumptionData: [ConsumptionDataPoint] {
        guard entries.count > 1 else { return [] }
        // Сортируем по пробегу для правильного расчета потребления
        let sortedEntries = entries.sorted { $0.mileage < $1.mileage }
        var dataPoints: [ConsumptionDataPoint] = []
        
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
                dataPoints.append(ConsumptionDataPoint(
                    date: current.date,
                    consumption: consumption
                ))
            }
        }
        
        return dataPoints
    }
    
    private var monthlySpending: [MonthlySpending] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .month, for: entry.date)?.start ?? entry.date
        }
        
        return grouped.map { date, entries in
            MonthlySpending(
                month: date,
                amount: entries.reduce(0) { $0 + $1.totalCost }
            )
        }.sorted { $0.month < $1.month }
    }
    
    private var priceTrendData: [PriceDataPoint] {
        entries.sorted { $0.date < $1.date }.map { entry in
            PriceDataPoint(date: entry.date, price: entry.pricePerLiter)
        }
    }
    
    private var totalDistance: Double {
        guard entries.count > 1 else { return 0.0 }
        // Сортируем по пробегу для правильного расчета расстояния
        let sorted = entries.sorted { $0.mileage < $1.mileage }
        
        // Суммируем все валидные расстояния между последовательными записями
        var totalDistance = 0.0
        for i in 1..<sorted.count {
            let current = sorted[i]
            let previous = sorted[i - 1]
            
            // Учитываем только случаи, когда пробег увеличился
            if current.mileage > previous.mileage {
                totalDistance += (current.mileage - previous.mileage)
            }
        }
        
        return totalDistance
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
    
    private var averagePrice: Double {
        guard !entries.isEmpty else { return 0.0 }
        return entries.reduce(0) { $0 + $1.pricePerLiter } / Double(entries.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Cards
                    if !entries.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            SummaryCard(
                                title: "Total Distance",
                                value: FuelMath.formatDistance(totalDistance, isMetric: isMetric),
                                icon: "road.lanes",
                                color: .blue
                            )
                            
                            SummaryCard(
                                title: "Total Spent",
                                value: FuelMath.formatCurrency(totalSpent, currency: currency),
                                icon: "dollarsign.circle.fill",
                                color: .green
                            )
                            
                            SummaryCard(
                                title: "Avg Consumption",
                                value: FuelMath.formatConsumption(averageConsumption, isMetric: isMetric),
                                icon: "gauge",
                                color: .orange
                            )
                            
                            SummaryCard(
                                title: "Avg Price",
                                value: FuelMath.formatCurrency(averagePrice, currency: currency),
                                icon: "tag.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Consumption Chart
                    if !consumptionData.isEmpty {
                        ConsumptionChartView(data: consumptionData, isMetric: isMetric)
                    }
                    
                    // Price Trend Chart
                    if !priceTrendData.isEmpty {
                        PriceTrendChartView(data: priceTrendData, currency: currency)
                    }
                    
                    // Monthly Spending Chart
                    if !monthlySpending.isEmpty {
                        SpendingChartView(data: monthlySpending, currency: currency)
                    }
                    
                    // Empty State
                    if consumptionData.isEmpty && monthlySpending.isEmpty && entries.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar",
                            title: "No Analytics Data",
                            message: "Add more refuel entries to see consumption trends and spending analysis."
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }
}

struct ConsumptionDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let consumption: Double
}

struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: Date
    let amount: Double
}

struct PriceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}

struct SummaryCard: View {
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
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
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

struct ConsumptionChartView: View {
    let data: [ConsumptionDataPoint]
    let isMetric: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fuel Consumption Trend")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Consumption", point.consumption)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                }
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Consumption", point.consumption)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .blue.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, data.count / 5))) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxisLabel(isMetric ? "L/100km" : "MPG")
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct PriceTrendChartView: View {
    let data: [PriceDataPoint]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price per Liter Trend")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, data.count / 5))) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxisLabel("Price (\(currency))")
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct SpendingChartView: View {
    let data: [MonthlySpending]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Spending")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(data) { item in
                BarMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(.green)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxisLabel("Amount (\(currency))")
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
