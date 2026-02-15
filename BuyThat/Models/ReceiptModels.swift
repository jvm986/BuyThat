//
//  ReceiptModels.swift
//  BuyThat
//

import Foundation
import SwiftData

// MARK: - LLM Response Models

struct LLMReceiptResponse: Codable {
    let storeName: String?
    let matchedStoreName: String?
    let receiptDate: String?
    let items: [LLMReceiptItem]
}

struct LLMReceiptItem: Codable {
    let receiptText: String
    let price: Double
    let quantity: Int
    let unit: String?
    let unitPrice: Double?
    let unitPriceUnit: String?
    let matchedProductName: String?
    let matchedBrandName: String?
    let matchedTagNames: [String]?
}

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
    let quantity: Int
    let unit: String?
    let unitPrice: Decimal?
    let unitPriceUnit: String?
    let matchedProductName: String?
    let matchedBrandName: String?
    let matchedTagNames: [String]

    /// The price to store in StoreVariantInfo.pricePerUnit.
    /// Prefers the per-unit price (e.g. €5.99/kg) over the line total (e.g. €1.45 for 0.242kg).
    var priceForStorage: Decimal {
        unitPrice ?? price
    }

    init(from llmItem: LLMReceiptItem) {
        self.id = UUID()
        self.receiptText = llmItem.receiptText
        self.price = Decimal(llmItem.price)
        self.quantity = llmItem.quantity
        self.unit = llmItem.unit
        self.unitPrice = llmItem.unitPrice.map { Decimal($0) }
        self.unitPriceUnit = llmItem.unitPriceUnit
        self.matchedProductName = llmItem.matchedProductName
        self.matchedBrandName = llmItem.matchedBrandName
        self.matchedTagNames = llmItem.matchedTagNames ?? []
    }

    init() {
        self.id = UUID()
        self.receiptText = ""
        self.price = 0
        self.quantity = 1
        self.unit = nil
        self.unitPrice = nil
        self.unitPriceUnit = nil
        self.matchedProductName = nil
        self.matchedBrandName = nil
        self.matchedTagNames = []
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

    // User override for store variant info selection
    var overrideStoreInfo: StoreVariantInfo?
    var hasStoreInfoOverride: Bool = false

    init(parsedItem: ParsedReceiptItem, matchResult: MatchResult) {
        self.id = parsedItem.id
        self.parsedItem = parsedItem
        self.matchResult = matchResult
        self.editedPrice = "\(parsedItem.priceForStorage)"
        self.editedQuantity = "\(parsedItem.quantity)"
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
        Int(editedQuantity) ?? parsedItem.quantity
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
