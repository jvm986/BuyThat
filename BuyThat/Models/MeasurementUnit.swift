//
//  MeasurementUnit.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation

enum MeasurementUnit: String, Codable, Hashable, Sendable, CaseIterable {
    case kilograms = "kg"
    case liters = "L"
    case units = "units"
    case grams = "g"
    case milliliters = "mL"

    var symbol: String {
        self.rawValue
    }

    enum Family: String, CaseIterable {
        case mass
        case volume
        case count
    }

    var family: Family {
        switch self {
        case .grams, .kilograms:
            return .mass
        case .milliliters, .liters:
            return .volume
        case .units:
            return .count
        }
    }

    /// Conversion factor to the smallest unit in the family (g for mass, mL for volume, 1 for count)
    var toFamilyBase: Double {
        switch self {
        case .grams: return 1
        case .kilograms: return 1000
        case .milliliters: return 1
        case .liters: return 1000
        case .units: return 1
        }
    }

    /// Returns the conversion factor from self to target, or nil if cross-family
    func conversionFactor(to target: MeasurementUnit) -> Double? {
        guard self.family == target.family else { return nil }
        return self.toFamilyBase / target.toFamilyBase
    }

    /// Human-readable label for pickers
    var displayLabel: String {
        switch self {
        case .grams: return "Grams (g)"
        case .kilograms: return "Kilograms (kg)"
        case .milliliters: return "Milliliters (mL)"
        case .liters: return "Liters (L)"
        case .units: return "Count (units)"
        }
    }

    /// All cases grouped by family for picker display
    static var groupedByFamily: [(family: Family, units: [MeasurementUnit])] {
        Family.allCases.map { family in
            (family: family, units: allCases.filter { $0.family == family })
        }
    }
}
