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

    var list: ShoppingList?

    var storeVariantInfo: StoreVariantInfo?
    var variant: ProductVariant?
    var product: Product?

    var purchaseUnit: PurchaseUnit?

    init(storeVariantInfo: StoreVariantInfo? = nil, variant: ProductVariant? = nil, product: Product? = nil, quantity: String = "1", purchaseUnit: PurchaseUnit? = nil, list: ShoppingList? = nil) {
        self.storeVariantInfo = storeVariantInfo
        self.variant = variant
        self.product = product
        self.quantity = quantity
        self.purchaseUnit = purchaseUnit
        self.list = list
        self.isPurchased = false
        self.dateAdded = Date()
    }
}

extension ShoppingListItem {
    // Get the effective product (priority: storeVariantInfo > variant > product)
    var effectiveProduct: Product? {
        storeVariantInfo?.variant?.product ?? variant?.product ?? product
    }

    // Get the effective variant (priority: storeVariantInfo > variant)
    var effectiveVariant: ProductVariant? {
        storeVariantInfo?.variant ?? variant
    }

    // Get the store if available
    var effectiveStore: Store? {
        storeVariantInfo?.store
    }

    // Get base unit from variant or default to units
    var effectiveBaseUnit: MeasurementUnit {
        effectiveVariant?.baseUnit ?? .units
    }

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
