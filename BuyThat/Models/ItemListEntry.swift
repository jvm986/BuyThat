//
//  ItemListEntry.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import Foundation
import SwiftData

@Model
final class ItemListEntry: BuyableItem {
    var quantity: String
    var dateAdded: Date
    var sortOrder: Int = 0

    var list: ItemList?

    var storeVariantInfo: StoreVariantInfo?
    var variant: ProductVariant?
    var product: Product?
    var purchaseUnit: PurchaseUnit?

    init(storeVariantInfo: StoreVariantInfo? = nil, variant: ProductVariant? = nil, product: Product? = nil, quantity: String = "1", purchaseUnit: PurchaseUnit? = nil, list: ItemList? = nil, sortOrder: Int = 0) {
        self.storeVariantInfo = storeVariantInfo
        self.variant = variant
        self.product = product
        self.quantity = quantity
        self.purchaseUnit = purchaseUnit
        self.list = list
        self.dateAdded = Date()
        self.sortOrder = sortOrder
    }
}
