import Foundation
import SwiftUI

enum UnitSystem: String, CaseIterable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }

    var weightLabel: String {
        switch self {
        case .metric: return "g"
        case .imperial: return "oz"
        }
    }

    var shortTitle: String {
        switch self {
        case .metric: return "Metric"
        case .imperial: return "Imperial"
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("com.snaptrack.unitSystem") var unitSystem: UnitSystem = .metric

    func formatWeight(_ grams: Int) -> String {
        switch unitSystem {
        case .metric:
            return "\(grams)g"
        case .imperial:
            let ounces = Double(grams) / 28.3495
            return String(format: "%.1f oz", ounces)
        }
    }

    func weightValue(_ grams: Int) -> Double {
        switch unitSystem {
        case .metric: return Double(grams)
        case .imperial: return Double(grams) / 28.3495
        }
    }
}
