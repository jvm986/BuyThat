//
//  ProductVariant.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation
import SwiftData

@Model
final class ProductVariant {
    var baseUnit: MeasurementUnit
    var dateCreated: Date
    var dateModified: Date

    @Relationship(deleteRule: .nullify)
    var product: Product?

    @Relationship(deleteRule: .nullify)
    var brand: Brand?

    @Relationship(deleteRule: .cascade, inverse: \StoreVariantInfo.variant)
    var storeInfo: [StoreVariantInfo]?

    @Relationship(deleteRule: .cascade)
    var purchaseUnits: [PurchaseUnit]?

    init(product: Product?, brand: Brand? = nil, baseUnit: MeasurementUnit = .units) {
        self.product = product
        self.brand = brand
        self.baseUnit = baseUnit
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}

extension ProductVariant {
    var displayName: String {
        var parts: [String] = []

        if let brand = brand?.name {
            parts.append(brand)
        }

        if let product = product?.name {
            parts.append(product)
        }

        return parts.joined(separator: " ")
    }

    var stores: [Store] {
        storeInfo?.compactMap { $0.store } ?? []
    }

    func priceAt(store: Store) -> Decimal? {
        storeInfo?.first { $0.store == store }?.pricePerUnit
    }

    var lowestPrice: Decimal? {
        storeInfo?.compactMap { $0.pricePerUnit }.min()
    }
}
