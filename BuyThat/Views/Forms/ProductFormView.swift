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
    @State private var showingCreateVariant = false
    @State private var editingVariant: ProductVariant?

    init(product: Product? = nil, prefillName: String? = nil, onSave: @escaping (Product) -> Void) {
        self.product = product
        self.prefillName = prefillName
        self.onSave = onSave
        _name = State(initialValue: product?.name ?? prefillName ?? "")
        _selectedTags = State(initialValue: Set(product?.tags ?? []))
    }

    private var sortedVariants: [ProductVariant] {
        (product?.variants ?? []).sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                        .accessibilityIdentifier("Product name")
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

                if product != nil {
                    Section {
                        if sortedVariants.isEmpty {
                            Text("No product variants")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(sortedVariants) { variant in
                                Button {
                                    editingVariant = variant
                                } label: {
                                    HStack {
                                        Text(variant.displayName)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete(perform: deleteVariants)
                        }

                        Button {
                            showingCreateVariant = true
                        } label: {
                            Label("Add Product Variant", systemImage: "plus.circle.fill")
                        }
                    } header: {
                        Text("Product Variants (\(sortedVariants.count))")
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
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingTag) { tag in
                TagFormView(tag: tag) { _ in
                    editingTag = nil
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingCreateVariant) {
                ProductVariantFormView(prefilledProduct: product) { _ in
                    showingCreateVariant = false
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingVariant) { variant in
                ProductVariantFormView(variant: variant) { _ in
                    editingVariant = nil
                }
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func deleteVariants(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedVariants[index])
        }
        try? modelContext.save()
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
