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
        let filtered = searchText.isEmpty ? variants : variants.filter { variant in
            variant.displayName.localizedCaseInsensitiveContains(searchText)
        }
        return filtered.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
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
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingVariant) { variant in
            ProductVariantFormView(variant: variant) { _ in
                editingVariant = nil
            }
            .presentationDragIndicator(.visible)
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

