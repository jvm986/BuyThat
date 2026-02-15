//
//  ToBuyView.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import SwiftUI
import SwiftData

struct ToBuyView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ToBuyItem.dateAdded, order: .reverse) private var toBuyItems: [ToBuyItem]
    @Query(sort: \ItemList.name) private var allLists: [ItemList]
    @Query(sort: \StoreVariantInfo.dateModified, order: .reverse) private var allStoreVariantInfos: [StoreVariantInfo]
    @Query(sort: \ProductVariant.dateCreated, order: .reverse) private var allVariants: [ProductVariant]
    @Query(sort: \Product.name) private var allProducts: [Product]

    @State private var searchText = ""
    @State private var editingItem: ToBuyItem?
    @State private var showingCreateNewItem = false
    @State private var selectedList: ItemList?
    @State private var showingReceiptScanner = false

    // MARK: - Filtered Data

    private var filteredLists: [ItemList] {
        guard !searchText.isEmpty else { return [] }
        return allLists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredToBuyItems: [ToBuyItem] {
        guard !searchText.isEmpty else { return [] }
        return toBuyItems.filter { item in
            let name = item.effectiveProduct?.name ?? ""
            let variantName = item.effectiveVariant?.displayName ?? ""
            let storeName = item.effectiveStore?.name ?? ""
            let searchable = "\(name) \(variantName) \(storeName)"
            return searchable.localizedCaseInsensitiveContains(searchText)
        }
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

    private var totalPrice: Decimal {
        toBuyItems.compactMap { $0.estimatedPrice }.reduce(0, +)
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if showingSearchResults {
                    searchResultsContent
                } else {
                    toBuyListContent
                }
            }
            .searchable(text: $searchText, prompt: "Search to add items")
            .navigationTitle("To Buy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingReceiptScanner = true
                    } label: {
                        Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                    }
                    .accessibilityIdentifier("ScanReceiptButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    .accessibilityIdentifier("SettingsButton")
                }
                if !toBuyItems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Clear All", systemImage: "trash", role: .destructive) {
                                clearAll()
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
                ToBuyItemFormView(item: item) { _ in
                    editingItem = nil
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedList) { list in
                ListSelectionSheet(list: list)
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showingReceiptScanner) {
                ReceiptScanningCoordinator()
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Search Results Content

    @ViewBuilder
    private var searchResultsContent: some View {
        if !filteredLists.isEmpty {
            Section("Lists") {
                ForEach(filteredLists) { list in
                    Button {
                        selectedList = list
                        searchText = ""
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading) {
                                Text(list.name)
                                    .foregroundStyle(.primary)
                                if let count = list.entries?.count, count > 0 {
                                    Text("\(count) items")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }

        if !filteredToBuyItems.isEmpty {
            Section("On Your List") {
                ForEach(filteredToBuyItems) { item in
                    ToBuyItemRow(item: item, onCheck: { checkOffItem(item) })
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingItem = item
                        }
                }
            }
        }

        HierarchicalSearchResultsView(
            hierarchicalResults: hierarchicalResults,
            style: .quickAdd,
            onSelectProduct: addQuickProduct,
            onSelectVariant: addQuickVariant,
            onSelectStoreInfo: addQuickStoreItem,
            onCreateNew: { showingCreateNewItem = true }
        )
    }

    // MARK: - To Buy List Content

    @ViewBuilder
    private var toBuyListContent: some View {
        if toBuyItems.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "cart")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Your list is empty")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Search to add items")
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
            .listRowBackground(Color.clear)
        } else {
            Section {
                ForEach(toBuyItems) { item in
                    ToBuyItemRow(item: item, onCheck: { checkOffItem(item) })
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingItem = item
                        }
                }
                .onDelete(perform: deleteItems)
            } header: {
                HStack {
                    Text("To Buy")
                    Spacer()
                    if totalPrice > 0 {
                        Text(totalPrice as NSDecimalNumber, formatter: currencyFormatter)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func addQuickStoreItem(_ storeVariantInfo: StoreVariantInfo) {
        let item = ToBuyItem(
            storeVariantInfo: storeVariantInfo,
            quantity: "1"
        )
        modelContext.insert(item)
        try? modelContext.save()
        searchText = ""
        editingItem = item
    }

    private func addQuickVariant(_ variant: ProductVariant) {
        let item = ToBuyItem(
            variant: variant,
            quantity: "1"
        )
        modelContext.insert(item)
        try? modelContext.save()
        searchText = ""
        editingItem = item
    }

    private func addQuickProduct(_ product: Product) {
        let item = ToBuyItem(
            product: product,
            quantity: "1"
        )
        modelContext.insert(item)
        try? modelContext.save()
        searchText = ""
        editingItem = item
    }

    private func checkOffItem(_ item: ToBuyItem) {
        withAnimation {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(toBuyItems[index])
        }
        try? modelContext.save()
    }

    private func clearAll() {
        for item in toBuyItems {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

// MARK: - To Buy Item Row

struct ToBuyItemRow: View {
    let item: ToBuyItem
    let onCheck: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onCheck) {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(productDisplayName)

                HStack(spacing: 4) {
                    if let brand = item.effectiveVariant?.brand?.name {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if item.effectiveVariant?.brand?.name != nil,
                       item.effectiveStore?.name != nil {
                        Text("\u{2022}")
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
    ToBuyView()
        .modelContainer(PreviewContainer.sample)
}
