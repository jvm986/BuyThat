//
//  ShoppingListDetailView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ShoppingListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let shoppingList: ShoppingList

    @Query private var items: [ShoppingListItem]
    @Query(sort: \StoreVariantInfo.dateModified, order: .reverse) private var allStoreVariantInfos: [StoreVariantInfo]
    @Query(sort: \ProductVariant.dateCreated, order: .reverse) private var allVariants: [ProductVariant]
    @Query(sort: \Product.name) private var allProducts: [Product]

    @State private var searchText = ""
    @State private var showingCreateNewItem = false
    @State private var editingItem: ShoppingListItem?

    init(shoppingList: ShoppingList) {
        self.shoppingList = shoppingList
        let listID = shoppingList.persistentModelID
        _items = Query(
            filter: #Predicate<ShoppingListItem> { item in
                item.list?.persistentModelID == listID
            },
            sort: \.dateAdded,
            order: .reverse
        )
    }

    private var unpurchasedItems: [ShoppingListItem] {
        items.filter { !$0.isPurchased }
    }

    private var purchasedItems: [ShoppingListItem] {
        items.filter { $0.isPurchased }
    }

    private var filteredItems: [ShoppingListItem] {
        if searchText.isEmpty {
            return []
        }
        return items.filter { item in
            let displayText = item.storeVariantInfo?.displayName ?? ""
            return displayText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredItemsUnpurchased: [ShoppingListItem] {
        filteredItems.filter { !$0.isPurchased }
    }

    private var filteredItemsPurchased: [ShoppingListItem] {
        filteredItems.filter { $0.isPurchased }
    }

    private var filteredStoreInfos: [StoreVariantInfo] {
        if searchText.isEmpty {
            return []
        }
        // Get all matching store infos
        return allStoreVariantInfos.filter { info in
            let displayText = "\(info.variant?.displayName ?? "") \(info.store?.name ?? "")"
            return displayText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredVariants: [ProductVariant] {
        if searchText.isEmpty {
            return []
        }
        // Get all matching variants
        return allVariants.filter { variant in
            variant.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return []
        }
        // Get all matching products
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

    private var unpurchasedTotal: Decimal {
        unpurchasedItems.compactMap { $0.estimatedPrice }.reduce(0, +)
    }

    private var purchasedTotal: Decimal {
        purchasedItems.compactMap { $0.estimatedPrice }.reduce(0, +)
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter
    }

    var body: some View {
        List {
            if showingSearchResults {
                ExistingItemsSearchView(
                    unpurchasedItems: filteredItemsUnpurchased,
                    purchasedItems: filteredItemsPurchased,
                    onEditItem: { editingItem = $0 }
                )

                HierarchicalSearchResultsView(
                    hierarchicalResults: hierarchicalResults,
                    style: .quickAdd,
                    onSelectProduct: addQuickProduct,
                    onSelectVariant: addQuickVariant,
                    onSelectStoreInfo: addQuickStoreItem,
                    onCreateNew: { showingCreateNewItem = true }
                )
            } else {
                ShoppingListSectionsView(
                    unpurchasedItems: unpurchasedItems,
                    purchasedItems: purchasedItems,
                    unpurchasedTotal: unpurchasedTotal,
                    purchasedTotal: purchasedTotal,
                    currencyFormatter: currencyFormatter,
                    onEditItem: { editingItem = $0 },
                    onDeleteUnpurchased: { deleteItems(from: unpurchasedItems, at: $0) },
                    onDeletePurchased: { deleteItems(from: purchasedItems, at: $0) }
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search to add items")
        .navigationTitle(shoppingList.name)
        .toolbar {
            if !purchasedItems.isEmpty || !unpurchasedItems.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if !unpurchasedItems.isEmpty {
                            Button("Mark All Purchased", systemImage: "checkmark.circle") {
                                markAllPurchased()
                            }
                        }
                        if !purchasedItems.isEmpty {
                            Button("Clear Purchased", systemImage: "arrow.uturn.backward") {
                                clearPurchased()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateNewItem) {
            NavigationStack {
                CreateNewItemView(searchText: searchText) { createdItem in
                    showingCreateNewItem = false
                    // Add the newly created item based on its type
                    if let storeInfo = createdItem as? StoreVariantInfo {
                        addQuickStoreItem(storeInfo)
                    } else if let variant = createdItem as? ProductVariant {
                        addQuickVariant(variant)
                    } else if let product = createdItem as? Product {
                        addQuickProduct(product)
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingItem) { item in
            ShoppingListItemFormView(shoppingList: shoppingList, item: item) { _ in
                editingItem = nil
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func addQuickStoreItem(_ storeVariantInfo: StoreVariantInfo) {
        let item = ShoppingListItem(
            storeVariantInfo: storeVariantInfo,
            quantity: "1",
            list: shoppingList
        )
        modelContext.insert(item)
        try? modelContext.save()
        searchText = ""
        editingItem = item
    }

    private func addQuickVariant(_ variant: ProductVariant) {
        let item = ShoppingListItem(
            variant: variant,
            quantity: "1",
            list: shoppingList
        )
        modelContext.insert(item)
        try? modelContext.save()
        searchText = ""
        editingItem = item
    }

    private func addQuickProduct(_ product: Product) {
        let item = ShoppingListItem(
            product: product,
            quantity: "1",
            list: shoppingList
        )
        modelContext.insert(item)
        try? modelContext.save()
        searchText = ""
        editingItem = item
    }

    private func deleteItems(from array: [ShoppingListItem], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(array[index])
        }
        try? modelContext.save()
    }

    private func clearPurchased() {
        for item in purchasedItems {
            item.isPurchased = false
        }
        try? modelContext.save()
    }

    private func markAllPurchased() {
        for item in unpurchasedItems {
            item.isPurchased = true
        }
        try? modelContext.save()
    }
}

// MARK: - Extracted View Components

struct ExistingItemsSearchView: View {
    let unpurchasedItems: [ShoppingListItem]
    let purchasedItems: [ShoppingListItem]
    let onEditItem: (ShoppingListItem) -> Void

    var body: some View {
        if !unpurchasedItems.isEmpty {
            Section("On Your List") {
                ForEach(unpurchasedItems) { item in
                    ShoppingListItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEditItem(item)
                        }
                }
            }
        }

        if !purchasedItems.isEmpty {
            Section("On Your List - Purchased") {
                ForEach(purchasedItems) { item in
                    ShoppingListItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEditItem(item)
                        }
                }
            }
        }
    }
}

struct ShoppingListSectionsView: View {
    let unpurchasedItems: [ShoppingListItem]
    let purchasedItems: [ShoppingListItem]
    let unpurchasedTotal: Decimal
    let purchasedTotal: Decimal
    let currencyFormatter: NumberFormatter
    let onEditItem: (ShoppingListItem) -> Void
    let onDeleteUnpurchased: (IndexSet) -> Void
    let onDeletePurchased: (IndexSet) -> Void

    var body: some View {
        if !unpurchasedItems.isEmpty {
            Section {
                ForEach(unpurchasedItems) { item in
                    ShoppingListItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEditItem(item)
                        }
                }
                .onDelete(perform: onDeleteUnpurchased)
            } header: {
                HStack {
                    Text("To Buy")
                    Spacer()
                    if unpurchasedTotal > 0 {
                        Text(unpurchasedTotal as NSDecimalNumber, formatter: currencyFormatter)
                    }
                }
            }
        }

        if !purchasedItems.isEmpty {
            Section {
                ForEach(purchasedItems) { item in
                    ShoppingListItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEditItem(item)
                        }
                }
                .onDelete(perform: onDeletePurchased)
            } header: {
                HStack {
                    Text("Purchased")
                    Spacer()
                    if purchasedTotal > 0 {
                        Text(purchasedTotal as NSDecimalNumber, formatter: currencyFormatter)
                    }
                }
            }
        }
    }
}

struct ShoppingListItemRow: View {
    @Bindable var item: ShoppingListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    item.isPurchased.toggle()
                } label: {
                    Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isPurchased ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(productDisplayName)
                        .strikethrough(item.isPurchased)

                    // Store and Brand subtitle
                    HStack(spacing: 4) {
                        if let brand = item.effectiveVariant?.brand?.name {
                            Text(brand)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let _ = item.effectiveVariant?.brand?.name,
                           let _ = item.effectiveStore?.name {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let store = item.effectiveStore?.name {
                            Text(store)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(quantityDisplay)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let price = item.estimatedPrice {
                        Text(price as NSDecimalNumber, formatter: currencyFormatter)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var productDisplayName: String {
        let productName = item.effectiveProduct?.name ?? "Unknown Item"

        if let detail = item.effectiveVariant?.detail, !detail.isEmpty {
            return "\(detail) \(productName)"
        }

        return productName
    }

    private var quantityDisplay: String {
        let itemQty = item.quantity

        if let unit = item.purchaseUnit {
            return "\(itemQty) \(unit.displayName)"
        } else {
            return "\(itemQty) \(item.effectiveBaseUnit.symbol)"
        }
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter
    }
}

#Preview {
    @Previewable @Query var shoppingLists: [ShoppingList]
    if let list = shoppingLists.first {
        NavigationStack {
            ShoppingListDetailView(shoppingList: list)
        }
        .modelContainer(PreviewContainer.sample)
    }
}
