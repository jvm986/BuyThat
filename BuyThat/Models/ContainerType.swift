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
        "bottle", "box", "bag", "packet", "can", "jar", "carton", "bunch", "container", "tin", "stick"
    ]

    var pluralName: String {
        let n = name.lowercased()
        if n.hasSuffix("x") || n.hasSuffix("ch") || n.hasSuffix("sh") || n.hasSuffix("s") {
            return name + "es"
        } else if n.hasSuffix("y") && !n.hasSuffix("ay") && !n.hasSuffix("ey") && !n.hasSuffix("oy") && !n.hasSuffix("uy") {
            return String(name.dropLast()) + "ies"
        } else {
            return name + "s"
        }
    }
}
