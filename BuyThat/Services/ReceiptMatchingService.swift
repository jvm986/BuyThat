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
        let products = (try? context.fetch(FetchDescriptor<Product>())) ?? []
        let brands = (try? context.fetch(FetchDescriptor<Brand>())) ?? []

        return parsedItems.map { parsedItem in
            let matchResult = findMatch(
                for: parsedItem,
                store: store,
                products: products,
                brands: brands
            )
            return MatchedReceiptItem(parsedItem: parsedItem, matchResult: matchResult)
        }
    }

    private static func findMatch(
        for item: ParsedReceiptItem,
        store: Store,
        products: [Product],
        brands: [Brand]
    ) -> MatchedReceiptItem.MatchResult {
        guard let matchedProductName = item.matchedProductName else {
            return .noMatch(suggestedName: cleanReceiptText(item.receiptText))
        }

        // Find product by name (exact first, then case-insensitive)
        guard let product = findProduct(named: matchedProductName, in: products) else {
            return .noMatch(suggestedName: matchedProductName)
        }

        // Find matching variant (by brand if provided)
        let variant = findVariant(for: product, brandName: item.matchedBrandName, brands: brands)

        // Find existing StoreVariantInfo for this variant at this store
        let storeInfo: StoreVariantInfo?
        if let variant = variant {
            storeInfo = variant.storeInfo?.first { $0.store == store }
        } else {
            storeInfo = nil
        }

        return .matched(product: product, variant: variant, storeInfo: storeInfo)
    }

    private static func findProduct(named name: String, in products: [Product]) -> Product? {
        // Exact match first
        if let exact = products.first(where: { $0.name == name }) {
            return exact
        }
        // Case-insensitive fallback
        return products.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    private static func findVariant(
        for product: Product,
        brandName: String?,
        brands: [Brand]
    ) -> ProductVariant? {
        guard let variants = product.variants, !variants.isEmpty else {
            return nil
        }

        // If brand name provided, try to match
        if let brandName = brandName {
            let matchedBrand = brands.first { $0.name.localizedCaseInsensitiveCompare(brandName) == .orderedSame }
            if let matchedBrand = matchedBrand {
                if let variant = variants.first(where: { $0.brand == matchedBrand }) {
                    return variant
                }
            }
        }

        // If product has exactly one variant, use it
        if variants.count == 1 {
            return variants.first
        }

        return nil
    }

    private static func cleanReceiptText(_ text: String) -> String {
        // Basic cleanup: capitalize words, remove excess whitespace
        text.split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    // MARK: - Save Logic

    static func saveMatchedItems(
        _ items: [MatchedReceiptItem],
        store: Store,
        context: ModelContext
    ) -> ReceiptSaveResult {
        var pricesUpdated = 0
        var productsCreated = 0

        let includedItems = items.filter(\.isIncluded)

        for item in includedItems {
            switch item.matchResult {
            case .matched(let product, let variant, let storeInfo):
                if let variant = variant, let storeInfo = storeInfo {
                    // Case 1: Update existing StoreVariantInfo price
                    storeInfo.pricePerUnit = item.parsedItem.price
                    storeInfo.dateModified = Date()
                    pricesUpdated += 1
                } else if let variant = variant {
                    // Case 2: Create new StoreVariantInfo for existing variant
                    let newStoreInfo = StoreVariantInfo(
                        variant: variant,
                        store: store,
                        pricePerUnit: item.parsedItem.price
                    )
                    context.insert(newStoreInfo)
                    pricesUpdated += 1
                } else {
                    // Case 3: Product matched but no variant matched
                    let targetVariant: ProductVariant
                    if let variants = product.variants, variants.count == 1, let single = variants.first {
                        targetVariant = single
                    } else {
                        targetVariant = ProductVariant(product: product, baseUnit: .units)
                        context.insert(targetVariant)
                    }
                    let newStoreInfo = StoreVariantInfo(
                        variant: targetVariant,
                        store: store,
                        pricePerUnit: item.parsedItem.price
                    )
                    context.insert(newStoreInfo)
                    pricesUpdated += 1
                }

            case .noMatch:
                // Case 4: Create new product + variant + store info
                let newProduct = Product(name: item.editedProductName)
                context.insert(newProduct)

                let newVariant = ProductVariant(product: newProduct, baseUnit: .units)
                context.insert(newVariant)

                let newStoreInfo = StoreVariantInfo(
                    variant: newVariant,
                    store: store,
                    pricePerUnit: item.parsedItem.price
                )
                context.insert(newStoreInfo)
                productsCreated += 1
            }
        }

        try? context.save()

        return ReceiptSaveResult(pricesUpdated: pricesUpdated, productsCreated: productsCreated)
    }
}
