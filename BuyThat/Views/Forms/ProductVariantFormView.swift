//
//  ProductVariantFormView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ProductVariantFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onSave: (ProductVariant) -> Void

    @State private var variant: ProductVariant?
    @State private var selectedProduct: Product?
    @State private var selectedBrand: Brand?
    @State private var detail: String
    @State private var selectedBaseUnit: MeasurementUnit
    @State private var originalBaseUnit: MeasurementUnit?
    @State private var editingProduct: Product?
    @State private var editingBrand: Brand?
    @State private var showingProductSelection = false
    @State private var showingBrandSelection = false
    @State private var variantForPurchaseUnit: ProductVariant?
    @State private var editingPurchaseUnit: PurchaseUnit?
    @State private var refreshTrigger = UUID()
    @State private var showingBaseUnitChangeConfirmation = false
    @State private var pendingBaseUnit: MeasurementUnit?
    @State private var showingCreateStoreInfo = false
    @State private var editingStoreInfo: StoreVariantInfo?

    init(variant: ProductVariant? = nil, prefilledProduct: Product? = nil, onSave: @escaping (ProductVariant) -> Void) {
        self.onSave = onSave
        _variant = State(initialValue: variant)
        _selectedProduct = State(initialValue: variant?.product ?? prefilledProduct)
        _selectedBrand = State(initialValue: variant?.brand)
        _detail = State(initialValue: variant?.detail ?? "")
        _selectedBaseUnit = State(initialValue: variant?.baseUnit ?? .units)
        _originalBaseUnit = State(initialValue: variant?.baseUnit)
    }

    private var canSave: Bool {
        selectedProduct != nil
    }

    private var sortedStoreInfos: [StoreVariantInfo] {
        (variant?.storeInfo ?? []).sorted { ($0.store?.name ?? "") < ($1.store?.name ?? "") }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    HStack {
                        Text("Product")
                        Spacer()
                        if let product = selectedProduct {
                            Text(product.name)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Required")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("ProductSelector")
                    .onTapGesture {
                        showingProductSelection = true
                    }
                    .onLongPressGesture {
                        if let product = selectedProduct {
                            editingProduct = product
                        }
                    }
                }

                Section("Brand") {
                    HStack {
                        Text("Brand")
                        Spacer()
                        if let brand = selectedBrand {
                            Text(brand.name)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Optional")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingBrandSelection = true
                    }
                    .onLongPressGesture {
                        if let brand = selectedBrand {
                            editingBrand = brand
                        }
                    }

                    if selectedBrand != nil {
                        Button("Clear Brand") {
                            selectedBrand = nil
                        }
                    }
                }

                Section {
                    TextField("Detail (optional)", text: $detail, prompt: Text("Detail"))
                } header: {
                    Text("Additional Detail")
                }

                Section {
                    Picker("Base", selection: Binding(
                        get: { selectedBaseUnit },
                        set: { newValue in
                            handleBaseUnitChange(newValue)
                        }
                    )) {
                        Text("Count (units)").tag(MeasurementUnit.units)
                        Text("Weight (kg)").tag(MeasurementUnit.kilograms)
                        Text("Volume (L)").tag(MeasurementUnit.liters)
                    }
                    .pickerStyle(.menu)

                    if variant == nil {
                        Button {
                            saveAndContinue()
                        } label: {
                            Label("Save to add purchase units", systemImage: "checkmark.circle")
                        }
                        .disabled(!canSave)
                    }
                } header: {
                    Text("Measurement Type")
                }

                if let variant = variant {
                    Section {
                        if let units = variant.purchaseUnits, !units.isEmpty {
                            ForEach(units) { unit in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(unit.displayName)
                                            .font(.body)
                                        Text(unit.displayWithConversion)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingPurchaseUnit = unit
                                }
                            }
                            .onDelete { offsets in
                                deletePurchaseUnits(at: offsets, from: units)
                            }
                        } else {
                            Text("No purchase units")
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            variantForPurchaseUnit = variant
                        } label: {
                            Label("Add Purchase Unit", systemImage: "plus.circle.fill")
                        }
                    } header: {
                        Text("Purchase Units")
                    }
                    .id(refreshTrigger)
                }

                if variant != nil {
                    Section {
                        if sortedStoreInfos.isEmpty {
                            Text("Not available in any stores")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(sortedStoreInfos) { info in
                                Button {
                                    editingStoreInfo = info
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(info.store?.name ?? "Unknown")
                                            if let price = info.formattedPrice {
                                                Text(price)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { offsets in
                                deleteStoreInfos(at: offsets)
                            }
                        }

                        Button {
                            showingCreateStoreInfo = true
                        } label: {
                            Label("Add Store", systemImage: "plus.circle.fill")
                        }
                    } header: {
                        Text("Stores (\(sortedStoreInfos.count))")
                    }
                    .id(refreshTrigger)
                }
            }
            .navigationTitle(variant == nil ? "New Variant" : "Edit Variant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // If we created a variant but didn't finish, still notify parent
                        if let v = variant {
                            onSave(v)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingProductSelection) {
                NavigationStack {
                    SelectProductView { product in
                        selectedProduct = product
                        showingProductSelection = false
                    }
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingBrandSelection) {
                NavigationStack {
                    SelectBrandView { brand in
                        selectedBrand = brand
                        showingBrandSelection = false
                    }
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingProduct) { product in
                ProductFormView(product: product) { _ in
                    editingProduct = nil
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingBrand) { brand in
                BrandFormView(brand: brand) { _ in
                    editingBrand = nil
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $variantForPurchaseUnit) { variant in
                PurchaseUnitFormView(variant: variant) { _ in
                    refreshTrigger = UUID()
                    variantForPurchaseUnit = nil
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingPurchaseUnit) { unit in
                PurchaseUnitFormView(variant: variant!, purchaseUnit: unit) { _ in
                    refreshTrigger = UUID()
                    editingPurchaseUnit = nil
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingCreateStoreInfo) {
                StoreVariantInfoFormView(prefilledVariant: variant) { _ in
                    refreshTrigger = UUID()
                    showingCreateStoreInfo = false
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingStoreInfo) { info in
                StoreVariantInfoFormView(storeVariantInfo: info) { _ in
                    refreshTrigger = UUID()
                    editingStoreInfo = nil
                }
                .presentationDragIndicator(.visible)
            }
            .alert(
                "Change Base Measurement?",
                isPresented: $showingBaseUnitChangeConfirmation,
                presenting: pendingBaseUnit
            ) { newUnit in
                Button("Change and Clear Units", role: .destructive) {
                    applyBaseUnitChange(newUnit)
                }
                Button("Cancel", role: .cancel) {
                    pendingBaseUnit = nil
                }
            } message: { _ in
                Text("This will clear all purchase units.")
            }
        }
    }

    private func handleBaseUnitChange(_ newValue: MeasurementUnit) {
        // If editing existing variant with purchase units, show confirmation
        if let existingVariant = variant,
           let units = existingVariant.purchaseUnits,
           !units.isEmpty,
           let original = originalBaseUnit,
           newValue != original {
            pendingBaseUnit = newValue
            showingBaseUnitChangeConfirmation = true
        } else {
            // No purchase units or new variant, change directly
            selectedBaseUnit = newValue
            if let existingVariant = variant {
                existingVariant.baseUnit = newValue
                try? modelContext.save()
            }
        }
    }

    private func applyBaseUnitChange(_ newUnit: MeasurementUnit) {
        guard let existingVariant = variant else { return }

        // Clear all purchase units
        if let units = existingVariant.purchaseUnits {
            for unit in units {
                modelContext.delete(unit)
            }
        }

        // Update base measurement
        existingVariant.baseUnit = newUnit
        existingVariant.dateModified = Date()

        // Save and update state
        try? modelContext.save()
        selectedBaseUnit = newUnit
        originalBaseUnit = newUnit
        pendingBaseUnit = nil
        refreshTrigger = UUID()
    }

    private func deletePurchaseUnits(at offsets: IndexSet, from units: [PurchaseUnit]) {
        for index in offsets {
            modelContext.delete(units[index])
        }
        try? modelContext.save()
        refreshTrigger = UUID()
    }

    private func deleteStoreInfos(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedStoreInfos[index])
        }
        try? modelContext.save()
        refreshTrigger = UUID()
    }

    private func previewName(product: Product) -> String {
        var parts: [String] = []

        if let brand = selectedBrand {
            parts.append(brand.name)
        }

        parts.append(product.name)

        return parts.joined(separator: " ")
    }

    private func saveAndContinue() {
        guard let product = selectedProduct else { return }

        // Create new variant
        let newVariant = ProductVariant(
            product: product,
            brand: selectedBrand,
            detail: detail.isEmpty ? nil : detail,
            baseUnit: selectedBaseUnit
        )
        modelContext.insert(newVariant)
        try? modelContext.save()

        // Update state to edit the newly created variant (don't call onSave yet - wait for final dismiss)
        variant = newVariant
        originalBaseUnit = newVariant.baseUnit
        refreshTrigger = UUID()
    }

    private func save() {
        guard let product = selectedProduct else { return }

        let variantToSave: ProductVariant
        if let existingVariant = variant {
            existingVariant.product = product
            existingVariant.brand = selectedBrand
            existingVariant.detail = detail.isEmpty ? nil : detail
            existingVariant.baseUnit = selectedBaseUnit
            existingVariant.dateModified = Date()
            variantToSave = existingVariant
        } else {
            variantToSave = ProductVariant(
                product: product,
                brand: selectedBrand,
                detail: detail.isEmpty ? nil : detail,
                baseUnit: selectedBaseUnit
            )
            modelContext.insert(variantToSave)
        }
        try? modelContext.save()
        onSave(variantToSave)
        dismiss()
    }
}

#Preview {
    ProductVariantFormView { variant in
        print("Saved: \(variant.displayName)")
    }
    .modelContainer(PreviewContainer.sample)
}
