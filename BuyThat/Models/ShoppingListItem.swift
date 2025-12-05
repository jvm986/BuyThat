//
//  ShoppingListItem.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation
import SwiftData

@Model
final class ShoppingListItem {
    var quantity: String
    var isPurchased: Bool
    var dateAdded: Date

    @Relationship(deleteRule: .nullify)
    var list: ShoppingList?

    @Relationship(deleteRule: .nullify)
    var storeVariantInfo: StoreVariantInfo?

    @Relationship(deleteRule: .nullify)
    var purchaseUnit: PurchaseUnit?

    init(storeVariantInfo: StoreVariantInfo?, quantity: String = "1", purchaseUnit: PurchaseUnit? = nil, list: ShoppingList? = nil) {
        self.storeVariantInfo = storeVariantInfo
        self.quantity = quantity
        self.purchaseUnit = purchaseUnit
        self.list = list
        self.isPurchased = false
        self.dateAdded = Date()
    }
}

extension ShoppingListItem {
    var estimatedPrice: Decimal? {
        guard let storeInfo = storeVariantInfo else { return nil }

        // Extract numeric value from quantity string
        let numbers = quantity.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let numericValue = Double(numbers) else { return nil }

        // Calculate price based on selected unit
        let pricePerSelectedUnit: Decimal?

        if let unit = purchaseUnit {
            // Purchase unit selected - convert from pricing unit
            pricePerSelectedUnit = storeInfo.priceForPurchaseUnit(unit)
        } else {
            // Base unit selected - need to convert from pricing unit to base unit
            guard let price = storeInfo.pricePerUnit else { return nil }

            if let pricingUnit = storeInfo.pricingUnit {
                // Convert from pricing unit to base unit
                // conversionToBase represents: X pricing_units = 1 base_unit
                // Example: 800g = 1 unit, so conversionToBase = 800
                // If price per g = €0.01, then price per unit = €0.01 × 800 = €8.00
                pricePerSelectedUnit = price * Decimal(pricingUnit.conversionToBase)
            } else {
                // Pricing unit is the base unit
                pricePerSelectedUnit = price
            }
        }

        guard let priceValue = pricePerSelectedUnit else { return nil }
        return priceValue * Decimal(numericValue)
    }
}
