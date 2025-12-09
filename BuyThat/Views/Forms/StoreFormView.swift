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
    @State private var showingCreateStoreInfo = false
    @State private var editingStoreInfo: StoreVariantInfo?

    init(store: Store? = nil, prefillName: String? = nil, onSave: @escaping (Store) -> Void) {
        self.store = store
        self.prefillName = prefillName
        self.onSave = onSave
        _name = State(initialValue: store?.name ?? prefillName ?? "")
    }

    private var sortedStoreInfos: [StoreVariantInfo] {
        (store?.storeVariantInfos ?? []).sorted { ($0.variant?.displayName ?? "") < ($1.variant?.displayName ?? "") }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                }

                if store != nil {
                    Section {
                        if sortedStoreInfos.isEmpty {
                            Text("No products in this store")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(sortedStoreInfos) { info in
                                Button {
                                    editingStoreInfo = info
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(info.variant?.displayName ?? "Unknown")
                                            if let price = info.formattedPrice {
                                                Text(price)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete(perform: deleteStoreInfos)
                        }

                        Button {
                            showingCreateStoreInfo = true
                        } label: {
                            Label("Add Product", systemImage: "plus.circle.fill")
                        }
                    } header: {
                        Text("Products (\(sortedStoreInfos.count))")
                    }
                }
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
            .sheet(isPresented: $showingCreateStoreInfo) {
                StoreVariantInfoFormView { _ in
                    showingCreateStoreInfo = false
                }
            }
            .sheet(item: $editingStoreInfo) { info in
                StoreVariantInfoFormView(storeVariantInfo: info) { _ in
                    editingStoreInfo = nil
                }
            }
        }
    }

    private func deleteStoreInfos(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedStoreInfos[index])
        }
        try? modelContext.save()
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
