//
//  ManageItemListsView.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import SwiftUI
import SwiftData

struct ManageItemListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ItemList.name) private var lists: [ItemList]

    @State private var showingCreateSheet = false

    var body: some View {
        List {
            ForEach(lists) { list in
                NavigationLink {
                    ItemListDetailView(list: list)
                } label: {
                    VStack(alignment: .leading) {
                        Text(list.name)
                        if let count = list.entries?.count, count > 0 {
                            Text("\(count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteLists)
        }
        .navigationTitle("Lists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    showingCreateSheet = true
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            ItemListFormView { _ in
                showingCreateSheet = false
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(lists[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Item List Detail View

struct ItemListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var list: ItemList

    @Query(sort: \StoreVariantInfo.dateModified, order: .reverse) private var allStoreVariantInfos: [StoreVariantInfo]
    @Query(sort: \ProductVariant.dateCreated, order: .reverse) private var allVariants: [ProductVariant]
    @Query(sort: \Product.name) private var allProducts: [Product]

    @State private var searchText = ""
    @State private var showingCreateNewItem = false
    @State private var showingEditName = false
    @State private var editingEntry: ItemListEntry?

    private var entries: [ItemListEntry] {
        (list.entries ?? []).sorted { $0.dateAdded < $1.dateAdded }
    }

    private var filteredStoreInfos: [StoreVariantInfo] {
        guard !searchText.isEmpty else { return [] }
        return allStoreVariantInfos.filter { info in
            let displayText = "\(info.variant?.displayName ?? "") \(info.store?.name ?? "")"
            return displayText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredVariants: [ProductVariant] {
        guard !searchText.isEmpty else { return [] }
        return allVariants.filter { variant in
            variant.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredProducts: [Product] {
        guard !searchText.isEmpty else { return [] }
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

    private var showingSearchResults: Bool {
        !searchText.isEmpty
    }

    var body: some View {
        List {
            if showingSearchResults {
                HierarchicalSearchResultsView(
                    hierarchicalResults: hierarchicalResults,
                    style: .quickAdd,
                    onSelectProduct: addProduct,
                    onSelectVariant: addVariant,
                    onSelectStoreInfo: addStoreItem,
                    onCreateNew: { showingCreateNewItem = true }
                )
            } else {
                if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No items yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Search to add items to this list")
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                    .listRowBackground(Color.clear)
                } else {
                    Section("Items") {
                        ForEach(entries) { entry in
                            ItemListEntryRow(entry: entry)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingEntry = entry
                                }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search to add items")
        .navigationTitle(list.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit Name", systemImage: "pencil") {
                    showingEditName = true
                }
            }
        }
        .sheet(isPresented: $showingCreateNewItem) {
            NavigationStack {
                CreateNewItemView(searchText: searchText) { createdItem in
                    showingCreateNewItem = false
                    if let storeInfo = createdItem as? StoreVariantInfo {
                        addStoreItem(storeInfo)
                    } else if let variant = createdItem as? ProductVariant {
                        addVariant(variant)
                    } else if let product = createdItem as? Product {
                        addProduct(product)
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEditName) {
            ItemListFormView(itemList: list) { _ in
                showingEditName = false
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingEntry) { entry in
            ItemListEntryFormView(list: list, entry: entry) { _ in
                editingEntry = nil
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func addStoreItem(_ storeVariantInfo: StoreVariantInfo) {
        let entry = ItemListEntry(
            storeVariantInfo: storeVariantInfo,
            quantity: "1",
            list: list
        )
        modelContext.insert(entry)
        list.dateModified = Date()
        try? modelContext.save()
        searchText = ""
        editingEntry = entry
    }

    private func addVariant(_ variant: ProductVariant) {
        let entry = ItemListEntry(
            variant: variant,
            quantity: "1",
            list: list
        )
        modelContext.insert(entry)
        list.dateModified = Date()
        try? modelContext.save()
        searchText = ""
        editingEntry = entry
    }

    private func addProduct(_ product: Product) {
        let entry = ItemListEntry(
            product: product,
            quantity: "1",
            list: list
        )
        modelContext.insert(entry)
        list.dateModified = Date()
        try? modelContext.save()
        searchText = ""
        editingEntry = entry
    }

    private func deleteEntries(at offsets: IndexSet) {
        let entriesToDelete = offsets.map { entries[$0] }
        for entry in entriesToDelete {
            modelContext.delete(entry)
        }
        list.dateModified = Date()
        try? modelContext.save()
    }
}

// MARK: - Item List Entry Row

struct ItemListEntryRow: View {
    let entry: ItemListEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(productDisplayName)

                HStack(spacing: 4) {
                    if let brand = entry.effectiveVariant?.brand?.name {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if entry.effectiveVariant?.brand?.name != nil,
                       entry.effectiveStore?.name != nil {
                        Text("\u{2022}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let store = entry.effectiveStore?.name {
                        Text(store)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(quantityDisplay)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var productDisplayName: String {
        let productName = entry.effectiveProduct?.name ?? "Unknown Item"
        if let detail = entry.effectiveVariant?.detail, !detail.isEmpty {
            return "\(detail) \(productName)"
        }
        return productName
    }

    private var quantityDisplay: String {
        if let unit = entry.purchaseUnit {
            return "\(entry.quantity) \(unit.displayName)"
        } else {
            return "\(entry.quantity) \(entry.effectiveBaseUnit.symbol)"
        }
    }
}

// MARK: - Item List Entry Form View

struct ItemListEntryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StoreVariantInfo.dateModified, order: .reverse) private var allStoreVariantInfos: [StoreVariantInfo]
    @Query(sort: \ProductVariant.dateCreated, order: .reverse) private var allVariants: [ProductVariant]
    @Query(sort: \Product.name) private var allProducts: [Product]

    let list: ItemList
    let entry: ItemListEntry?
    let onSave: (ItemListEntry) -> Void

    @State private var searchText: String
    @State private var selectedStoreVariantInfo: StoreVariantInfo?
    @State private var selectedVariant: ProductVariant?
    @State private var selectedProduct: Product?
    @State private var quantity: String
    @State private var selectedPurchaseUnit: PurchaseUnit?
    @State private var showingCreateNewItem = false

    init(list: ItemList, entry: ItemListEntry? = nil, onSave: @escaping (ItemListEntry) -> Void) {
        self.list = list
        self.entry = entry
        self.onSave = onSave
        _quantity = State(initialValue: entry?.quantity ?? "1")
        _selectedStoreVariantInfo = State(initialValue: entry?.storeVariantInfo)
        _selectedVariant = State(initialValue: entry?.variant)
        _selectedProduct = State(initialValue: entry?.product)
        _selectedPurchaseUnit = State(initialValue: entry?.purchaseUnit)
        _searchText = State(initialValue: "")
    }

    private var canSave: Bool {
        !quantity.isEmpty && (selectedStoreVariantInfo != nil || selectedVariant != nil || selectedProduct != nil)
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
                if !searchText.isEmpty {
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
                        onEditStoreInfo: { _ in },
                        onEditVariant: { _ in },
                        onEditProduct: { _ in },
                        estimatedPrice: nil
                    )
                } else {
                    EmptySearchStateView()
                }
            }
            .searchable(text: $searchText, prompt: "Search products, variants, or store items")
            .navigationTitle(entry == nil ? "Add Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(entry == nil ? "Add" : "Save") { save() }
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
        }
    }

    private func selectStoreInfo(_ info: StoreVariantInfo) {
        selectedStoreVariantInfo = info
        selectedVariant = nil
        selectedProduct = nil
        searchText = ""
    }

    private func selectVariant(_ variant: ProductVariant) {
        selectedStoreVariantInfo = nil
        selectedVariant = variant
        selectedProduct = nil
        searchText = ""
    }

    private func selectProduct(_ product: Product) {
        selectedStoreVariantInfo = nil
        selectedVariant = nil
        selectedProduct = product
        searchText = ""
    }

    private func save() {
        let entryToSave: ItemListEntry
        if let existing = entry {
            existing.storeVariantInfo = selectedStoreVariantInfo
            existing.variant = selectedVariant
            existing.product = selectedProduct
            existing.quantity = quantity
            existing.purchaseUnit = selectedPurchaseUnit
            entryToSave = existing
        } else {
            entryToSave = ItemListEntry(
                storeVariantInfo: selectedStoreVariantInfo,
                variant: selectedVariant,
                product: selectedProduct,
                quantity: quantity,
                purchaseUnit: selectedPurchaseUnit,
                list: list
            )
            modelContext.insert(entryToSave)
        }

        list.dateModified = Date()
        try? modelContext.save()
        onSave(entryToSave)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ManageItemListsView()
    }
    .modelContainer(PreviewContainer.sample)
}
