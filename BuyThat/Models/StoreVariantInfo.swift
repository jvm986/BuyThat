//
//  StoreVariantInfo.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation
import SwiftData

@Model
final class StoreVariantInfo {
    var pricePerUnit: Decimal?
    var dateCreated: Date
    var dateModified: Date

    @Relationship(deleteRule: .nullify)
    var variant: ProductVariant?

    @Relationship(deleteRule: .nullify)
    var store: Store?

    @Relationship(deleteRule: .nullify)
    var pricingUnit: PurchaseUnit?

    @Relationship(deleteRule: .cascade, inverse: \PriceHistory.storeVariantInfo)
    var priceHistory: [PriceHistory]?

    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.storeVariantInfo)
    var shoppingListItems: [ShoppingListItem]?

    init(variant: ProductVariant?, store: Store?, pricePerUnit: Decimal? = nil, pricingUnit: PurchaseUnit? = nil) {
        self.variant = variant
        self.store = store
        self.pricePerUnit = pricePerUnit
        self.pricingUnit = pricingUnit
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}

extension StoreVariantInfo {
    var displayName: String {
        var parts: [String] = []
        if let variantName = variant?.displayName {
            parts.append(variantName)
        }
        if let storeName = store?.name {
            parts.append("at \(storeName)")
        }
        return parts.joined(separator: " ")
    }

    /// Calculates the price for a given purchase unit
    func priceForPurchaseUnit(_ purchaseUnit: PurchaseUnit) -> Decimal? {
        guard let price = pricePerUnit else { return nil }

        // Get conversion factors
        // conversionToBase means: X purchase_units = 1 base_unit
        let sourceFactor = pricingUnit?.conversionToBase ?? 1.0
        let targetFactor = purchaseUnit.conversionToBase

        // To convert price: we need to invert the conversion factors
        // Example: if 0.0067 apples = 1g, then 1 apple = 1/0.0067 g
        // So price_per_apple = price_per_g × (1/0.0067)
        return price * Decimal(sourceFactor / targetFactor)
    }

    /// Formatted price for the pricing unit
    var formattedPrice: String? {
        guard let price = pricePerUnit else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: price as NSDecimalNumber)
    }

    /// Formatted price with unit label
    var formattedPricePerUnit: String? {
        guard let price = pricePerUnit else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"

        guard let priceStr = formatter.string(from: price as NSDecimalNumber) else { return nil }

        let unitName = pricingUnit?.displayName ?? variant?.baseUnit.symbol ?? "unit"
        return "\(priceStr)/\(unitName)"
    }

    /// Formatted price for a specific purchase unit
    func formattedPriceForPurchaseUnit(_ purchaseUnit: PurchaseUnit) -> String? {
        guard let price = priceForPurchaseUnit(purchaseUnit) else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: price as NSDecimalNumber)
    }
}
