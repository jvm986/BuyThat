//
//  PriceHistory.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation
import SwiftData

@Model
final class PriceHistory {
    var pricePerUnit: Decimal
    var dateRecorded: Date

    @Relationship(deleteRule: .nullify)
    var storeVariantInfo: StoreVariantInfo?

    @Relationship(deleteRule: .nullify)
    var pricingUnit: PurchaseUnit?

    init(pricePerUnit: Decimal, pricingUnit: PurchaseUnit? = nil, storeVariantInfo: StoreVariantInfo?, dateRecorded: Date = Date()) {
        self.pricePerUnit = pricePerUnit
        self.pricingUnit = pricingUnit
        self.storeVariantInfo = storeVariantInfo
        self.dateRecorded = dateRecorded
    }
}

extension PriceHistory {
    var store: Store? {
        storeVariantInfo?.store
    }

    var variant: ProductVariant? {
        storeVariantInfo?.variant
    }
}
