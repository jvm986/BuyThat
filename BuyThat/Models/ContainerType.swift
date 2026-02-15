//
//  ContainerType.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import Foundation
import SwiftData

@Model
final class ContainerType {
    var name: String
    var isSystem: Bool
    var dateCreated: Date

    @Relationship(deleteRule: .nullify, inverse: \PurchaseUnit.containerType)
    var purchaseUnits: [PurchaseUnit]?

    init(name: String, isSystem: Bool = false) {
        self.name = name
        self.isSystem = isSystem
        self.dateCreated = Date()
    }
}

extension ContainerType {
    static let systemDefaults = [
        "bottle", "box", "bag", "packet", "can", "jar", "carton", "bunch", "pack", "tin"
    ]
}
