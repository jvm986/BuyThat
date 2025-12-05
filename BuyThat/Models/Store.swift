//
//  Store.swift
//  BuyThat
//
//  Created by James Maguire on 01.12.25.
//

import Foundation
import SwiftData

@Model
final class Store {
    var name: String
    var dateCreated: Date

    @Relationship(deleteRule: .cascade, inverse: \StoreVariantInfo.store)
    var storeVariantInfos: [StoreVariantInfo]?

    init(name: String, notes: String? = nil) {
        self.name = name
        self.dateCreated = Date()
    }
}
