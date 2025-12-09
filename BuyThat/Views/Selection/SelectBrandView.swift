//
//  SelectBrandView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct SelectBrandView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Brand.name) private var allBrands: [Brand]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingBrand: Brand?

    let onSelect: (Brand) -> Void

    private var filteredBrands: [Brand] {
        if searchText.isEmpty {
            return allBrands
        }
        return allBrands.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                    HStack {
                        Text(brand.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(brand)
                        dismiss()
                    }
                    .onLongPressGesture {
                        editingBrand = brand
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
                                Text("Create New Brand")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Select Brand")
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
                prefillName: searchText.isEmpty ? nil : searchText,
                onSave: { newBrand in
                    showingCreateSheet = false
                    onSelect(newBrand)
                    dismiss()
                }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingBrand) { brand in
            BrandFormView(
                brand: brand,
                onSave: { _ in
                    editingBrand = nil
                }
            )
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    NavigationStack {
        SelectBrandView { brand in
            print("Selected: \(brand.name)")
        }
    }
    .modelContainer(PreviewContainer.sample)
}
