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

    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var showingQuickCreate = false
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
        let allMatching = allStoreVariantInfos.filter { info in
            let displayText = "\(info.variant?.displayName ?? "") \(info.store?.name ?? "")"
            return displayText.localizedCaseInsensitiveContains(searchText)
        }

        // Filter out ones that are already on the list
        let existingInfoIDs = Set(items.compactMap { $0.storeVariantInfo?.persistentModelID })
        return allMatching.filter { !existingInfoIDs.contains($0.persistentModelID) }
    }

    private var groupedByStore: [String: [StoreVariantInfo]] {
        Dictionary(grouping: filteredStoreInfos) { info in
            info.store?.name ?? "No Store"
        }
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
                // Show existing items on list that match search
                if !filteredItemsUnpurchased.isEmpty {
                    Section("On Your List") {
                        ForEach(filteredItemsUnpurchased) { item in
                            ShoppingListItemRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingItem = item
                                }
                        }
                    }
                }

                if !filteredItemsPurchased.isEmpty {
                    Section("On Your List - Purchased") {
                        ForEach(filteredItemsPurchased) { item in
                            ShoppingListItemRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingItem = item
                                }
                        }
                    }
                }

                // Show available items to add
                if !filteredStoreInfos.isEmpty {
                    ForEach(groupedByStore.keys.sorted(), id: \.self) { storeName in
                        Section("Add from \(storeName)") {
                            ForEach(groupedByStore[storeName] ?? []) { info in
                                Button {
                                    addQuickItem(info)
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.green)
                                        VStack(alignment: .leading) {
                                            Text(info.variant?.displayName ?? "Unknown")
                                                .foregroundStyle(.primary)
                                            if let price = info.formattedPrice {
                                                Text(price)
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
                }

                // Always show "Create New Item" button when searching
                Section {
                    Button {
                        showingQuickCreate = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Create New Item")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } else {
                if !unpurchasedItems.isEmpty {
                    Section {
                        ForEach(unpurchasedItems) { item in
                            ShoppingListItemRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingItem = item
                                }
                        }
                        .onDelete { offsets in
                            deleteItems(from: unpurchasedItems, at: offsets)
                        }
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
                                    editingItem = item
                                }
                        }
                        .onDelete { offsets in
                            deleteItems(from: purchasedItems, at: offsets)
                        }
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
        .searchable(text: $searchText, prompt: "Search to add items")
        .navigationTitle(shoppingList.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    showingAddSheet = true
                }
            }
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
        .sheet(isPresented: $showingAddSheet) {
            ShoppingListItemFormView(shoppingList: shoppingList) { _ in
                showingAddSheet = false
            }
        }
        .sheet(isPresented: $showingQuickCreate) {
            StoreVariantInfoFormView { newInfo in
                showingQuickCreate = false
                addQuickItem(newInfo)
            }
        }
        .sheet(item: $editingItem) { item in
            ShoppingListItemFormView(shoppingList: shoppingList, item: item) { _ in
                editingItem = nil
            }
        }
    }

    private func addQuickItem(_ storeVariantInfo: StoreVariantInfo) {
        let item = ShoppingListItem(
            storeVariantInfo: storeVariantInfo,
            quantity: "1",
            list: shoppingList
        )
        modelContext.insert(item)
        try? modelContext.save()
        searchText = ""
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

struct ShoppingListItemRow: View {
    @Bindable var item: ShoppingListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Button {
                    item.isPurchased.toggle()
                } label: {
                    Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isPurchased ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.storeVariantInfo?.variant?.product?.name ?? "Unknown Item")
                        .strikethrough(item.isPurchased)

                    // Store and Brand subtitle
                    HStack(spacing: 4) {
                        if let brand = item.storeVariantInfo?.variant?.brand?.name {
                            Text(brand)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let _ = item.storeVariantInfo?.variant?.brand?.name,
                           let _ = item.storeVariantInfo?.store?.name {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let store = item.storeVariantInfo?.store?.name {
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

    private var quantityDisplay: String {
        let itemQty = item.quantity

        if let unit = item.purchaseUnit {
            return "\(itemQty) \(unit.displayName)"
        } else if let baseUnit = item.storeVariantInfo?.variant?.baseUnit {
            return "\(itemQty) \(baseUnit.symbol)"
        }

        return itemQty
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
