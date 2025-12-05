//
//  ManageProductsView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ManageProductsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingProduct: Product?

    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return products
        }
        return products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if filteredProducts.isEmpty && !searchText.isEmpty {
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
                ForEach(filteredProducts) { product in
                    Button {
                        editingProduct = product
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.name)
                                if let tags = product.tags, !tags.isEmpty {
                                    Text(tags.map { $0.name }.joined(separator: ", "))
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
                .onDelete(perform: deleteProducts)

                if !searchText.isEmpty {
                    Section {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Create New Product")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Products")
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
            ProductFormView(
                prefillName: searchText.isEmpty ? nil : searchText
            ) { _ in
                showingCreateSheet = false
            }
        }
        .sheet(item: $editingProduct) { product in
            ProductFormView(product: product) { _ in
                editingProduct = nil
            }
        }
    }

    private func deleteProducts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredProducts[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ManageProductsView()
    }
    .modelContainer(PreviewContainer.sample)
}

