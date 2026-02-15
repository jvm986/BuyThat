//
//  ItemListFormView.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import SwiftUI
import SwiftData

struct ItemListFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    let itemList: ItemList?
    let onSave: (ItemList) -> Void

    @State private var name: String

    init(itemList: ItemList? = nil, onSave: @escaping (ItemList) -> Void) {
        self.itemList = itemList
        self.onSave = onSave
        _name = State(initialValue: itemList?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .focused($isNameFocused)
            }
            .navigationTitle(itemList == nil ? "New List" : "Edit List")
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
        let listToSave: ItemList
        if let existingList = itemList {
            existingList.name = name
            existingList.dateModified = Date()
            listToSave = existingList
        } else {
            listToSave = ItemList(name: name)
            modelContext.insert(listToSave)
        }
        try? modelContext.save()
        onSave(listToSave)
        dismiss()
    }
}

#Preview {
    ItemListFormView { list in
        print("Saved: \(list.name)")
    }
    .modelContainer(PreviewContainer.sample)
}
