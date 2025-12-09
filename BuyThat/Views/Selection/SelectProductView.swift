//
//  SelectProductView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct SelectProductView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Product.name) private var allProducts: [Product]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingProduct: Product?

    let onSelect: (Product) -> Void

    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return allProducts
        }
        return allProducts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                    VStack(alignment: .leading) {
                        Text(product.name)
                        if let tags = product.tags, !tags.isEmpty {
                            Text(tags.map { $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(product)
                        dismiss()
                    }
                    .onLongPressGesture {
                        editingProduct = product
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
                                Text("Create New Product")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Select Product")
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
                prefillName: searchText.isEmpty ? nil : searchText,
                onSave: { newProduct in
                    showingCreateSheet = false
                    onSelect(newProduct)
                    dismiss()
                }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingProduct) { product in
            ProductFormView(
                product: product,
                onSave: { _ in
                    editingProduct = nil
                }
            )
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    NavigationStack {
        SelectProductView { product in
            print("Selected: \(product.name)")
        }
    }
    .modelContainer(PreviewContainer.sample)
}
