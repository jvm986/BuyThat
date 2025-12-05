//
//  ManageProductVariantsView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ManageProductVariantsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProductVariant.dateCreated, order: .reverse) private var variants: [ProductVariant]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingVariant: ProductVariant?

    private var filteredVariants: [ProductVariant] {
        if searchText.isEmpty {
            return variants
        }
        return variants.filter { variant in
            variant.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredVariants) { variant in
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
        .searchable(text: $searchText)
        .navigationTitle("Product Variants")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    showingCreateSheet = true
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            ProductVariantFormView { _ in
                showingCreateSheet = false
            }
        }
        .sheet(item: $editingVariant) { variant in
            ProductVariantFormView(variant: variant) { _ in
                editingVariant = nil
            }
        }
    }

    private func deleteVariants(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredVariants[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ManageProductVariantsView()
    }
    .modelContainer(PreviewContainer.sample)
}

