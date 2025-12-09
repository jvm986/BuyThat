//
//  ManageTagsView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ManageTagsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var editingTag: Tag?

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return tags
        }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if filteredTags.isEmpty && !searchText.isEmpty {
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
                ForEach(filteredTags) { tag in
                    Button {
                        editingTag = tag
                    } label: {
                        HStack {
                            Text(tag.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .contain)
                }
                .onDelete(perform: deleteTags)

                if !searchText.isEmpty {
                    Section {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Create New Tag")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Tags")
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
            TagFormView(
                prefillName: searchText.isEmpty ? nil : searchText
            ) { _ in
                showingCreateSheet = false
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingTag) { tag in
            TagFormView(tag: tag) { _ in
                editingTag = nil
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTags[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ManageTagsView()
    }
    .modelContainer(PreviewContainer.sample)
}

