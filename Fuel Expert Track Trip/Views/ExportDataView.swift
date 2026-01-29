import SwiftUI
import SwiftData

struct ExportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RefuelEntry.date) private var entries: [RefuelEntry]
    @Query private var vehicles: [VehicleInfo]
    @State private var exportFormat: ExportFormat = .csv
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
            } header: {
                Text("Export Format")
            } footer: {
                Text(exportFormat == .csv ? "CSV format is compatible with Excel and Google Sheets." : "JSON format preserves all data structure.")
            }
            
            Section {
                HStack {
                    Text("Total Entries")
                    Spacer()
                    Text("\(entries.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Date Range")
                    Spacer()
                    if let first = entries.first, let last = entries.last {
                        Text("\(first.date, style: .date) - \(last.date, style: .date)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        Text("No data")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Data Summary")
            }
            
            Section {
                Button(action: {
                    exportData()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data")
                    }
                }
                .disabled(entries.isEmpty)
            }
        }
        .navigationTitle("Export Data")
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }
    
    private func exportData() {
        if exportFormat == .csv {
            let csv = DataExportService.exportToCSV(entries: entries)
            shareItems = [csv]
        } else {
            if let jsonData = DataExportService.exportToJSON(entries: entries, vehicle: vehicles.first) {
                shareItems = [jsonData]
            }
        }
        showShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
