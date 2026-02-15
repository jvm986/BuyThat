//
//  ContainerTypeFormView.swift
//  BuyThat
//
//  Created by Claude on 15.02.26.
//

import SwiftUI
import SwiftData

struct ContainerTypeFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    let containerType: ContainerType?
    let prefillName: String?
    let onSave: (ContainerType) -> Void

    @State private var name: String

    init(containerType: ContainerType? = nil, prefillName: String? = nil, onSave: @escaping (ContainerType) -> Void) {
        self.containerType = containerType
        self.prefillName = prefillName
        self.onSave = onSave
        _name = State(initialValue: containerType?.name ?? prefillName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                        .accessibilityIdentifier("ContainerTypeName")
                }

                if let ct = containerType {
                    Section {
                        let count = ct.purchaseUnits?.count ?? 0
                        if count == 0 {
                            Text("Not used by any purchase units")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Used by \(count) purchase unit\(count == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Usage")
                    }
                }
            }
            .navigationTitle(containerType == nil ? "New Container Type" : "Edit Container Type")
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
        let ctToSave: ContainerType
        if let existing = containerType {
            existing.name = name
            ctToSave = existing
        } else {
            ctToSave = ContainerType(name: name)
            modelContext.insert(ctToSave)
        }
        try? modelContext.save()
        onSave(ctToSave)
        dismiss()
    }
}

#Preview {
    ContainerTypeFormView { ct in
        print("Saved: \(ct.name)")
    }
    .modelContainer(PreviewContainer.sample)
}
