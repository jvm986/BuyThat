//
//  Product.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation
import SwiftData

@Model
final class Product {
    var name: String
    var dateCreated: Date
    var dateModified: Date
    var defaultMeasurementUnit: MeasurementUnit?
    var defaultUnitName: String?

    @Relationship(deleteRule: .nullify)
    var tags: [Tag]?

    @Relationship(deleteRule: .cascade, inverse: \ProductVariant.product)
    var variants: [ProductVariant]?

    @Relationship(deleteRule: .nullify, inverse: \ShoppingTripItem.product)
    var shoppingTripItems: [ShoppingTripItem]?

    init(name: String, notes: String? = nil, tags: [Tag]? = nil) {
        self.name = name
        self.tags = tags
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}

extension String {
    var pluralized: String {
        let n = self.lowercased()
        if n.hasSuffix("x") || n.hasSuffix("ch") || n.hasSuffix("sh") || n.hasSuffix("s") {
            return self + "es"
        } else if n.hasSuffix("y") && !n.hasSuffix("ay") && !n.hasSuffix("ey") && !n.hasSuffix("oy") && !n.hasSuffix("uy") {
            return String(self.dropLast()) + "ies"
        } else {
            return self + "s"
        }
    }
}
