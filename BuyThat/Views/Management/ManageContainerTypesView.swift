//
//  ManageContainerTypesView.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import SwiftUI
import SwiftData

struct ManageContainerTypesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContainerType.name) private var containerTypes: [ContainerType]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingContainerType: ContainerType?

    private var filteredContainerTypes: [ContainerType] {
        if searchText.isEmpty {
            return containerTypes
        }
        return containerTypes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if filteredContainerTypes.isEmpty && !searchText.isEmpty {
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
                ForEach(filteredContainerTypes) { ct in
                    Button {
                        editingContainerType = ct
                    } label: {
                        HStack {
                            Text(ct.name.capitalized)
                            if ct.isSystem {
                                Text("Built-in")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteContainerTypes)

                if !searchText.isEmpty {
                    Section {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Create New Container Type")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Container Types")
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
            ContainerTypeFormView(
                prefillName: searchText.isEmpty ? nil : searchText
            ) { _ in
                showingCreateSheet = false
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingContainerType) { ct in
            ContainerTypeFormView(containerType: ct) { _ in
                editingContainerType = nil
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func deleteContainerTypes(at offsets: IndexSet) {
        for index in offsets {
            let ct = filteredContainerTypes[index]
            // Prevent deletion of system types
            guard !ct.isSystem else { continue }
            modelContext.delete(ct)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ManageContainerTypesView()
    }
    .modelContainer(PreviewContainer.sample)
}
