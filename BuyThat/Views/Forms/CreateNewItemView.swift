//
//  CreateNewItemView.swift
//  BuyThat
//
//  Created by Claude on 08.12.25.
//

import SwiftUI

struct CreateNewItemView: View {
    @Environment(\.dismiss) private var dismiss

    let searchText: String
    let onCreate: (Any) -> Void

    @State private var selectedType: ItemType = .product
    @State private var showingForm = false

    enum ItemType: String, CaseIterable {
        case product = "Product"
        case variant = "Variant"
        case storeItem = "Store Item"
    }

    var body: some View {
        List {
            Section("What would you like to create?") {
                ForEach(ItemType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                        showingForm = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(type.rawValue)
                                    .foregroundStyle(.primary)
                                Text(description(for: type))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: icon(for: type))
                                .foregroundStyle(color(for: type))
                        }
                    }
                }
            }
        }
        .navigationTitle("Create New")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .sheet(isPresented: $showingForm) {
            switch selectedType {
            case .product:
                ProductFormView(prefillName: searchText) { product in
                    showingForm = false
                    onCreate(product)
                    dismiss()
                }
            case .variant:
                ProductVariantFormView { variant in
                    showingForm = false
                    onCreate(variant)
                    dismiss()
                }
            case .storeItem:
                StoreVariantInfoFormView { storeInfo in
                    showingForm = false
                    onCreate(storeInfo)
                    dismiss()
                }
            }
        }
    }

    private func description(for type: ItemType) -> String {
        switch type {
        case .product:
            return "Just the product name (e.g., Milk)"
        case .variant:
            return "Product with brand/details (e.g., Tesco Organic Milk)"
        case .storeItem:
            return "Variant with store and pricing"
        }
    }

    private func icon(for type: ItemType) -> String {
        switch type {
        case .product:
            return "square.grid.2x2.fill"
        case .variant:
            return "shippingbox.fill"
        case .storeItem:
            return "tag.fill"
        }
    }

    private func color(for type: ItemType) -> Color {
        switch type {
        case .product:
            return .orange
        case .variant:
            return .blue
        case .storeItem:
            return .green
        }
    }
}

#Preview {
    NavigationStack {
        CreateNewItemView(searchText: "Milk") { item in
            print("Created: \(item)")
        }
    }
}
