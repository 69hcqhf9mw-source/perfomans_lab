import SwiftUI
import SwiftData

struct VehicleInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [VehicleInfo]
    @State private var brand: String = ""
    @State private var model: String = ""
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var tankCapacity: String = ""
    
    private var vehicle: VehicleInfo? {
        vehicles.first
    }
    
    private var isFormValid: Bool {
        !brand.isEmpty && !model.isEmpty && year > 1900 && year <= Calendar.current.component(.year, from: Date()) + 1
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                    
                    Picker("Year", selection: $year) {
                        ForEach(1900...(Calendar.current.component(.year, from: Date()) + 1), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    
                    HStack {
                        Text("Tank Capacity")
                        Spacer()
                        TextField("Liters", text: $tankCapacity)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Vehicle Information")
                } footer: {
                    Text("Enter your vehicle details to personalize your fuel tracking experience.")
                }
            }
            .navigationTitle("Vehicle Info")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVehicleInfo()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if let vehicle = vehicle {
                    brand = vehicle.brand
                    model = vehicle.model
                    year = vehicle.year
                    tankCapacity = vehicle.tankCapacity > 0 ? String(vehicle.tankCapacity) : ""
                }
            }
        }
    }
    
    private func saveVehicleInfo() {
        let capacity = Double(tankCapacity) ?? 0.0
        
        if let existingVehicle = vehicle {
            existingVehicle.brand = brand
            existingVehicle.model = model
            existingVehicle.year = year
            existingVehicle.tankCapacity = capacity
        } else {
            let newVehicle = VehicleInfo(
                brand: brand,
                model: model,
                year: year,
                tankCapacity: capacity
            )
            modelContext.insert(newVehicle)
        }
        
        try? modelContext.save()
    }
}
