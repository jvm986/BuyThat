//
//  ManageStoreVariantInfoView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ManageStoreVariantInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoreVariantInfo.dateModified, order: .reverse) private var infos: [StoreVariantInfo]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingInfo: StoreVariantInfo?

    private var filteredInfos: [StoreVariantInfo] {
        if searchText.isEmpty {
            return infos
        }
        return infos.filter { info in
            let displayText = "\(info.variant?.displayName ?? "") \(info.store?.name ?? "")"
            return displayText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedByStore: [String: [StoreVariantInfo]] {
        Dictionary(grouping: filteredInfos) { info in
            info.store?.name ?? "No Store"
        }
    }

    var body: some View {
        List {
            ForEach(groupedByStore.keys.sorted(), id: \.self) { storeName in
                Section(storeName) {
                    ForEach(groupedByStore[storeName] ?? []) { info in
                        Button {
                            editingInfo = info
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(info.variant?.displayName ?? "Unknown")
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
                        deleteInfos(from: groupedByStore[storeName] ?? [], at: offsets)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Store Variant Info")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    showingCreateSheet = true
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            StoreVariantInfoFormView { _ in
                showingCreateSheet = false
            }
        }
        .sheet(item: $editingInfo) { info in
            StoreVariantInfoFormView(storeVariantInfo: info) { _ in
                editingInfo = nil
            }
        }
    }

    private func deleteInfos(from array: [StoreVariantInfo], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(array[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ManageStoreVariantInfoView()
    }
    .modelContainer(PreviewContainer.sample)
}

