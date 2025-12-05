//
//  ProductFormView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ProductFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    let product: Product?
    let prefillName: String?
    let onSave: (Product) -> Void

    @State private var name: String
    @State private var selectedTags: Set<Tag>
    @State private var showingTagSelection = false
    @State private var editingTag: Tag?

    init(product: Product? = nil, prefillName: String? = nil, onSave: @escaping (Product) -> Void) {
        self.product = product
        self.prefillName = prefillName
        self.onSave = onSave
        _name = State(initialValue: product?.name ?? prefillName ?? "")
        _selectedTags = State(initialValue: Set(product?.tags ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                }

                Section("Tags") {
                    if selectedTags.isEmpty {
                        Button("Add Tags") {
                            showingTagSelection = true
                        }
                    } else {
                        ForEach(Array(selectedTags).sorted(by: { $0.name < $1.name })) { tag in
                            HStack {
                                Text(tag.name)
                                Spacer()
                                Button(role: .destructive) {
                                    selectedTags.remove(tag)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .contentShape(Rectangle())
                            .onLongPressGesture {
                                editingTag = tag
                            }
                        }

                        Button("Add More Tags") {
                            showingTagSelection = true
                        }
                    }
                }
            }
            .navigationTitle(product == nil ? "New Product" : "Edit Product")
            .onAppear {
                isNameFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingTagSelection) {
                NavigationStack {
                    SelectTagsView(initialSelection: selectedTags) { tags in
                        selectedTags = tags
                        showingTagSelection = false
                    }
                }
            }
            .sheet(item: $editingTag) { tag in
                TagFormView(tag: tag) { _ in
                    editingTag = nil
                }
            }
        }
    }

    private func save() {
        let productToSave: Product
        if let existingProduct = product {
            existingProduct.name = name
            existingProduct.tags = Array(selectedTags)
            existingProduct.dateModified = Date()
            productToSave = existingProduct
        } else {
            productToSave = Product(name: name, tags: Array(selectedTags))
            modelContext.insert(productToSave)
        }
        try? modelContext.save()
        onSave(productToSave)
        dismiss()
    }
}

#Preview {
    ProductFormView { product in
        print("Saved: \(product.name)")
    }
    .modelContainer(PreviewContainer.sample)
}
