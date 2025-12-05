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

    init(brand: Brand? = nil, prefillName: String? = nil, onSave: @escaping (Brand) -> Void) {
        self.brand = brand
        self.prefillName = prefillName
        self.onSave = onSave
        _name = State(initialValue: brand?.name ?? prefillName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .focused($isNameFocused)
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
        }
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
