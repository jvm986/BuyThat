//
//  TagFormView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct TagFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    let tag: Tag?
    let prefillName: String?
    let onSave: (Tag) -> Void

    @State private var name: String
    @State private var editingProduct: Product?

    init(tag: Tag? = nil, prefillName: String? = nil, onSave: @escaping (Tag) -> Void) {
        self.tag = tag
        self.prefillName = prefillName
        self.onSave = onSave
        _name = State(initialValue: tag?.name ?? prefillName ?? "")
    }

    private var sortedProducts: [Product] {
        (tag?.products ?? []).sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                        .accessibilityIdentifier("TagName")
                }

                if tag != nil {
                    Section {
                        if sortedProducts.isEmpty {
                            Text("No products with this tag")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(sortedProducts) { product in
                                Button {
                                    editingProduct = product
                                } label: {
                                    HStack {
                                        Text(product.name)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("Products (\(sortedProducts.count))")
                    }
                }
            }
            .navigationTitle(tag == nil ? "New Tag" : "Edit Tag")
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
            .sheet(item: $editingProduct) { product in
                ProductFormView(product: product) { _ in
                    editingProduct = nil
                }
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func save() {
        let tagToSave: Tag
        if let existingTag = tag {
            existingTag.name = name
            tagToSave = existingTag
        } else {
            tagToSave = Tag(name: name)
            modelContext.insert(tagToSave)
        }
        try? modelContext.save()
        onSave(tagToSave)
        dismiss()
    }
}

#Preview {
    TagFormView { tag in
        print("Saved: \(tag.name)")
    }
    .modelContainer(PreviewContainer.sample)
}
