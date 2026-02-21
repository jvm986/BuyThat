//
//  ReceiptModels.swift
//  BuyThat
//

import Foundation
import SwiftData

// MARK: - Parsed Receipt Models

struct ParsedReceipt {
    let storeName: String?
    let matchedStoreName: String?
    let receiptDate: Date?
    let items: [ParsedReceiptItem]
}

struct ParsedReceiptItem: Identifiable {
    let id: UUID
    let receiptText: String
    let price: Decimal
    let quantity: Double
    let unitPrice: Decimal?

    /// The price to store in StoreVariantInfo.pricePerUnit.
    /// Prefers the per-unit price (e.g. €5.99/kg) over the line total (e.g. €1.45 for 0.242kg).
    var priceForStorage: Decimal {
        unitPrice ?? price
    }

    init(receiptText: String, price: Decimal, quantity: Double, unitPrice: Decimal?) {
        self.id = UUID()
        self.receiptText = receiptText
        self.price = price
        self.quantity = quantity
        self.unitPrice = unitPrice
    }

    init() {
        self.id = UUID()
        self.receiptText = ""
        self.price = 0
        self.quantity = 1
        self.unitPrice = nil
    }
}

// MARK: - Matched Receipt Models

struct MatchedReceiptItem: Identifiable {
    let id: UUID
    let parsedItem: ParsedReceiptItem
    var matchResult: MatchResult
    var isIncluded: Bool = true
    var editedProductName: String
    var editedPrice: String
    var editedQuantity: String
    var editedUnit: MeasurementUnit

    // User override for store variant info selection
    var overrideStoreInfo: StoreVariantInfo?
    var hasStoreInfoOverride: Bool = false

    init(parsedItem: ParsedReceiptItem, matchResult: MatchResult) {
        self.id = parsedItem.id
        self.parsedItem = parsedItem
        self.matchResult = matchResult
        self.editedPrice = "\(parsedItem.priceForStorage)"
        self.editedQuantity = parsedItem.quantity.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(parsedItem.quantity))"
            : "\(parsedItem.quantity)"
        self.editedUnit = .units
        switch matchResult {
        case .matched(let product, _, _):
            self.editedProductName = product.name
        case .noMatch(let suggestedName):
            self.editedProductName = suggestedName
        }
    }

    enum MatchResult {
        case matched(product: Product, variant: ProductVariant?, storeInfo: StoreVariantInfo?)
        case noMatch(suggestedName: String)
    }

    // MARK: - Effective values (override-aware)

    var effectiveStoreInfo: StoreVariantInfo? {
        if hasStoreInfoOverride { return overrideStoreInfo }
        if case .matched(_, _, let storeInfo) = matchResult { return storeInfo }
        return nil
    }

    var effectiveVariant: ProductVariant? {
        if let storeInfo = effectiveStoreInfo { return storeInfo.variant }
        if case .matched(_, let variant, _) = matchResult { return variant }
        return nil
    }

    var effectiveProduct: Product? {
        if let variant = effectiveVariant { return variant.product }
        if case .matched(let product, _, _) = matchResult { return product }
        return nil
    }

    var effectivelyMatched: Bool {
        effectiveProduct != nil
    }

    var effectivePrice: Decimal? {
        let normalized = editedPrice.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    var effectiveQuantity: Int {
        Int(editedQuantity) ?? Int(parsedItem.quantity)
    }

    // MARK: - Convenience properties

    var isMatched: Bool {
        effectivelyMatched
    }

    var currentPrice: Decimal? {
        effectiveStoreInfo?.pricePerUnit
    }
}

// MARK: - Save Result

struct ReceiptSaveResult {
    let pricesUpdated: Int
    let productsCreated: Int
    let shoppingTrip: ShoppingTrip
}
