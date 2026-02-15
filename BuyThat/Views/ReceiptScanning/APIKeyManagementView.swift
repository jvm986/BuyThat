//
//  APIKeyManagementView.swift
//  BuyThat
//

import SwiftUI

struct APIKeyManagementView: View {
    @State private var hasKey = APIKeyManager.hasAPIKey()
    @State private var newKey = ""
    @State private var isEditing = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                if hasKey && !isEditing {
                    HStack {
                        Text("API Key")
                        Spacer()
                        Text("Configured")
                            .foregroundStyle(.green)
                    }

                    Button("Update Key") {
                        isEditing = true
                    }

                    Button("Remove Key", role: .destructive) {
                        APIKeyManager.deleteAPIKey()
                        hasKey = false
                    }
                } else {
                    SecureField("OpenAI API Key", text: $newKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Save") {
                        saveKey()
                    }
                    .disabled(newKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if isEditing {
                        Button("Cancel", role: .cancel) {
                            isEditing = false
                            newKey = ""
                        }
                    }
                }
            } header: {
                Text("OpenAI API Key")
            } footer: {
                Text("Used for receipt scanning. Your key is stored securely in the device Keychain.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                    Label("Manage keys on OpenAI", systemImage: "arrow.up.right.square")
                }
            }
        }
        .navigationTitle("Receipt Scanning")
    }

    private func saveKey() {
        errorMessage = nil
        let trimmedKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try APIKeyManager.saveAPIKey(trimmedKey)
            hasKey = true
            isEditing = false
            newKey = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
