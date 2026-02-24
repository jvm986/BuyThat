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
        var productsCreated = 0

        let trip = ShoppingTrip(store: store, date: receiptDate ?? Date())
        context.insert(trip)

        let includedItems = items.filter(\.isIncluded)

        for (sortIndex, item) in includedItems.enumerated() {
            let product = item.effectiveProduct
            let variant = item.effectiveVariant
            let storeInfo = item.effectiveStoreInfo

            var resolvedProduct: Product?
            var resolvedVariant: ProductVariant?
            var resolvedStoreInfo: StoreVariantInfo?

            let price = item.effectivePrice ?? item.parsedItem.priceForStorage
            let quantity = item.effectiveQuantity

            if let product, let variant, let storeInfo {
                storeInfo.pricePerUnit = price
                storeInfo.dateModified = Date()
                resolvedProduct = product
                resolvedVariant = variant
                resolvedStoreInfo = storeInfo
                pricesUpdated += 1
            } else if let product, let variant {
                let newStoreInfo = StoreVariantInfo(
                    variant: variant,
                    store: store,
                    pricePerUnit: price
                )
                context.insert(newStoreInfo)
                resolvedProduct = product
                resolvedVariant = variant
                resolvedStoreInfo = newStoreInfo
                pricesUpdated += 1
            } else if let product {
                let targetVariant: ProductVariant
                if let variants = product.variants, variants.count == 1, let single = variants.first {
                    targetVariant = single
                } else {
                    targetVariant = ProductVariant(product: product, baseUnit: item.editedUnit)
                    context.insert(targetVariant)
                }
                let newStoreInfo = StoreVariantInfo(
                    variant: targetVariant,
                    store: store,
                    pricePerUnit: price
                )
                context.insert(newStoreInfo)
                resolvedProduct = product
                resolvedVariant = targetVariant
                resolvedStoreInfo = newStoreInfo
                pricesUpdated += 1
            } else {
                let newProduct = Product(name: item.editedProductName)
                context.insert(newProduct)

                let newVariant = ProductVariant(product: newProduct, baseUnit: item.editedUnit)
                context.insert(newVariant)

                let newStoreInfo = StoreVariantInfo(
                    variant: newVariant,
                    store: store,
                    pricePerUnit: price
                )
                context.insert(newStoreInfo)
                resolvedProduct = newProduct
                resolvedVariant = newVariant
                resolvedStoreInfo = newStoreInfo
                productsCreated += 1
            }

            // Auto-learn: add receipt text as alias for future matching
            resolvedStoreInfo?.addReceiptAlias(item.parsedItem.receiptText)

            let tripItem = ShoppingTripItem(
                trip: trip,
                product: resolvedProduct,
                variant: resolvedVariant,
                storeVariantInfo: resolvedStoreInfo,
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

        return ReceiptSaveResult(pricesUpdated: pricesUpdated, productsCreated: productsCreated, shoppingTrip: trip)
    }
}
