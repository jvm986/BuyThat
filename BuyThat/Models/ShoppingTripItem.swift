//
//  ShoppingTripItem.swift
//  BuyThat
//

import Foundation
import SwiftData

@Model
final class ShoppingTripItem {
    var trip: ShoppingTrip?

    @Relationship(deleteRule: .nullify)
    var product: Product?

    @Relationship(deleteRule: .nullify)
    var variant: ProductVariant?

    @Relationship(deleteRule: .nullify)
    var storeVariantInfo: StoreVariantInfo?

    var quantity: Int
    var pricePerItem: Decimal
    var unitPrice: Decimal?
    var unitPriceUnit: String?
    var receiptText: String
    var productName: String
    var sortOrder: Int = 0

    init(
        trip: ShoppingTrip?,
        product: Product?,
        variant: ProductVariant?,
        storeVariantInfo: StoreVariantInfo?,
        quantity: Int,
        pricePerItem: Decimal,
        unitPrice: Decimal? = nil,
        unitPriceUnit: String? = nil,
        receiptText: String,
        productName: String,
        sortOrder: Int = 0
    ) {
        self.trip = trip
        self.product = product
        self.variant = variant
        self.storeVariantInfo = storeVariantInfo
        self.quantity = quantity
        self.pricePerItem = pricePerItem
        self.unitPrice = unitPrice
        self.unitPriceUnit = unitPriceUnit
        self.receiptText = receiptText
        self.productName = productName
        self.sortOrder = sortOrder
    }
}

extension ShoppingTripItem {
    var displayProductName: String {
        product?.name ?? productName
    }

    var lineTotal: Decimal {
        pricePerItem * Decimal(quantity)
    }

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: pricePerItem as NSDecimalNumber) ?? "\(pricePerItem)"
    }

    var formattedLineTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: lineTotal as NSDecimalNumber) ?? "\(lineTotal)"
    }

    var formattedUnitPrice: String? {
        guard let unitPrice = unitPrice else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        guard let priceStr = formatter.string(from: unitPrice as NSDecimalNumber) else { return nil }
        let unit = unitPriceUnit ?? "unit"
        return "\(priceStr)/\(unit)"
    }
}
