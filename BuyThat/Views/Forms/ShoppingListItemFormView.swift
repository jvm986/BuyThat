//
//  ToBuyItemFormView.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import SwiftUI
import SwiftData

struct ToBuyItemFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StoreVariantInfo.dateModified, order: .reverse) private var allStoreVariantInfos: [StoreVariantInfo]
    @Query(sort: \ProductVariant.dateCreated, order: .reverse) private var allVariants: [ProductVariant]
    @Query(sort: \Product.name) private var allProducts: [Product]

    let item: ToBuyItem?
    let onSave: (ToBuyItem) -> Void

    @State private var searchText: String
    @State private var selectedStoreVariantInfo: StoreVariantInfo?
    @State private var selectedVariant: ProductVariant?
    @State private var selectedProduct: Product?
    @State private var quantity: String
    @State private var selectedPurchaseUnit: PurchaseUnit?
    @State private var editingStoreVariantInfo: StoreVariantInfo?
    @State private var editingVariant: ProductVariant?
    @State private var editingProduct: Product?
    @State private var showingCreateNewItem = false

    init(item: ToBuyItem? = nil, onSave: @escaping (ToBuyItem) -> Void) {
        self.item = item
        self.onSave = onSave
        _quantity = State(initialValue: item?.quantity ?? "1")
        _selectedStoreVariantInfo = State(initialValue: item?.storeVariantInfo)
        _selectedVariant = State(initialValue: item?.variant)
        _selectedProduct = State(initialValue: item?.product)
        _selectedPurchaseUnit = State(initialValue: item?.purchaseUnit)
        _searchText = State(initialValue: "")
    }

    private var canSave: Bool {
        !quantity.isEmpty && (selectedStoreVariantInfo != nil || selectedVariant != nil || selectedProduct != nil)
    }

    private var showingSearchResults: Bool {
        !searchText.isEmpty
    }

    private var filteredStoreInfos: [StoreVariantInfo] {
        if searchText.isEmpty { return [] }
        return allStoreVariantInfos.filter { info in
            let displayText = "\(info.variant?.displayName ?? "") \(info.store?.name ?? "")"
            return displayText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredVariants: [ProductVariant] {
        if searchText.isEmpty { return [] }
        return allVariants.filter { variant in
            variant.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredProducts: [Product] {
        if searchText.isEmpty { return [] }
        return allProducts.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var hierarchicalResults: [ProductGroup] {
        HierarchicalResultsBuilder.build(
            products: filteredProducts,
            variants: filteredVariants,
            storeInfos: filteredStoreInfos
        )
    }

    var body: some View {
        NavigationStack {
            List {
                if showingSearchResults {
                    HierarchicalSearchResultsView(
                        hierarchicalResults: hierarchicalResults,
                        style: .select,
                        onSelectProduct: selectProduct,
                        onSelectVariant: selectVariant,
                        onSelectStoreInfo: selectStoreInfo,
                        onCreateNew: { showingCreateNewItem = true }
                    )
                } else if selectedStoreVariantInfo != nil || selectedVariant != nil || selectedProduct != nil {
                    SelectedItemDetailsView(
                        selectedStoreVariantInfo: selectedStoreVariantInfo,
                        selectedVariant: selectedVariant,
                        selectedProduct: selectedProduct,
                        quantity: $quantity,
                        selectedPurchaseUnit: $selectedPurchaseUnit,
                        onEditStoreInfo: { editingStoreVariantInfo = $0 },
                        onEditVariant: { editingVariant = $0 },
                        onEditProduct: { editingProduct = $0 },
                        estimatedPrice: selectedStoreVariantInfo.flatMap { estimatedPrice(for: $0) }
                    )
                } else {
                    EmptySearchStateView()
                }
            }
            .searchable(text: $searchText, prompt: "Search products, variants, or store items")
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
            .sheet(isPresented: $showingCreateNewItem) {
                NavigationStack {
                    CreateNewItemView(searchText: searchText) { createdItem in
                        showingCreateNewItem = false
                        if let storeInfo = createdItem as? StoreVariantInfo {
                            selectStoreInfo(storeInfo)
                        } else if let variant = createdItem as? ProductVariant {
                            selectVariant(variant)
                        } else if let product = createdItem as? Product {
                            selectProduct(product)
                        }
                    }
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingStoreVariantInfo) { info in
                StoreVariantInfoFormView(storeVariantInfo: info) { _ in
                    editingStoreVariantInfo = nil
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingVariant) { variant in
                ProductVariantFormView(variant: variant) { _ in
                    editingVariant = nil
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingProduct) { product in
                ProductFormView(product: product) { _ in
                    editingProduct = nil
                }
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func selectStoreInfo(_ info: StoreVariantInfo) {
        selectedStoreVariantInfo = info
        selectedVariant = nil
        selectedProduct = nil
        selectedPurchaseUnit = info.variant?.purchaseUnits?.first
        searchText = ""
    }

    private func selectVariant(_ variant: ProductVariant) {
        selectedStoreVariantInfo = nil
        selectedVariant = variant
        selectedProduct = nil
        selectedPurchaseUnit = variant.purchaseUnits?.first
        searchText = ""
    }

    private func selectProduct(_ product: Product) {
        selectedStoreVariantInfo = nil
        selectedVariant = nil
        selectedProduct = product
        selectedPurchaseUnit = nil
        searchText = ""
    }

    private func estimatedPrice(for info: StoreVariantInfo) -> String? {
        guard let numericValue = Double(quantity) else { return nil }

        let pricePerSelectedUnit: Decimal?
        if let unit = selectedPurchaseUnit {
            pricePerSelectedUnit = info.priceForPurchaseUnit(unit)
        } else {
            guard let price = info.pricePerUnit else { return nil }

            if let pricingUnit = info.pricingUnit {
                pricePerSelectedUnit = price * Decimal(pricingUnit.conversionToBase)
            } else {
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
        let itemToSave: ToBuyItem
        if let existing = item {
            existing.storeVariantInfo = selectedStoreVariantInfo
            existing.variant = selectedVariant
            existing.product = selectedProduct
            existing.quantity = quantity
            existing.purchaseUnit = selectedPurchaseUnit
            itemToSave = existing
        } else {
            let descriptor = FetchDescriptor<ToBuyItem>()
            let existingItems = (try? modelContext.fetch(descriptor)) ?? []
            let maxSortOrder = existingItems.map(\.sortOrder).max() ?? -1
            itemToSave = ToBuyItem(
                storeVariantInfo: selectedStoreVariantInfo,
                variant: selectedVariant,
                product: selectedProduct,
                quantity: quantity,
                purchaseUnit: selectedPurchaseUnit,
                sortOrder: maxSortOrder + 1
            )
            modelContext.insert(itemToSave)
        }

        try? modelContext.save()
        onSave(itemToSave)
        dismiss()
    }
}

// MARK: - Extracted View Components

struct SelectedItemDetailsView: View {
    let selectedStoreVariantInfo: StoreVariantInfo?
    let selectedVariant: ProductVariant?
    let selectedProduct: Product?
    @Binding var quantity: String
    @Binding var selectedPurchaseUnit: PurchaseUnit?
    let onEditStoreInfo: (StoreVariantInfo) -> Void
    let onEditVariant: (ProductVariant) -> Void
    let onEditProduct: (Product) -> Void
    let estimatedPrice: String?

    private var levelLabel: String {
        if selectedStoreVariantInfo != nil { return "Store Item" }
        if selectedVariant != nil { return "Variant" }
        return "Product"
    }

    var body: some View {
        Section(levelLabel) {
            selectedItemContent
        }

        Section("Details") {
            TextField("Quantity", text: $quantity)
                .keyboardType(.decimalPad)

            unitPickerView

            estimatedPriceView
        }
    }

    @ViewBuilder
    private var selectedItemContent: some View {
        VStack(alignment: .leading) {
            if let info = selectedStoreVariantInfo {
                storeInfoDetails(info)
            } else if let variant = selectedVariant {
                variantDetails(variant)
            } else if let product = selectedProduct {
                Text(product.name)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onLongPressGesture(perform: handleLongPress)
    }

    @ViewBuilder
    private func storeInfoDetails(_ info: StoreVariantInfo) -> some View {
        Text(info.variant?.displayName ?? "Unknown")
        HStack {
            Text(info.store?.name ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let price = info.formattedPricePerUnit {
                Text("\u{2022}")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(price)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func variantDetails(_ variant: ProductVariant) -> some View {
        Text(variant.displayNameShort)
        if let brand = variant.brand?.name {
            Text(brand)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var unitPickerView: some View {
        let effectiveVariant = selectedStoreVariantInfo?.variant ?? selectedVariant
        let effectiveProduct = effectiveVariant?.product ?? selectedProduct
        let baseUnit = effectiveVariant?.baseUnit ?? .units
        let resolvedUnitName: String? = baseUnit == .units
            ? (effectiveVariant?.unitName ?? effectiveProduct?.defaultUnitName)
            : nil
        let baseLabel = resolvedUnitName ?? baseUnit.symbol

        if let variant = effectiveVariant, let units = variant.purchaseUnits, !units.isEmpty {
            Picker("Unit", selection: $selectedPurchaseUnit) {
                Text(baseLabel).tag(nil as PurchaseUnit?)
                ForEach(units) { unit in
                    Text(unit.displayName).tag(unit as PurchaseUnit?)
                }
            }
        } else if let name = resolvedUnitName {
            HStack {
                Text("Unit")
                Spacer()
                Text(name)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var estimatedPriceView: some View {
        if let estimated = estimatedPrice {
            HStack {
                Text("Estimated Price")
                Spacer()
                Text(estimated)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func handleLongPress() {
        if let info = selectedStoreVariantInfo {
            onEditStoreInfo(info)
        } else if let variant = selectedVariant {
            onEditVariant(variant)
        } else if let product = selectedProduct {
            onEditProduct(product)
        }
    }
}

struct EmptySearchStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Search for an item to add to your list")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    ToBuyItemFormView { _ in
        print("Item saved")
    }
    .modelContainer(PreviewContainer.sample)
}
