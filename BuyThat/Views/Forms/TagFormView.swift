//
//  TagFormView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct TagFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    let tag: Tag?
    let prefillName: String?
    let onSave: (Tag) -> Void

    @State private var name: String

    init(tag: Tag? = nil, prefillName: String? = nil, onSave: @escaping (Tag) -> Void) {
        self.tag = tag
        self.prefillName = prefillName
        self.onSave = onSave
        _name = State(initialValue: tag?.name ?? prefillName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .focused($isNameFocused)
            }
            .navigationTitle(tag == nil ? "New Tag" : "Edit Tag")
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
        let tagToSave: Tag
        if let existingTag = tag {
            existingTag.name = name
            tagToSave = existingTag
        } else {
            tagToSave = Tag(name: name)
            modelContext.insert(tagToSave)
        }
        try? modelContext.save()
        onSave(tagToSave)
        dismiss()
    }
}

#Preview {
    TagFormView { tag in
        print("Saved: \(tag.name)")
    }
    .modelContainer(PreviewContainer.sample)
}
