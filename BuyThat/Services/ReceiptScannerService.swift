//
//  ReceiptScannerService.swift
//  BuyThat
//

import Foundation
import SwiftData
import UIKit

enum ReceiptScannerService {
    static func scanReceipt(
        image: UIImage,
        context: ModelContext
    ) async throws -> ParsedReceipt {
        let products = try context.fetch(FetchDescriptor<Product>(sortBy: [SortDescriptor(\.name)]))
        let brands = try context.fetch(FetchDescriptor<Brand>(sortBy: [SortDescriptor(\.name)]))
        let stores = try context.fetch(FetchDescriptor<Store>(sortBy: [SortDescriptor(\.name)]))
        let tags = try context.fetch(FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)]))

        let productNames = products.map(\.name)
        let brandNames = brands.map(\.name)
        let storeNames = stores.map(\.name)
        let tagNames = tags.map(\.name)

        let response = try await OpenAIClient.analyzeReceipt(
            image: image,
            existingProducts: productNames,
            existingBrands: brandNames,
            existingStores: storeNames,
            existingTags: tagNames
        )

        let receiptDate: Date?
        if let dateString = response.receiptDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            receiptDate = formatter.date(from: dateString)
        } else {
            receiptDate = nil
        }

        let items = response.items.map { ParsedReceiptItem(from: $0) }

        return ParsedReceipt(
            storeName: response.storeName,
            matchedStoreName: response.matchedStoreName,
            receiptDate: receiptDate,
            items: items
        )
    }
}
