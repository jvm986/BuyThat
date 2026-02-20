//
//  ReceiptItemDetailView.swift
//  BuyThat
//

import SwiftUI
import SwiftData

struct ReceiptItemDetailView: View {
    @Binding var item: MatchedReceiptItem
    let store: Store

    @State private var showingStoreInfoSheet = false

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter
    }

    var body: some View {
        List {
            receiptInfoSection
            storeItemSection
            priceQuantitySection
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingStoreInfoSheet) {
            NavigationStack {
                SelectStoreVariantInfoView(filterStore: store) { storeInfo in
                    item.hasStoreInfoOverride = true
                    item.overrideStoreInfo = storeInfo
                    item.editedProductName = storeInfo.variant?.product?.name ?? item.editedProductName
                }
            }
        }
    }

    // MARK: - Receipt Info Section

    private var receiptInfoSection: some View {
        Section("Receipt Info") {
            LabeledContent("Receipt Text") {
                Text(item.parsedItem.receiptText)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Line Total") {
                Text(item.parsedItem.price as NSDecimalNumber, formatter: currencyFormatter)
                    .foregroundStyle(.secondary)
            }
            if item.parsedItem.quantity > 1 {
                LabeledContent("Quantity") {
                    Text("\(item.parsedItem.quantity)")
                        .foregroundStyle(.secondary)
                }
            }
            if let unitPrice = item.parsedItem.unitPrice,
               let unitPriceUnit = item.parsedItem.unitPriceUnit {
                LabeledContent("Unit Price") {
                    Text("\(unitPrice as NSDecimalNumber, formatter: currencyFormatter)/\(unitPriceUnit)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Store Item Section

    private var storeItemSection: some View {
        Section("Store Item") {
            Button {
                showingStoreInfoSheet = true
            } label: {
                HStack {
                    if let storeInfo = item.effectiveStoreInfo {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(storeInfo.variant?.displayName ?? "Unknown")
                                .foregroundStyle(.primary)
                            if let price = storeInfo.formattedPricePerUnit {
                                Text(price)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else if let variant = item.effectiveVariant {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(variant.displayName)
                                .foregroundStyle(.primary)
                            Text("No store pricing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if let product = item.effectiveProduct {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.name)
                                .foregroundStyle(.primary)
                            Text("Product only — no variant or store pricing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Select Store Item")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Price & Quantity Section

    private var priceQuantitySection: some View {
        Section("Price & Quantity") {
            HStack {
                Text("Price")
                Spacer()
                TextField("0.00", text: $item.editedPrice)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }

            HStack {
                Text("Quantity")
                Spacer()
                TextField("1", text: $item.editedQuantity)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }

            Picker("Unit", selection: $item.editedUnit) {
                ForEach(MeasurementUnit.groupedByFamily, id: \.family) { group in
                    ForEach(group.units, id: \.self) { unit in
                        Text(unit.displayLabel).tag(unit)
                    }
                }
            }

            if let storeInfo = item.effectiveStoreInfo,
               let currentPrice = storeInfo.pricePerUnit {
                let unitLabel = storeInfo.pricingUnit?.displayName ?? storeInfo.variant?.baseUnit.symbol ?? "unit"
                HStack {
                    Text("Existing Price")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(currentPrice as NSDecimalNumber, formatter: currencyFormatter)/\(unitLabel)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
