//
//  SelectStoreVariantInfoView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct SelectStoreVariantInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StoreVariantInfo.dateModified, order: .reverse) private var allStoreVariantInfos: [StoreVariantInfo]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingInfo: StoreVariantInfo?

    var filterVariant: ProductVariant? = nil
    var filterStore: Store? = nil
    let onSelect: (StoreVariantInfo) -> Void

    private var filteredInfos: [StoreVariantInfo] {
        var infos = allStoreVariantInfos
        if let filterVariant {
            infos = infos.filter { $0.variant == filterVariant }
        }
        if let filterStore {
            infos = infos.filter { $0.store == filterStore }
        }
        if !searchText.isEmpty {
            infos = infos.filter { info in
                let displayText = "\(info.variant?.displayName ?? "") \(info.store?.name ?? "")"
                return displayText.localizedCaseInsensitiveContains(searchText)
            }
        }
        return infos
    }

    private var groupedByStore: [String: [StoreVariantInfo]] {
        Dictionary(grouping: filteredInfos) { info in
            info.store?.name ?? "No Store"
        }
    }

    var body: some View {
        List {
            if filteredInfos.isEmpty && !searchText.isEmpty {
                Section {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Create New Store Item")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } else {
                ForEach(groupedByStore.keys.sorted(), id: \.self) { storeName in
                    Section(storeName) {
                        ForEach(groupedByStore[storeName] ?? []) { info in
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
                            .onTapGesture {
                                onSelect(info)
                                dismiss()
                            }
                            .onLongPressGesture {
                                editingInfo = info
                            }
                        }
                    }
                }

                if !searchText.isEmpty {
                    Section {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Create New Store Item")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Select Store Item")
        .toolbar {
            if searchText.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        showingCreateSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            StoreVariantInfoFormView(prefilledVariant: filterVariant) { newInfo in
                showingCreateSheet = false
                onSelect(newInfo)
                dismiss()
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingInfo) { info in
            StoreVariantInfoFormView(storeVariantInfo: info) { _ in
                editingInfo = nil
            }
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    NavigationStack {
        SelectStoreVariantInfoView { info in
            print("Selected: \(info.displayName)")
        }
    }
    .modelContainer(PreviewContainer.sample)
}
