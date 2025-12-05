//
//  StoreFormView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct StoreFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    let store: Store?
    let prefillName: String?
    let onSave: (Store) -> Void

    @State private var name: String

    init(store: Store? = nil, prefillName: String? = nil, onSave: @escaping (Store) -> Void) {
        self.store = store
        self.prefillName = prefillName
        self.onSave = onSave
        _name = State(initialValue: store?.name ?? prefillName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .focused($isNameFocused)
            }
            .navigationTitle(store == nil ? "New Store" : "Edit Store")
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
        let storeToSave: Store
        if let existingStore = store {
            existingStore.name = name
            storeToSave = existingStore
        } else {
            storeToSave = Store(name: name)
            modelContext.insert(storeToSave)
        }
        try? modelContext.save()
        onSave(storeToSave)
        dismiss()
    }
}

#Preview {
    StoreFormView { store in
        print("Saved: \(store.name)")
    }
    .modelContainer(PreviewContainer.sample)
}
