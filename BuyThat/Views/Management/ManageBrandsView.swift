//
//  ManageBrandsView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ManageBrandsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Brand.name) private var brands: [Brand]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingBrand: Brand?

    private var filteredBrands: [Brand] {
        if searchText.isEmpty {
            return brands
        }
        return brands.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if filteredBrands.isEmpty && !searchText.isEmpty {
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
                ForEach(filteredBrands) { brand in
                    Button {
                        editingBrand = brand
                    } label: {
                        HStack {
                            Text(brand.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteBrands)

                if !searchText.isEmpty {
                    Section {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Create New Brand")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Brands")
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
            BrandFormView(
                prefillName: searchText.isEmpty ? nil : searchText
            ) { _ in
                showingCreateSheet = false
            }
        }
        .sheet(item: $editingBrand) { brand in
            BrandFormView(brand: brand) { _ in
                editingBrand = nil
            }
        }
    }

    private func deleteBrands(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredBrands[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ManageBrandsView()
    }
    .modelContainer(PreviewContainer.sample)
}

