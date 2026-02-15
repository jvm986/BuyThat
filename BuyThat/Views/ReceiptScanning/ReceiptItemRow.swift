//
//  ReceiptItemRow.swift
//  BuyThat
//

import SwiftUI

struct ReceiptItemRow: View {
    @Binding var item: MatchedReceiptItem

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter
    }

    var body: some View {
        DisclosureGroup {
            expandedContent
        } label: {
            rowLabel
        }
    }

    // MARK: - Collapsed Label

    private var rowLabel: some View {
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

                if item.parsedItem.quantity > 1 {
                    Text("Qty: \(item.parsedItem.quantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(item.parsedItem.price as NSDecimalNumber, formatter: currencyFormatter)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var matchIndicator: some View {
        switch item.matchResult {
        case .matched(_, _, let storeInfo):
            if storeInfo != nil {
                Image(systemName: "circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "circle.fill")
                    .foregroundStyle(.yellow)
            }
        case .noMatch:
            Image(systemName: "circle.fill")
                .foregroundStyle(.red)
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        switch item.matchResult {
        case .matched(let product, let variant, let storeInfo):
            matchedContent(product: product, variant: variant, storeInfo: storeInfo)
        case .noMatch:
            unmatchedContent
        }
    }

    private func matchedContent(product: Product, variant: ProductVariant?, storeInfo: StoreVariantInfo?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Product") {
                Text(product.name)
            }

            if let variant {
                LabeledContent("Variant") {
                    Text(variant.displayNameShort)
                }
            }

            if let storeInfo, let currentPrice = storeInfo.pricePerUnit {
                LabeledContent("Current Price") {
                    Text(currentPrice as NSDecimalNumber, formatter: currencyFormatter)
                }
                LabeledContent("New Price") {
                    Text(item.parsedItem.price as NSDecimalNumber, formatter: currencyFormatter)
                        .foregroundStyle(item.parsedItem.price != currentPrice ? .orange : .secondary)
                }
            } else {
                LabeledContent("Status") {
                    Text("New price entry")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.subheadline)
    }

    private var unmatchedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Product Name", text: $item.editedProductName)
                .textFieldStyle(.roundedBorder)

            Text("A new product, variant, and store price will be created.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
