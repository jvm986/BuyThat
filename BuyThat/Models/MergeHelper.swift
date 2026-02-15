//
//  MergeHelper.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import Foundation
import SwiftData

enum MergeHelper {

    /// Merges two quantity strings. If both are numeric, sums them.
    /// Formats as integer if the result is whole, otherwise decimal.
    /// Falls back to concatenation with "+" if either is non-numeric.
    static func mergeQuantities(_ q1: String, _ q2: String) -> String {
        if let v1 = Double(q1), let v2 = Double(q2) {
            let sum = v1 + v2
            if sum == sum.rounded() {
                return String(Int(sum))
            }
            return String(sum)
        }
        return "\(q1)+\(q2)"
    }

    /// Finds a matching ToBuyItem for a given BuyableItem based on specificity level.
    ///
    /// Matching rules:
    /// - Store-level: same StoreVariantInfo + same PurchaseUnit
    /// - Variant-level: same ProductVariant + same PurchaseUnit (no StoreVariantInfo on either)
    /// - Product-level: same Product (no variant or StoreVariantInfo on either)
    static func findMatch(for entry: some BuyableItem, in items: [ToBuyItem]) -> ToBuyItem? {
        for item in items {
            // Store-level match
            if let entrySVI = entry.storeVariantInfo,
               let itemSVI = item.storeVariantInfo,
               entrySVI.persistentModelID == itemSVI.persistentModelID,
               entry.purchaseUnit?.persistentModelID == item.purchaseUnit?.persistentModelID {
                return item
            }

            // Variant-level match
            if entry.storeVariantInfo == nil,
               item.storeVariantInfo == nil,
               let entryV = entry.variant,
               let itemV = item.variant,
               entryV.persistentModelID == itemV.persistentModelID,
               entry.purchaseUnit?.persistentModelID == item.purchaseUnit?.persistentModelID {
                return item
            }

            // Product-level match
            if entry.storeVariantInfo == nil, entry.variant == nil,
               item.storeVariantInfo == nil, item.variant == nil,
               let entryP = entry.product,
               let itemP = item.product,
               entryP.persistentModelID == itemP.persistentModelID {
                return item
            }
        }
        return nil
    }
}
