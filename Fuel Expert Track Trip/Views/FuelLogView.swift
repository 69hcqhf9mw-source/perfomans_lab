import SwiftUI
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.fuelexpert", category: "FuelLogView")

struct FuelLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RefuelEntry.date, order: .reverse) private var entries: [RefuelEntry]
    @Query private var settings: [AppSettings]
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateDescending
    @State private var showingAddEntry = false
    
    enum SortOption: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case mileageDescending = "Highest Mileage"
        case mileageAscending = "Lowest Mileage"
        case costDescending = "Highest Cost"
        case costAscending = "Lowest Cost"
    }
    
    private var isMetric: Bool {
        settings.first?.isMetric ?? true
    }
    
    private var filteredAndSortedEntries: [RefuelEntry] {
        var result = entries
        
        // Filter by search text
        if !searchText.isEmpty {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            result = result.filter { entry in
                formatter.string(from: entry.date).localizedCaseInsensitiveContains(searchText) ||
                String(entry.mileage).contains(searchText) ||
                String(entry.liters).contains(searchText) ||
                String(entry.totalCost).contains(searchText)
            }
        }
        
        // Sort
        switch sortOption {
        case .dateDescending:
            result = result.sorted { $0.date > $1.date }
        case .dateAscending:
            result = result.sorted { $0.date < $1.date }
        case .mileageDescending:
            result = result.sorted { $0.mileage > $1.mileage }
        case .mileageAscending:
            result = result.sorted { $0.mileage < $1.mileage }
        case .costDescending:
            result = result.sorted { $0.totalCost > $1.totalCost }
        case .costAscending:
            result = result.sorted { $0.totalCost < $1.totalCost }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet",
                        title: "No Fuel Entries",
                        message: "Start tracking your fuel consumption by adding your first refuel entry."
                    )
                } else {
                    VStack(spacing: 0) {
                        // Search and Sort Bar
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                TextField("Search entries...", text: $searchText)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            Menu {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        sortOption = option
                                    }) {
                                        HStack {
                                            Text(option.rawValue)
                                            if sortOption == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.arrow.down")
                                    Text("Sort: \(sortOption.rawValue)")
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        
                        // List
                        List {
                            ForEach(filteredAndSortedEntries) { entry in
                                NavigationLink(destination: RefuelDetailView(entry: entry)) {
                                    RefuelRowView(entry: entry, isMetric: isMetric, currency: settings.first?.currency ?? "USD")
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Fuel Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        logger.info("🔘 Add button tapped in FuelLogView")
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                logger.info("📱 Sheet dismissed in FuelLogView, entries count: \(entries.count)")
            } content: {
                NavigationStack {
                    AddEntryView()
                }
            }
        }
        .onAppear {
            logger.info("📱 FuelLogView appeared, entries count: \(entries.count)")
        }
    }
}

struct RefuelRowView: View {
    let entry: RefuelEntry
    let isMetric: Bool
    let currency: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.headline)
                
                Text(FuelMath.formatDistance(entry.mileage, isMetric: isMetric))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(FuelMath.formatVolume(entry.liters, isMetric: isMetric))
                    .font(.headline)
                
                Text(FuelMath.formatCurrency(entry.totalCost, currency: currency))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
