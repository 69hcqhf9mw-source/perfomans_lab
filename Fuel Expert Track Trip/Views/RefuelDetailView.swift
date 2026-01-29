import SwiftUI
import SwiftData

struct RefuelDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RefuelEntry.date) private var allEntries: [RefuelEntry]
    @Query private var settings: [AppSettings]
    
    let entry: RefuelEntry
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    private var isMetric: Bool {
        settings.first?.isMetric ?? true
    }
    
    private var consumption: Double {
        let sortedEntries = allEntries.sorted { $0.date < $1.date }
        guard let currentIndex = sortedEntries.firstIndex(where: { $0.id == entry.id }),
              currentIndex > 0 else {
            return 0.0
        }
        
        let previousEntry = sortedEntries[currentIndex - 1]
        return FuelMath.calculateConsumption(
            currentMileage: entry.mileage,
            previousMileage: previousEntry.mileage,
            liters: entry.liters,
            isMetric: isMetric
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date Section
                DetailSection(title: "Date") {
                    Text(entry.date, style: .date)
                        .font(.title3)
                }
                
                // Mileage Section
                DetailSection(title: "Mileage") {
                    Text(FuelMath.formatDistance(entry.mileage, isMetric: isMetric))
                        .font(.title3)
                }
                
                // Volume Section
                DetailSection(title: "Volume") {
                    Text(FuelMath.formatVolume(entry.liters, isMetric: isMetric))
                        .font(.title3)
                }
                
                // Price Section
                DetailSection(title: "Price per Liter") {
                    Text(FuelMath.formatCurrency(entry.pricePerLiter, currency: settings.first?.currency ?? "USD"))
                        .font(.title3)
                }
                
                // Total Cost Section
                DetailSection(title: "Total Cost") {
                    Text(FuelMath.formatCurrency(entry.totalCost, currency: settings.first?.currency ?? "USD"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
                
                // Consumption Section
                if consumption > 0 {
                    DetailSection(title: "Fuel Consumption") {
                        Text(FuelMath.formatConsumption(consumption, isMetric: isMetric))
                            .font(.title3)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Refuel Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                AddEntryView(entryToEdit: entry)
            }
        }
        .alert("Delete Entry", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("Are you sure you want to delete this refuel entry? This action cannot be undone.")
        }
    }
    
    private func deleteEntry() {
        modelContext.delete(entry)
        try? modelContext.save()
        dismiss()
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
