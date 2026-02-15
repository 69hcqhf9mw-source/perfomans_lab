import SwiftUI
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.fuelexpert", category: "DashboardView")

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RefuelEntry.date, order: .reverse) private var entries: [RefuelEntry]
    @Query private var vehicleInfo: [VehicleInfo]
    @Query private var settings: [AppSettings]
    
    @State private var showingAddEntry = false
    
    private var lastEntry: RefuelEntry? {
        entries.first
    }
    
    private var totalMileage: Double {
        entries.max(by: { $0.mileage < $1.mileage })?.mileage ?? 0.0
    }
    
    private var isMetric: Bool {
        settings.first?.isMetric ?? true
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Vehicle Info Card
                    if let vehicle = vehicleInfo.first, !vehicle.brand.isEmpty {
                        VehicleSummaryCard(vehicle: vehicle)
                    }
                    
                    // Last Refuel Card
                    if let entry = lastEntry {
                        LastRefuelCard(entry: entry, isMetric: isMetric, currency: settings.first?.currency ?? "USD")
                    } else {
                        EmptyStateView(
                            icon: "fuelpump",
                            title: "No Refuel Entries",
                            message: "Start tracking your fuel consumption by adding your first refuel entry."
                        )
                    }
                    
                    // Statistics Card
                    if !entries.isEmpty {
                        StatisticsCard(entries: entries, isMetric: isMetric, currency: settings.first?.currency ?? "USD")
                        
                        // Quick Stats Grid
                        QuickStatsGrid(entries: entries, isMetric: isMetric, settings: settings.first)
                    }
                    
                    // Quick Add Button - используем sheet вместо NavigationLink
                    Button {
                        logger.info("🔘 Quick Add Refuel button tapped")
                        logger.info("📊 Current entries count: \(entries.count)")
                        showingAddEntry = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Quick Add Refuel")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingAddEntry) {
                logger.info("📱 Sheet dismissed, entries count: \(entries.count)")
            } content: {
                NavigationStack {
                    AddEntryView()
                }
            }
        }
        .onAppear {
            logger.info("📱 DashboardView appeared")
            logger.info("📊 Entries count: \(entries.count)")
            logger.info("📊 ModelContext: \(String(describing: modelContext))")
            
            // Детальное логирование всех записей
            if !entries.isEmpty {
                let sorted = entries.sorted { $0.date < $1.date }
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                
                logger.info("📊 All entries (sorted by date):")
                for (index, entry) in sorted.enumerated() {
                    let dateString = dateFormatter.string(from: entry.date)
                    logger.info("  \(index + 1). Date: \(dateString), Mileage: \(entry.mileage), Liters: \(entry.liters), Price: \(entry.pricePerLiter)")
                }
                
                // Логируем расчеты Total Distance
                var totalDistance = 0.0
                for i in 1..<sorted.count {
                    let current = sorted[i]
                    let previous = sorted[i - 1]
                    if current.mileage > previous.mileage {
                        let segmentDistance = current.mileage - previous.mileage
                        totalDistance += segmentDistance
                        logger.info("📏 Distance segment \(i): \(previous.mileage) → \(current.mileage) = \(segmentDistance)")
                    } else {
                        logger.info("📏 Distance segment \(i): Skipped (mileage didn't increase: \(previous.mileage) → \(current.mileage))")
                    }
                }
                logger.info("📏 Total Distance: \(totalDistance)")
                
                // Логируем consumption
                if entries.count > 1 {
                    var totalConsumption = 0.0
                    var validCalculations = 0
                    
                    for i in 1..<sorted.count {
                        let current = sorted[i]
                        let previous = sorted[i - 1]
                        let diff = current.mileage - previous.mileage
                        
                        logger.info("📊 Consumption calc \(i):")
                        logger.info("  Previous: mileage=\(previous.mileage), liters=\(previous.liters)")
                        logger.info("  Current: mileage=\(current.mileage), liters=\(current.liters)")
                        logger.info("  Mileage difference: \(diff)")
                        
                        if current.mileage > previous.mileage {
                            let consumption = FuelMath.calculateConsumption(
                                currentMileage: current.mileage,
                                previousMileage: previous.mileage,
                                liters: current.liters,
                                isMetric: isMetric
                            )
                            logger.info("  ✅ Valid - Consumption: \(consumption)")
                            if consumption > 0 {
                                totalConsumption += consumption
                                validCalculations += 1
                            }
                        } else {
                            logger.info("  ⚠️ Skipped - Mileage didn't increase")
                        }
                    }
                    
                    let avgConsumption = validCalculations > 0 ? totalConsumption / Double(validCalculations) : 0.0
                    logger.info("📊 Avg Consumption result:")
                    logger.info("  Valid calculations: \(validCalculations)")
                    logger.info("  Total consumption: \(totalConsumption)")
                    logger.info("  Average: \(avgConsumption)")
                    
                    // Логируем пары
                    let validPairs = (1..<sorted.count).filter { sorted[$0].mileage > sorted[$0-1].mileage }.count
                    let invalidPairs = sorted.count - 1 - validPairs
                    logger.info("📊 Mileage pairs analysis:")
                    logger.info("  Valid increases: \(validPairs)")
                    logger.info("  Invalid (same/decreased): \(invalidPairs)")
                }
            }
        }
        .onChange(of: entries.count) { oldCount, newCount in
            logger.info("📊 Entries count changed: \(oldCount) → \(newCount)")
        }
    }
}

struct VehicleSummaryCard: View {
    let vehicle: VehicleInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.accentColor)
                Text(vehicle.displayName)
                    .font(.headline)
                Spacer()
            }
            
            if vehicle.year > 0 {
                Text("\(vehicle.year)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct LastRefuelCard: View {
    let entry: RefuelEntry
    let isMetric: Bool
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "fuelpump.fill")
                    .foregroundColor(.accentColor)
                Text("Last Refuel")
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Volume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(FuelMath.formatVolume(entry.liters, isMetric: isMetric))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(FuelMath.formatCurrency(entry.totalCost, currency: currency))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Mileage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(FuelMath.formatDistance(entry.mileage, isMetric: isMetric))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Price/Liter")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(FuelMath.formatCurrency(entry.pricePerLiter, currency: currency))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatisticsCard: View {
    let entries: [RefuelEntry]
    let isMetric: Bool
    let currency: String
    
    private var totalCost: Double {
        entries.reduce(0) { $0 + $1.totalCost }
    }
    
    private var totalLiters: Double {
        entries.reduce(0) { $0 + $1.liters }
    }
    
    private var averageConsumption: Double {
        guard entries.count > 1 else { 
            print("⚠️ StatisticsCard: Not enough entries for consumption (\(entries.count))")
            return 0.0 
        }
        // Сортируем по пробегу для правильного расчета потребления
        let sortedEntries = entries.sorted { $0.mileage < $1.mileage }
        var totalConsumption = 0.0
        var validCalculations = 0
        
        print("📊 StatisticsCard: Calculating consumption from \(sortedEntries.count) entries")
        
        for i in 1..<sortedEntries.count {
            let current = sortedEntries[i]
            let previous = sortedEntries[i - 1]
            
            print("  Entry \(i): prev mileage=\(previous.mileage), curr mileage=\(current.mileage), liters=\(current.liters)")
            
            // Проверяем, что пробег увеличился
            guard current.mileage > previous.mileage else { 
                print("  ⚠️ Skipping: mileage didn't increase")
                continue 
            }
            
            let consumption = FuelMath.calculateConsumption(
                currentMileage: current.mileage,
                previousMileage: previous.mileage,
                liters: current.liters,
                isMetric: isMetric
            )
            
            print("  ✅ Consumption calculated: \(consumption)")
            
            if consumption > 0 {
                totalConsumption += consumption
                validCalculations += 1
            }
        }
        
        let result = validCalculations > 0 ? totalConsumption / Double(validCalculations) : 0.0
        print("📊 StatisticsCard Avg Consumption: valid=\(validCalculations), total=\(totalConsumption), avg=\(result)")
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Total Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(FuelMath.formatCurrency(totalCost, currency: currency))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Avg Consumption")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if averageConsumption > 0 {
                        Text(FuelMath.formatConsumption(averageConsumption, isMetric: isMetric))
                            .font(.title3)
                            .fontWeight(.semibold)
                    } else {
                        Text("N/A")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

struct QuickStatsGrid: View {
    let entries: [RefuelEntry]
    let isMetric: Bool
    let settings: AppSettings?
    
    private var totalSpent: Double {
        entries.reduce(0) { $0 + $1.totalCost }
    }
    
    private var totalLiters: Double {
        entries.reduce(0) { $0 + $1.liters }
    }
    
    private var totalDistance: Double {
        guard entries.count > 1 else { 
            return 0.0 
        }
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
    
    var body: some View {
        let distanceValue = totalDistance
        let distanceText = distanceValue > 0 ? FuelMath.formatDistance(distanceValue, isMetric: isMetric) : "0.0 \(isMetric ? "km" : "miles")"
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickStatCard(
                title: "Total Spent",
                value: FuelMath.formatCurrency(totalSpent, currency: settings?.currency ?? "USD"),
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            QuickStatCard(
                title: "Total Fuel",
                value: FuelMath.formatVolume(totalLiters, isMetric: isMetric),
                icon: "fuelpump.fill",
                color: .red
            )
            
            QuickStatCard(
                title: "Total Distance",
                value: distanceText,
                icon: "road.lanes",
                color: .blue
            )
            
            QuickStatCard(
                title: "Entries",
                value: "\(entries.count)",
                icon: "list.number",
                color: .orange
            )
        }
        .padding(.horizontal)
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

