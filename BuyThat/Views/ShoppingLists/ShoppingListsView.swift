//
//  ShoppingListsView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ShoppingListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingList.dateModified, order: .reverse) private var shoppingLists: [ShoppingList]

    @State private var showingCreateSheet = false
    @State private var showingSettings = false
    @State private var searchText = ""

    private var filteredLists: [ShoppingList] {
        if searchText.isEmpty {
            return shoppingLists
        }
        return shoppingLists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredLists) { list in
                    NavigationLink(value: list) {
                        VStack(alignment: .leading) {
                            Text(list.name)
                            if let itemCount = list.items?.count {
                                Text("\(itemCount) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteLists)
            }
            .searchable(text: $searchText, prompt: "Search lists")
            .navigationTitle("Shopping Lists")
            .navigationDestination(for: ShoppingList.self) { list in
                ShoppingListDetailView(shoppingList: list)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        showingCreateSheet = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                ShoppingListFormView { _ in
                    showingCreateSheet = false
                }
            }
        }
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredLists[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    ShoppingListsView()
        .modelContainer(PreviewContainer.sample)
}

