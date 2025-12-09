//
//  SelectProductVariantView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct SelectProductVariantView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ProductVariant.dateCreated, order: .reverse) private var allVariants: [ProductVariant]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingVariant: ProductVariant?

    let onSelect: (ProductVariant) -> Void

    private var filteredVariants: [ProductVariant] {
        if searchText.isEmpty {
            return allVariants
        }
        return allVariants.filter { variant in
            variant.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            if filteredVariants.isEmpty && !searchText.isEmpty {
                Section {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Create New Variant")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } else {
                ForEach(filteredVariants) { variant in
                    HStack {
                        Text(variant.displayName)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(variant)
                        dismiss()
                    }
                    .onLongPressGesture {
                        editingVariant = variant
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
                                Text("Create New Variant")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Select Variant")
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
            ProductVariantFormView { newVariant in
                showingCreateSheet = false
                onSelect(newVariant)
                dismiss()
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

#Preview {
    NavigationStack {
        SelectProductVariantView { variant in
            print("Selected: \(variant.displayName)")
        }
    }
    .modelContainer(PreviewContainer.sample)
}
