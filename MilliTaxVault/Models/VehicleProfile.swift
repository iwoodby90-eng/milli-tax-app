import Foundation

// MARK: - VehicleProfile — Onboarding vehicle data model
// Persisted via @AppStorage / UserDefaults during onboarding setup.

struct VehicleProfile: Codable, Identifiable {
    var id = UUID()
    var year: String = ""
    var make: String = ""
    var model: String = ""
    var vehicleUse: VehicleUse = .personal
    var odometerReading: String = ""
    
    enum VehicleUse: String, Codable, CaseIterable {
        case personal = "Personal"
        case business = "Business"
        case mixed = "Mixed Use"
        
        var icon: String {
            switch self {
            case .personal: return "car.fill"
            case .business: return "briefcase.fill"
            case .mixed: return "arrow.triangle.2.circlepath"
            }
        }
    }
    
    var displayName: String {
        if year.isEmpty && make.isEmpty && model.isEmpty {
            return "My Vehicle"
        }
        return [year, make, model].filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    var isValid: Bool {
        !year.isEmpty && !make.isEmpty && !model.isEmpty
    }
}
