//
//  MeasurementUnit.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation

enum MeasurementUnit: String, Codable, Hashable, Sendable, CaseIterable {
    case grams = "g"
    case milliliters = "mL"
    case units = "units"

    var symbol: String {
        self.rawValue
    }
}
