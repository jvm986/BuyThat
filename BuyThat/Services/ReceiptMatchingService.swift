//
//  ReceiptMatchingService.swift
//  BuyThat
//

import Foundation
import SwiftData

enum ReceiptMatchingService {
    static func matchItems(
        _ parsedItems: [ParsedReceiptItem],
        store: Store,
        context: ModelContext
    ) -> [MatchedReceiptItem] {
        let allStoreInfo = (try? context.fetch(FetchDescriptor<StoreVariantInfo>())) ?? []
        let storeSpecific = allStoreInfo.filter { $0.store == store }

        return parsedItems.map { parsedItem in
            let matchResult = findMatchByAlias(
                receiptText: parsedItem.receiptText,
                storeVariantInfos: storeSpecific
            )
            return MatchedReceiptItem(parsedItem: parsedItem, matchResult: matchResult)
        }
    }

    private static func findMatchByAlias(
        receiptText: String,
        storeVariantInfos: [StoreVariantInfo]
    ) -> MatchedReceiptItem.MatchResult {
        let normalized = receiptText.trimmingCharacters(in: .whitespaces).lowercased()
        for storeInfo in storeVariantInfos {
            if storeInfo.receiptAliases.contains(where: { $0.lowercased() == normalized }) {
                if let variant = storeInfo.variant, let product = variant.product {
                    return .matched(product: product, variant: variant, storeInfo: storeInfo)
                }
            }
        }
        return .noMatch(suggestedName: cleanReceiptText(receiptText))
    }

    private static func cleanReceiptText(_ text: String) -> String {
        text.split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    // MARK: - Save Logic

    static func saveMatchedItems(
        _ items: [MatchedReceiptItem],
        store: Store,
        receiptDate: Date?,
        context: ModelContext
    ) -> ReceiptSaveResult {
        var pricesUpdated = 0

        let trip = ShoppingTrip(store: store, date: receiptDate ?? Date())
        context.insert(trip)

        let includedItems = items.filter(\.isIncluded)

        for (sortIndex, item) in includedItems.enumerated() {
            let product = item.effectiveProduct
            let variant = item.effectiveVariant
            let storeInfo = item.effectiveStoreInfo
            let price = item.effectivePrice ?? item.parsedItem.priceForStorage
            let quantity = item.effectiveQuantity

            // Only update price on existing store variant info
            if let storeInfo {
                storeInfo.pricePerUnit = price
                storeInfo.dateModified = Date()
                storeInfo.addReceiptAlias(item.parsedItem.receiptText)
                pricesUpdated += 1
            }

            let tripItem = ShoppingTripItem(
                trip: trip,
                product: product,
                variant: variant,
                storeVariantInfo: storeInfo,
                quantity: quantity,
                pricePerItem: item.parsedItem.price,
                unitPrice: item.parsedItem.unitPrice,
                receiptText: item.parsedItem.receiptText,
                productName: item.editedProductName,
                sortOrder: sortIndex
            )
            context.insert(tripItem)
        }

        try? context.save()

        return ReceiptSaveResult(pricesUpdated: pricesUpdated, shoppingTrip: trip)
    }
}
