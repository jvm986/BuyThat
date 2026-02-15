//
//  ReceiptModels.swift
//  BuyThat
//

import Foundation

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
    let matchedProductName: String?
    let matchedBrandName: String?
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
    let matchedProductName: String?
    let matchedBrandName: String?

    init(from llmItem: LLMReceiptItem) {
        self.id = UUID()
        self.receiptText = llmItem.receiptText
        self.price = Decimal(llmItem.price)
        self.quantity = llmItem.quantity
        self.unit = llmItem.unit
        self.matchedProductName = llmItem.matchedProductName
        self.matchedBrandName = llmItem.matchedBrandName
    }
}

// MARK: - Matched Receipt Models

struct MatchedReceiptItem: Identifiable {
    let id: UUID
    let parsedItem: ParsedReceiptItem
    var matchResult: MatchResult
    var isIncluded: Bool = true
    var editedProductName: String

    init(parsedItem: ParsedReceiptItem, matchResult: MatchResult) {
        self.id = parsedItem.id
        self.parsedItem = parsedItem
        self.matchResult = matchResult
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

    var isMatched: Bool {
        if case .matched = matchResult { return true }
        return false
    }

    var matchedProduct: Product? {
        if case .matched(let product, _, _) = matchResult { return product }
        return nil
    }

    var matchedVariant: ProductVariant? {
        if case .matched(_, let variant, _) = matchResult { return variant }
        return nil
    }

    var matchedStoreInfo: StoreVariantInfo? {
        if case .matched(_, _, let storeInfo) = matchResult { return storeInfo }
        return nil
    }

    var currentPrice: Decimal? {
        matchedStoreInfo?.pricePerUnit
    }
}

// MARK: - Save Result

struct ReceiptSaveResult {
    let pricesUpdated: Int
    let productsCreated: Int
}
