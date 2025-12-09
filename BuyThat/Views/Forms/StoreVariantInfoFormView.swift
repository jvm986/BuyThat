//
//  StoreVariantInfoFormView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct StoreVariantInfoFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let storeVariantInfo: StoreVariantInfo?
    let onSave: (StoreVariantInfo) -> Void

    @State private var selectedVariant: ProductVariant?
    @State private var selectedStore: Store?
    @State private var priceText: String
    @State private var selectedPricingUnit: PurchaseUnit?
    @State private var editingVariant: ProductVariant?
    @State private var editingStore: Store?
    @State private var showingVariantSelection = false
    @State private var showingStoreSelection = false

    init(storeVariantInfo: StoreVariantInfo? = nil, prefilledVariant: ProductVariant? = nil, onSave: @escaping (StoreVariantInfo) -> Void) {
        self.storeVariantInfo = storeVariantInfo
        self.onSave = onSave
        _selectedVariant = State(initialValue: storeVariantInfo?.variant ?? prefilledVariant)
        _selectedStore = State(initialValue: storeVariantInfo?.store)
        _priceText = State(initialValue: storeVariantInfo?.pricePerUnit.map { "\($0)" } ?? "")
        _selectedPricingUnit = State(initialValue: storeVariantInfo?.pricingUnit)
    }

    private var price: Decimal? {
        if priceText.isEmpty { return nil }
        // Replace comma with period for decimal parsing
        let normalizedText = priceText.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalizedText)
    }

    private var canSave: Bool {
        selectedVariant != nil && selectedStore != nil
    }

    private var pricePlaceholder: String {
        if let unit = selectedPricingUnit {
            return "Price per \(unit.displayName)"
        } else if let variant = selectedVariant {
            return "Price per \(variant.baseUnit.symbol)"
        }
        return "Price"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product Variant") {
                    HStack {
                        Text("Variant")
                        Spacer()
                        if let variant = selectedVariant {
                            Text(variant.displayName)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Required")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingVariantSelection = true
                    }
                    .onLongPressGesture {
                        if let variant = selectedVariant {
                            editingVariant = variant
                        }
                    }
                }

                Section("Store") {
                    HStack {
                        Text("Store")
                        Spacer()
                        if let store = selectedStore {
                            Text(store.name)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Required")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingStoreSelection = true
                    }
                    .onLongPressGesture {
                        if let store = selectedStore {
                            editingStore = store
                        }
                    }
                }

                if let variant = selectedVariant, let units = variant.purchaseUnits, !units.isEmpty {
                    Section("Pricing Unit") {
                        Picker("Unit", selection: $selectedPricingUnit) {
                            Text("Base unit (\(variant.baseUnit.symbol))").tag(nil as PurchaseUnit?)
                            ForEach(units) { unit in
                                Text(unit.displayName).tag(unit as PurchaseUnit?)
                            }
                        }
                    }
                }

                Section("Price") {
                    TextField(pricePlaceholder, text: $priceText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(storeVariantInfo == nil ? "New Store Info" : "Edit Store Info")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingVariantSelection) {
                NavigationStack {
                    SelectProductVariantView { variant in
                        selectedVariant = variant
                        showingVariantSelection = false
                    }
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingStoreSelection) {
                NavigationStack {
                    SelectStoreView { store in
                        selectedStore = store
                        showingStoreSelection = false
                    }
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingVariant) { variant in
                ProductVariantFormView(variant: variant) { _ in
                    editingVariant = nil
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingStore) { store in
                StoreFormView(store: store) { _ in
                    editingStore = nil
                }
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func save() {
        guard let variant = selectedVariant, let store = selectedStore else { return }

        let storeVariantInfoToSave: StoreVariantInfo
        if let existing = storeVariantInfo {
            existing.variant = variant
            existing.store = store
            existing.pricePerUnit = price
            existing.pricingUnit = selectedPricingUnit
            existing.pricingUnitConversion = selectedPricingUnit?.conversionToBase
            existing.dateModified = Date()
            storeVariantInfoToSave = existing
        } else {
            storeVariantInfoToSave = StoreVariantInfo(
                variant: variant,
                store: store,
                pricePerUnit: price,
                pricingUnit: selectedPricingUnit
            )
            modelContext.insert(storeVariantInfoToSave)
        }
        try? modelContext.save()
        onSave(storeVariantInfoToSave)
        dismiss()
    }
}

#Preview {
    StoreVariantInfoFormView { info in
        print("Saved: \(info.displayName)")
    }
    .modelContainer(PreviewContainer.sample)
}
