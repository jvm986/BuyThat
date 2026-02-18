//
//  PurchaseUnit.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import Foundation
import SwiftData

@Model
final class PurchaseUnit {
    var unit: MeasurementUnit
    var conversionToBase: Double
    var isInverted: Bool // True if entered as "1 purchase_unit = X base_units"
    var unitName: String?
    var dateCreated: Date

    var variant: ProductVariant?

    @Relationship(deleteRule: .nullify, inverse: \ToBuyItem.purchaseUnit)
    var toBuyItems: [ToBuyItem]?

    @Relationship(deleteRule: .nullify, inverse: \ItemListEntry.purchaseUnit)
    var itemListEntries: [ItemListEntry]?

    @Relationship(deleteRule: .nullify, inverse: \StoreVariantInfo.pricingUnit)
    var storeVariantInfos: [StoreVariantInfo]?

    init(unit: MeasurementUnit, conversionToBase: Double, isInverted: Bool = false, variant: ProductVariant? = nil) {
        self.unit = unit
        self.conversionToBase = conversionToBase
        self.isInverted = isInverted
        self.variant = variant
        self.dateCreated = Date()
    }
}

extension PurchaseUnit {
    /// Returns the singular display name for this unit
    var displayName: String {
        if unit == .units {
            return unitName ?? variant?.unitName ?? variant?.product?.defaultUnitName ?? unit.singularSymbol
        }
        return unit.singularSymbol
    }

    /// Returns the plural display name for this unit
    var displayNamePlural: String {
        if unit == .units {
            let name = unitName ?? variant?.unitName ?? variant?.product?.defaultUnitName
            return name?.pluralized ?? unit.symbol
        }
        return unit.symbol
    }

    /// Shows the unit with conversion info (e.g., "1g = 150 units" or "1 units = 150g")
    var displayWithConversion: String {
        let baseUnitSymbol = variant?.baseUnit.symbol ?? "unit"
        return Self.formatConversion(
            conversionToBase: conversionToBase,
            baseUnitSymbol: baseUnitSymbol,
            purchaseUnitSymbol: displayName,
            isInverted: isInverted
        )
    }

    /// Static helper to format a conversion relationship
    static func formatConversion(
        conversionToBase: Double,
        baseUnitSymbol: String,
        purchaseUnitSymbol: String,
        isInverted: Bool
    ) -> String {
        let conversionValue = conversionToBase.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(conversionToBase))
            : String(format: "%.5g", conversionToBase)

        if isInverted {
            // Display as: "1 units = 150 g" (user entered it this way)
            let invertedValue = 1.0 / conversionToBase
            let invertedStr = invertedValue.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(invertedValue))
                : String(format: "%.5g", invertedValue)

            let leftSide = "1 \(purchaseUnitSymbol)"
            let rightSide = "\(invertedStr) \(baseUnitSymbol)"
            return "\(leftSide) = \(rightSide)"
        } else {
            // Display as: "1 g = 0.0067 units" (standard direction)
            let leftSide = "1 \(baseUnitSymbol)"
            let rightSide = "\(conversionValue) \(purchaseUnitSymbol)"
            return "\(leftSide) = \(rightSide)"
        }
    }
}
