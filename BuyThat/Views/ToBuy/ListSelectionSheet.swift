//
//  ListSelectionSheet.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import SwiftUI
import SwiftData

struct ListSelectionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let list: ItemList

    @State private var selectedEntryIDs: Set<PersistentIdentifier>

    init(list: ItemList) {
        self.list = list
        let allIDs = Set((list.entries ?? []).map { $0.persistentModelID })
        _selectedEntryIDs = State(initialValue: allIDs)
    }

    private var entries: [ItemListEntry] {
        (list.entries ?? []).sorted { $0.dateAdded < $1.dateAdded }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(entries) { entry in
                        Button {
                            toggleEntry(entry)
                        } label: {
                            HStack {
                                Image(systemName: selectedEntryIDs.contains(entry.persistentModelID) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedEntryIDs.contains(entry.persistentModelID) ? .blue : .secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(displayName(for: entry))
                                    subtitleView(for: entry)
                                }
                                .foregroundStyle(.primary)

                                Spacer()

                                Text(quantityDisplay(for: entry))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(list.name)
                        Spacer()
                        Text("\(selectedEntryIDs.count) of \(entries.count) selected")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add from List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to To Buy") {
                        addSelectedItems()
                        dismiss()
                    }
                    .disabled(selectedEntryIDs.isEmpty)
                }
            }
        }
    }

    private func toggleEntry(_ entry: ItemListEntry) {
        if selectedEntryIDs.contains(entry.persistentModelID) {
            selectedEntryIDs.remove(entry.persistentModelID)
        } else {
            selectedEntryIDs.insert(entry.persistentModelID)
        }
    }

    private func displayName(for entry: ItemListEntry) -> String {
        let productName = entry.effectiveProduct?.name ?? "Unknown Item"
        if let detail = entry.effectiveVariant?.detail, !detail.isEmpty {
            return "\(detail) \(productName)"
        }
        return productName
    }

    @ViewBuilder
    private func subtitleView(for entry: ItemListEntry) -> some View {
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

    private func quantityDisplay(for entry: ItemListEntry) -> String {
        if let unit = entry.purchaseUnit {
            return "\(entry.quantity) \(unit.displayName)"
        } else {
            return "\(entry.quantity) \(entry.effectiveBaseUnit.symbol)"
        }
    }

    // MARK: - Merge Logic

    private func addSelectedItems() {
        let descriptor = FetchDescriptor<ToBuyItem>()
        let existingItems = (try? modelContext.fetch(descriptor)) ?? []

        let selectedEntries = entries.filter { selectedEntryIDs.contains($0.persistentModelID) }

        for entry in selectedEntries {
            if let matchingItem = MergeHelper.findMatch(for: entry, in: existingItems) {
                matchingItem.quantity = MergeHelper.mergeQuantities(matchingItem.quantity, entry.quantity)
            } else {
                let newItem = ToBuyItem(
                    storeVariantInfo: entry.storeVariantInfo,
                    variant: entry.variant,
                    product: entry.product,
                    quantity: entry.quantity,
                    purchaseUnit: entry.purchaseUnit
                )
                modelContext.insert(newItem)
            }
        }

        try? modelContext.save()
    }
}

#Preview {
    let container = PreviewContainer.sample
    let context = container.mainContext
    let list = ItemList(name: "Weekly Groceries")
    context.insert(list)
    let entry = ItemListEntry(quantity: "2", list: list)
    context.insert(entry)
    try? context.save()

    return ListSelectionSheet(list: list)
        .modelContainer(container)
}
