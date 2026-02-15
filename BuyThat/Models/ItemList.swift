//
//  ItemList.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import Foundation
import SwiftData

@Model
final class ItemList {
    var name: String
    var dateCreated: Date
    var dateModified: Date

    @Relationship(deleteRule: .cascade, inverse: \ItemListEntry.list)
    var entries: [ItemListEntry]?

    init(name: String) {
        self.name = name
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}
