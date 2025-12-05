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

    init(variant: ProductVariant? = nil, onSave: @escaping (ProductVariant) -> Void) {
        self.onSave = onSave
        _variant = State(initialValue: variant)
        _selectedProduct = State(initialValue: variant?.product)
        _selectedBrand = State(initialValue: variant?.brand)
        _selectedBaseUnit = State(initialValue: variant?.baseUnit ?? .units)
        _originalBaseUnit = State(initialValue: variant?.baseUnit)
    }

    private var canSave: Bool {
        selectedProduct != nil
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
                    Picker("Base", selection: Binding(
                        get: { selectedBaseUnit },
                        set: { newValue in
                            handleBaseUnitChange(newValue)
                        }
                    )) {
                        Text("Count (units)").tag(MeasurementUnit.units)
                        Text("Weight (g)").tag(MeasurementUnit.grams)
                        Text("Volume (mL)").tag(MeasurementUnit.milliliters)
                    }
                    .pickerStyle(.menu)

                    if variant == nil {
                        Button {
                            saveAndContinue()
                        } label: {
                            Label("Add Purchase Units", systemImage: "plus.circle")
                        }
                        .disabled(!canSave)
                    }
                } header: {
                    Text("Measurement Type")
                } footer: {
                    if variant == nil {
                        Text("Save to configure alternative units.")
                    }
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
                    } footer: {
                        Text("Optional: Add alternative units for pricing and ordering")
                    }
                    .id(refreshTrigger)
                }

                if let product = selectedProduct {
                    Section {
                        Text("Preview: \(previewName(product: product))")
                            .foregroundStyle(.secondary)
                    }
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
            }
            .sheet(isPresented: $showingBrandSelection) {
                NavigationStack {
                    SelectBrandView { brand in
                        selectedBrand = brand
                        showingBrandSelection = false
                    }
                }
            }
            .sheet(item: $editingProduct) { product in
                ProductFormView(product: product) { _ in
                    editingProduct = nil
                }
            }
            .sheet(item: $editingBrand) { brand in
                BrandFormView(brand: brand) { _ in
                    editingBrand = nil
                }
            }
            .sheet(item: $variantForPurchaseUnit) { variant in
                PurchaseUnitFormView(variant: variant) { _ in
                    refreshTrigger = UUID()
                    variantForPurchaseUnit = nil
                }
            }
            .sheet(item: $editingPurchaseUnit) { unit in
                PurchaseUnitFormView(variant: variant!, purchaseUnit: unit) { _ in
                    refreshTrigger = UUID()
                    editingPurchaseUnit = nil
                }
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
            existingVariant.baseUnit = selectedBaseUnit
            existingVariant.dateModified = Date()
            variantToSave = existingVariant
        } else {
            variantToSave = ProductVariant(
                product: product,
                brand: selectedBrand,
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
