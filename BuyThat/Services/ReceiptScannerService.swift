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
        let result = try await AzureDocumentIntelligenceClient.analyzeReceipt(image: image)

        let items = result.items.map { item in
            ParsedReceiptItem(
                receiptText: item.description,
                price: item.totalPrice ?? item.price ?? 0,
                quantity: item.quantity ?? 1,
                unitPrice: (item.quantity ?? 1) > 1 ? item.price : nil
            )
        }

        let stores = (try? context.fetch(FetchDescriptor<Store>())) ?? []
        let matchedStore = stores.first {
            $0.name.localizedCaseInsensitiveContains(result.merchantName ?? "")
            || (result.merchantName ?? "").localizedCaseInsensitiveContains($0.name)
        }

        return ParsedReceipt(
            storeName: result.merchantName,
            matchedStoreName: matchedStore?.name,
            receiptDate: parseDate(result.transactionDate),
            items: items
        )
    }

    private static func parseDate(_ dateString: String?) -> Date? {
        guard let dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}
