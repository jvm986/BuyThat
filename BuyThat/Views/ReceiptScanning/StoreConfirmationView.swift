//
//  StoreConfirmationView.swift
//  BuyThat
//

import SwiftUI
import SwiftData

struct StoreConfirmationView: View {
    let detectedStoreName: String?
    let matchedStoreName: String?
    let onStoreConfirmed: (Store) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Store.name) private var allStores: [Store]

    @State private var selectedStore: Store?
    @State private var newStoreName: String
    @State private var searchText = ""
    @State private var isCreatingNew = false

    init(detectedStoreName: String?, matchedStoreName: String?, onStoreConfirmed: @escaping (Store) -> Void) {
        self.detectedStoreName = detectedStoreName
        self.matchedStoreName = matchedStoreName
        self.onStoreConfirmed = onStoreConfirmed
        _newStoreName = State(initialValue: detectedStoreName ?? "")
    }

    private var filteredStores: [Store] {
        guard !searchText.isEmpty else { return allStores }
        return allStores.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var preMatchedStore: Store? {
        guard let matchedName = matchedStoreName else { return nil }
        return allStores.first { $0.name.localizedCaseInsensitiveCompare(matchedName) == .orderedSame }
    }

    var body: some View {
        List {
            if let detectedName = detectedStoreName {
                Section {
                    HStack {
                        Image(systemName: "doc.text.viewfinder")
                            .foregroundStyle(.secondary)
                        Text("Detected: **\(detectedName)**")
                    }
                } header: {
                    Text("From Receipt")
                }
            }

            Section {
                ForEach(filteredStores) { store in
                    Button {
                        selectedStore = store
                        isCreatingNew = false
                    } label: {
                        HStack {
                            Text(store.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if store == selectedStore {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text("Select Store")
            }

            Section {
                Button {
                    isCreatingNew = true
                    selectedStore = nil
                } label: {
                    Label("Create New Store", systemImage: "plus.circle")
                }

                if isCreatingNew {
                    TextField("Store Name", text: $newStoreName)
                        .textInputAutocapitalization(.words)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search stores")
        .navigationTitle("Confirm Store")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    confirmStore()
                }
                .disabled(!canContinue)
            }
        }
        .onAppear {
            if let preMatched = preMatchedStore {
                selectedStore = preMatched
            }
        }
    }

    private var canContinue: Bool {
        selectedStore != nil || (isCreatingNew && !newStoreName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func confirmStore() {
        if let selectedStore {
            onStoreConfirmed(selectedStore)
        } else if isCreatingNew {
            let trimmedName = newStoreName.trimmingCharacters(in: .whitespacesAndNewlines)
            let store = Store(name: trimmedName)
            modelContext.insert(store)
            try? modelContext.save()
            onStoreConfirmed(store)
        }
    }
}
