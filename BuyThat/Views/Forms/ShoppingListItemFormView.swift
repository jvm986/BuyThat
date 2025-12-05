//
//  ShoppingListItemFormView.swift
//  BuyThat
//
//  Created by Claude on 05.12.25.
//

import SwiftUI
import SwiftData

struct ShoppingListItemFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StoreVariantInfo.dateModified, order: .reverse) private var allStoreVariantInfos: [StoreVariantInfo]

    let shoppingList: ShoppingList
    let item: ShoppingListItem?
    let onSave: (ShoppingListItem) -> Void

    @State private var selectedStoreVariantInfo: StoreVariantInfo?
    @State private var quantity: String
    @State private var selectedPurchaseUnit: PurchaseUnit?
    @State private var showingStoreVariantSelection = false
    @State private var editingStoreVariantInfo: StoreVariantInfo?

    init(shoppingList: ShoppingList, item: ShoppingListItem? = nil, onSave: @escaping (ShoppingListItem) -> Void) {
        self.shoppingList = shoppingList
        self.item = item
        self.onSave = onSave
        _quantity = State(initialValue: item?.quantity ?? "1")
        _selectedStoreVariantInfo = State(initialValue: item?.storeVariantInfo)
        _selectedPurchaseUnit = State(initialValue: item?.purchaseUnit)
    }

    private var canSave: Bool {
        selectedStoreVariantInfo != nil && !quantity.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    HStack {
                        Text("Item")
                        Spacer()
                        if let info = selectedStoreVariantInfo {
                            Text(info.displayName)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Required")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingStoreVariantSelection = true
                    }
                    .onLongPressGesture {
                        if let info = selectedStoreVariantInfo {
                            editingStoreVariantInfo = info
                        }
                    }
                }

                Section("Details") {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)

                    if let variant = selectedStoreVariantInfo?.variant, let units = variant.purchaseUnits, !units.isEmpty {
                        Picker("Unit", selection: $selectedPurchaseUnit) {
                            Text("Base measurement (\(variant.baseUnit.symbol))").tag(nil as PurchaseUnit?)
                            ForEach(units) { unit in
                                Text(unit.displayName).tag(unit as PurchaseUnit?)
                            }
                        }
                    }

                    if let info = selectedStoreVariantInfo, let estimated = estimatedPrice(for: info) {
                        HStack {
                            Text("Estimated Price")
                            Spacer()
                            Text(estimated)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "Add Item" : "Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(item == nil ? "Add" : "Save") { save() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingStoreVariantSelection) {
                NavigationStack {
                    SelectStoreVariantInfoView { info in
                        selectedStoreVariantInfo = info
                        showingStoreVariantSelection = false
                    }
                }
            }
            .sheet(item: $editingStoreVariantInfo) { info in
                StoreVariantInfoFormView(storeVariantInfo: info) { _ in
                    editingStoreVariantInfo = nil
                }
            }
        }
    }

    private func estimatedPrice(for info: StoreVariantInfo) -> String? {
        guard let numericValue = Double(quantity) else { return nil }

        let pricePerSelectedUnit: Decimal?
        if let unit = selectedPurchaseUnit {
            // Purchase unit selected - convert from pricing unit
            pricePerSelectedUnit = info.priceForPurchaseUnit(unit)
        } else {
            // Base unit selected - need to convert from pricing unit to base unit
            guard let price = info.pricePerUnit else { return nil }

            if let pricingUnit = info.pricingUnit {
                // Convert from pricing unit to base unit
                // conversionToBase represents: X pricing_units = 1 base_unit
                // Example: 800g = 1 unit, so conversionToBase = 800
                // If price per g = €0.01, then price per unit = €0.01 × 800 = €8.00
                pricePerSelectedUnit = price * Decimal(pricingUnit.conversionToBase)
            } else {
                // Pricing unit is the base unit
                pricePerSelectedUnit = price
            }
        }

        guard let priceValue = pricePerSelectedUnit else { return nil }
        let total = priceValue * Decimal(numericValue)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: total as NSDecimalNumber)
    }

    private func save() {
        guard let storeVariantInfo = selectedStoreVariantInfo else { return }

        let itemToSave: ShoppingListItem
        if let existing = item {
            existing.storeVariantInfo = storeVariantInfo
            existing.quantity = quantity
            existing.purchaseUnit = selectedPurchaseUnit
            itemToSave = existing
        } else {
            itemToSave = ShoppingListItem(
                storeVariantInfo: storeVariantInfo,
                quantity: quantity,
                purchaseUnit: selectedPurchaseUnit,
                list: shoppingList
            )
            modelContext.insert(itemToSave)
        }

        try? modelContext.save()
        onSave(itemToSave)
        dismiss()
    }
}

#Preview {
    @Previewable @Query var shoppingLists: [ShoppingList]
    if let list = shoppingLists.first {
        ShoppingListItemFormView(shoppingList: list) { _ in
            print("Item saved")
        }
        .modelContainer(PreviewContainer.sample)
    }
}
