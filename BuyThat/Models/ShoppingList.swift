//
//  ShoppingList.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation
import SwiftData

@Model
final class ShoppingList {
    var name: String
    var dateCreated: Date
    var dateModified: Date

    @Relationship(deleteRule: .cascade, inverse: \ShoppingListItem.list)
    var items: [ShoppingListItem]?

    init(name: String) {
        self.name = name
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}
