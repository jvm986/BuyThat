//
//  Tag.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation
import SwiftData

@Model
final class Tag {
    var name: String
    var dateCreated: Date

    @Relationship(deleteRule: .nullify, inverse: \Product.tags)
    var products: [Product]?

    init(name: String) {
        self.name = name
        self.dateCreated = Date()
    }
}
