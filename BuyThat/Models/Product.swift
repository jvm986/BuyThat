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

    @Relationship(deleteRule: .nullify)
    var tags: [Tag]?

    @Relationship(deleteRule: .cascade, inverse: \ProductVariant.product)
    var variants: [ProductVariant]?

    init(name: String, notes: String? = nil, tags: [Tag]? = nil) {
        self.name = name
        self.tags = tags
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}
