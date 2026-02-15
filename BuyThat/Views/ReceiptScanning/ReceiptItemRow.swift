//
//  ReceiptItemRow.swift
//  BuyThat
//

import SwiftUI
import SwiftData

struct ReceiptItemRow: View {
    @Binding var item: MatchedReceiptItem

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                item.isIncluded.toggle()
            } label: {
                Image(systemName: item.isIncluded ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isIncluded ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            matchIndicator
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.parsedItem.receiptText)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let productName = item.effectiveProduct?.name {
                    Text(productName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(item.editedProductName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.parsedItem.price as NSDecimalNumber, formatter: currencyFormatter)
                    .foregroundStyle(.secondary)
                if let unitPrice = item.parsedItem.unitPrice,
                   let unitPriceUnit = item.parsedItem.unitPriceUnit {
                    Text("\(unitPrice as NSDecimalNumber, formatter: currencyFormatter)/\(unitPriceUnit)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var matchIndicator: some View {
        if item.effectiveStoreInfo != nil {
            Image(systemName: "circle.fill")
                .foregroundStyle(.green)
        } else if item.effectiveProduct != nil {
            Image(systemName: "circle.fill")
                .foregroundStyle(.yellow)
        } else {
            Image(systemName: "circle.fill")
                .foregroundStyle(.red)
        }
    }
}
