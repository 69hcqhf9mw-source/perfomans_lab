import SwiftUI
import SwiftData
import os.log

// Logger for debugging
private let logger = Logger(subsystem: "com.fuelexpert", category: "AddEntryView")

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [AppSettings]
    @Query private var existingEntries: [RefuelEntry]
    
    let entryToEdit: RefuelEntry?
    
    @State private var mileage: String = ""
    @State private var liters: String = ""
    @State private var pricePerLiter: String = ""
    @State private var date: Date = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(entryToEdit: RefuelEntry? = nil) {
        self.entryToEdit = entryToEdit
        logger.info("🚀 AddEntryView initialized, editing: \(entryToEdit != nil)")
    }
    
    private var isMetric: Bool {
        settings.first?.isMetric ?? true
    }
    
    private var isFormValid: Bool {
        let valid = !mileage.isEmpty &&
        !liters.isEmpty &&
        !pricePerLiter.isEmpty &&
        Double(mileage) != nil &&
        Double(liters) != nil &&
        Double(pricePerLiter) != nil &&
        (Double(mileage) ?? 0) > 0 &&
        (Double(liters) ?? 0) > 0 &&
        (Double(pricePerLiter) ?? 0) > 0
        
        return valid
    }
    
    var body: some View {
        Form {
            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            
            Section {
                HStack {
                    Text("Current Mileage")
                    Spacer()
                    TextField(isMetric ? "km" : "miles", text: $mileage)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Liters")
                    Spacer()
                    TextField("L", text: $liters)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Price per Liter")
                    Spacer()
                    TextField("$", text: $pricePerLiter)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section {
                if isFormValid {
                    let totalCost = (Double(liters) ?? 0) * (Double(pricePerLiter) ?? 0)
                    HStack {
                        Text("Total Cost")
                        Spacer()
                        Text(formatCurrency(totalCost))
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationTitle(entryToEdit == nil ? "Add Refuel" : "Edit Refuel")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    logger.info("❌ Cancel button tapped")
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    logger.info("💾 Save button tapped")
                    saveEntry()
                }
                .disabled(!isFormValid)
            }
        }
        .onAppear {
            logger.info("📱 AddEntryView appeared")
            logger.info("📊 ModelContext: \(String(describing: modelContext))")
            logger.info("📊 Existing entries count: \(existingEntries.count)")
            
            if let entry = entryToEdit {
                mileage = String(entry.mileage)
                liters = String(entry.liters)
                pricePerLiter = String(entry.pricePerLiter)
                date = entry.date
                logger.info("📝 Loaded entry for editing: mileage=\(entry.mileage), liters=\(entry.liters)")
            }
        }
        .alert(alertMessage.contains("Warning") ? "Warning" : "Error", isPresented: $showingAlert) {
            if alertMessage.contains("Warning") && alertMessage.contains("Mileage") {
                // Only allow "Save Anyway" for mileage warnings, not for unrealistic values
                Button("Save Anyway") {
                    saveEntryAfterWarning()
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveEntry() {
        logger.info("🔄 saveEntry() called")
        logger.info("📊 Input values - mileage: '\(mileage)', liters: '\(liters)', price: '\(pricePerLiter)'")
        
        // Parse values
        guard let mileageValue = Double(mileage) else {
            logger.error("❌ Failed to parse mileage: '\(mileage)'")
            alertMessage = "Invalid mileage value"
            showingAlert = true
            return
        }
        
        guard let litersValue = Double(liters) else {
            logger.error("❌ Failed to parse liters: '\(liters)'")
            alertMessage = "Invalid liters value"
            showingAlert = true
            return
        }
        
        guard let priceValue = Double(pricePerLiter) else {
            logger.error("❌ Failed to parse price: '\(pricePerLiter)'")
            alertMessage = "Invalid price value"
            showingAlert = true
            return
        }
        
        // Validate values are positive
        guard mileageValue > 0, litersValue > 0, priceValue > 0 else {
            logger.error("❌ Values must be positive: mileage=\(mileageValue), liters=\(litersValue), price=\(priceValue)")
            alertMessage = "All values must be greater than 0"
            showingAlert = true
            return
        }
        
        // Validate realistic values
        // Check for unrealistic fuel amount (more than 200L is suspicious for most vehicles)
        if litersValue > 200 {
            logger.warning("⚠️ Unrealistic fuel amount: \(litersValue) liters")
            alertMessage = "Warning: The fuel amount (\(String(format: "%.2f", litersValue)) L) seems unusually high. Please verify the value is correct."
            showingAlert = true
            return
        }
        
        // Check for unrealistic price (more than $10 per liter is suspicious)
        if priceValue > 10 {
            logger.warning("⚠️ Unrealistic price: \(priceValue) per liter")
            alertMessage = "Warning: The price per liter (\(FuelMath.formatCurrency(priceValue, currency: settings.first?.currency ?? "USD"))) seems unusually high. Please verify the value is correct."
            showingAlert = true
            return
        }
        
        // Check for unrealistic mileage (more than 1,000,000 km/miles)
        if mileageValue > 1_000_000 {
            logger.warning("⚠️ Unrealistic mileage: \(mileageValue)")
            alertMessage = "Warning: The mileage (\(FuelMath.formatDistance(mileageValue, isMetric: isMetric))) seems unusually high. Please verify the value is correct."
            showingAlert = true
            return
        }
        
        logger.info("✅ Values parsed successfully: mileage=\(mileageValue), liters=\(litersValue), price=\(priceValue)")
        
        // Check if we need to show warning about mileage
        var shouldShowWarning = false
        if entryToEdit == nil && !existingEntries.isEmpty {
            let sortedEntries = existingEntries.sorted { $0.date < $1.date }
            let lastMileage = sortedEntries.last!.mileage
            
            if mileageValue <= lastMileage {
                logger.warning("⚠️ Mileage warning: new mileage (\(mileageValue)) is not greater than last entry (\(lastMileage))")
                alertMessage = "Warning: Mileage should be higher than the last entry (\(String(format: "%.1f", lastMileage))). Current: \(String(format: "%.1f", mileageValue)). Distance and consumption calculations may not work correctly."
                shouldShowWarning = true
            }
        }
        
        if shouldShowWarning {
            showingAlert = true
            return
        }
        
        // Save entry directly if no warning needed
        performSave()
    }
    
    private func saveEntryAfterWarning() {
        // Called when user confirms saving despite warning
        performSave()
    }
    
    private func performSave() {
        guard let mileageValue = Double(mileage),
              let litersValue = Double(liters),
              let priceValue = Double(pricePerLiter) else {
            return
        }
        
        // Update or create entry
        if let entry = entryToEdit {
            logger.info("📝 Updating existing entry with id: \(entry.id)")
            entry.date = date
            entry.mileage = mileageValue
            entry.liters = litersValue
            entry.pricePerLiter = priceValue
        } else {
            logger.info("🆕 Creating new RefuelEntry")
            let newEntry = RefuelEntry(
                date: date,
                mileage: mileageValue,
                liters: litersValue,
                pricePerLiter: priceValue
            )
            logger.info("🆕 New entry created with id: \(newEntry.id)")
            
            logger.info("📥 Inserting entry into modelContext")
            modelContext.insert(newEntry)
            logger.info("📥 Entry inserted")
        }
        
        // Save context
        logger.info("💾 Attempting to save modelContext...")
        do {
            try modelContext.save()
            logger.info("✅ ModelContext saved successfully!")
            logger.info("📊 Total entries after save: \(existingEntries.count)")
            dismiss()
        } catch {
            logger.error("❌ Failed to save: \(error.localizedDescription)")
            logger.error("❌ Full error: \(String(describing: error))")
            alertMessage = "Failed to save: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let currency = settings.first?.currency ?? "USD"
        return FuelMath.formatCurrency(value, currency: currency)
    }
}
