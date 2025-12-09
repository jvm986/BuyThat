//
//  SelectStoreView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct SelectStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Store.name) private var allStores: [Store]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingStore: Store?

    let onSelect: (Store) -> Void

    private var filteredStores: [Store] {
        if searchText.isEmpty {
            return allStores
        }
        return allStores.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if filteredStores.isEmpty && !searchText.isEmpty {
                Section {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Create \"\(searchText)\"")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } else {
                ForEach(filteredStores) { store in
                    HStack {
                        Text(store.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(store)
                        dismiss()
                    }
                    .onLongPressGesture {
                        editingStore = store
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
                                Text("Create New Store")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Select Store")
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
            StoreFormView(
                prefillName: searchText.isEmpty ? nil : searchText,
                onSave: { newStore in
                    showingCreateSheet = false
                    onSelect(newStore)
                    dismiss()
                }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingStore) { store in
            StoreFormView(
                store: store,
                onSave: { _ in
                    editingStore = nil
                }
            )
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    NavigationStack {
        SelectStoreView { store in
            print("Selected: \(store.name)")
        }
    }
    .modelContainer(PreviewContainer.sample)
}
