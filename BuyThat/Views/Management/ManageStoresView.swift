//
//  ManageStoresView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ManageStoresView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Store.name) private var stores: [Store]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingStore: Store?

    private var filteredStores: [Store] {
        if searchText.isEmpty {
            return stores
        }
        return stores.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                    Button {
                        editingStore = store
                    } label: {
                        HStack {
                            Text(store.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteStores)

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
        .navigationTitle("Stores")
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
                prefillName: searchText.isEmpty ? nil : searchText
            ) { _ in
                showingCreateSheet = false
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingStore) { store in
            StoreFormView(store: store) { _ in
                editingStore = nil
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func deleteStores(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredStores[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ManageStoresView()
    }
    .modelContainer(PreviewContainer.sample)
}

