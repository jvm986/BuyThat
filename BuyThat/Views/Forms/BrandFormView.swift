//
//  BrandFormView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct BrandFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    let brand: Brand?
    let prefillName: String?
    let onSave: (Brand) -> Void

    @State private var name: String
    @State private var showingCreateVariant = false
    @State private var editingVariant: ProductVariant?

    init(brand: Brand? = nil, prefillName: String? = nil, onSave: @escaping (Brand) -> Void) {
        self.brand = brand
        self.prefillName = prefillName
        self.onSave = onSave
        _name = State(initialValue: brand?.name ?? prefillName ?? "")
    }

    private var sortedVariants: [ProductVariant] {
        (brand?.variants ?? []).sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                        .accessibilityIdentifier("BrandName")
                }

                if brand != nil {
                    Section {
                        if sortedVariants.isEmpty {
                            Text("No product variants for this brand")
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
            .navigationTitle(brand == nil ? "New Brand" : "Edit Brand")
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
            .sheet(isPresented: $showingCreateVariant) {
                ProductVariantFormView { _ in
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
        let brandToSave: Brand
        if let existingBrand = brand {
            existingBrand.name = name
            brandToSave = existingBrand
        } else {
            brandToSave = Brand(name: name)
            modelContext.insert(brandToSave)
        }
        try? modelContext.save()
        onSave(brandToSave)
        dismiss()
    }
}

#Preview {
    BrandFormView { brand in
        print("Saved: \(brand.name)")
    }
    .modelContainer(PreviewContainer.sample)
}
