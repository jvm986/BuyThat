//
//  Brand.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation
import SwiftData

@Model
final class Brand {
    var name: String
    var dateCreated: Date

    @Relationship(deleteRule: .nullify, inverse: \ProductVariant.brand)
    var variants: [ProductVariant]?

    init(name: String) {
        self.name = name
        self.dateCreated = Date()
    }
}
