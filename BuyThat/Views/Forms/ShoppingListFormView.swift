//
//  ShoppingListFormView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct ShoppingListFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    let shoppingList: ShoppingList?
    let onSave: (ShoppingList) -> Void

    @State private var name: String

    init(shoppingList: ShoppingList? = nil, onSave: @escaping (ShoppingList) -> Void) {
        self.shoppingList = shoppingList
        self.onSave = onSave
        _name = State(initialValue: shoppingList?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .focused($isNameFocused)
            }
            .navigationTitle(shoppingList == nil ? "New Shopping List" : "Edit Shopping List")
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
        let listToSave: ShoppingList
        if let existingList = shoppingList {
            existingList.name = name
            existingList.dateModified = Date()
            listToSave = existingList
        } else {
            listToSave = ShoppingList(name: name)
            modelContext.insert(listToSave)
        }
        try? modelContext.save()
        onSave(listToSave)
        dismiss()
    }
}

#Preview {
    ShoppingListFormView { list in
        print("Saved: \(list.name)")
    }
    .modelContainer(PreviewContainer.sample)
}
