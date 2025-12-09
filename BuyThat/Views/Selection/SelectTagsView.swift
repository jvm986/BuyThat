//
//  SelectTagsView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct SelectTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var selectedTags: Set<Tag>
    @State private var editingTag: Tag?

    let onSelect: (Set<Tag>) -> Void

    init(initialSelection: Set<Tag> = [], onSelect: @escaping (Set<Tag>) -> Void) {
        _selectedTags = State(initialValue: initialSelection)
        self.onSelect = onSelect
    }

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return allTags
        }
        return allTags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                    HStack {
                        Text(tag.name)
                        Spacer()
                        if selectedTags.contains(tag) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(tag)
                    }
                    .onLongPressGesture {
                        editingTag = tag
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
                                Text("Create New Tag")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Select Tags")
        .toolbar {
            if searchText.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        showingCreateSheet = true
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    onSelect(selectedTags)
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            TagFormView(
                prefillName: searchText.isEmpty ? nil : searchText,
                onSave: { newTag in
                    showingCreateSheet = false
                    selectedTags.insert(newTag)
                }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingTag) { tag in
            TagFormView(
                tag: tag,
                onSave: { _ in
                    editingTag = nil
                }
            )
            .presentationDragIndicator(.visible)
        }
    }

    private func toggleSelection(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

#Preview {
    NavigationStack {
        SelectTagsView(initialSelection: []) { tags in
            print("Selected: \(tags.map { $0.name }.joined(separator: ", "))")
        }
    }
    .modelContainer(PreviewContainer.sample)
}
