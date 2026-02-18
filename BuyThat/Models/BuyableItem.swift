//
//  BuyableItem.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import Foundation

protocol BuyableItem {
    var quantity: String { get }
    var storeVariantInfo: StoreVariantInfo? { get }
    var variant: ProductVariant? { get }
    var product: Product? { get }
    var purchaseUnit: PurchaseUnit? { get }
}

extension BuyableItem {
    var effectiveProduct: Product? {
        storeVariantInfo?.variant?.product ?? variant?.product ?? product
    }

    var effectiveVariant: ProductVariant? {
        storeVariantInfo?.variant ?? variant
    }

    var effectiveStore: Store? {
        storeVariantInfo?.store
    }

    var effectiveBaseUnit: MeasurementUnit {
        effectiveVariant?.baseUnit ?? effectiveProduct?.defaultMeasurementUnit ?? .units
    }

    var estimatedPrice: Decimal? {
        guard let storeInfo = storeVariantInfo else { return nil }

        let numbers = quantity.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let numericValue = Double(numbers) else { return nil }

        let pricePerSelectedUnit: Decimal?

        if let unit = purchaseUnit {
            pricePerSelectedUnit = storeInfo.priceForPurchaseUnit(unit)
        } else {
            guard let price = storeInfo.pricePerUnit else { return nil }

            if let pricingUnit = storeInfo.pricingUnit {
                pricePerSelectedUnit = price * Decimal(pricingUnit.conversionToBase)
            } else {
                pricePerSelectedUnit = price
            }
        }

        guard let priceValue = pricePerSelectedUnit else { return nil }
        return priceValue * Decimal(numericValue)
    }
}
