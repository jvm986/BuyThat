//
//  ShoppingTrip.swift
//  BuyThat
//

import Foundation
import SwiftData

@Model
final class ShoppingTrip {
    var date: Date
    var dateCreated: Date
    var storeName: String

    @Relationship(deleteRule: .nullify)
    var store: Store?

    @Relationship(deleteRule: .cascade, inverse: \ShoppingTripItem.trip)
    var items: [ShoppingTripItem]?

    init(store: Store?, date: Date) {
        self.store = store
        self.storeName = store?.name ?? "Unknown Store"
        self.date = date
        self.dateCreated = Date()
    }
}

extension ShoppingTrip {
    var displayStoreName: String {
        store?.name ?? storeName
    }

    var itemCount: Int {
        items?.count ?? 0
    }

    var totalSpent: Decimal {
        items?.reduce(Decimal.zero) { $0 + $1.lineTotal } ?? Decimal.zero
    }

    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: totalSpent as NSDecimalNumber) ?? "\(totalSpent)"
    }
}
