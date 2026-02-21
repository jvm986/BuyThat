//
//  APIKeyManagementView.swift
//  BuyThat
//

import SwiftUI

struct APIKeyManagementView: View {
    @State private var hasCredentials = APIKeyManager.hasAzureAPIKey()
    @State private var newEndpoint = ""
    @State private var newKey = ""
    @State private var isEditing = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                if hasCredentials && !isEditing {
                    HStack {
                        Text("Endpoint")
                        Spacer()
                        Text("Configured")
                            .foregroundStyle(.green)
                    }

                    HStack {
                        Text("API Key")
                        Spacer()
                        Text("Configured")
                            .foregroundStyle(.green)
                    }

                    Button("Update Credentials") {
                        isEditing = true
                    }

                    Button("Remove Credentials", role: .destructive) {
                        APIKeyManager.deleteAzureEndpoint()
                        APIKeyManager.deleteAzureAPIKey()
                        hasCredentials = false
                    }
                } else {
                    TextField("Endpoint URL", text: $newEndpoint)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    SecureField("API Key", text: $newKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Save") {
                        saveCredentials()
                    }
                    .disabled(
                        newEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || newKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

                    if isEditing {
                        Button("Cancel", role: .cancel) {
                            isEditing = false
                            newEndpoint = ""
                            newKey = ""
                        }
                    }
                }
            } header: {
                Text("Azure Document Intelligence")
            } footer: {
                Text("Used for receipt scanning. Your credentials are stored securely in the device Keychain.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Receipt Scanning")
    }

    private func saveCredentials() {
        errorMessage = nil
        let trimmedEndpoint = newEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try APIKeyManager.saveAzureEndpoint(trimmedEndpoint)
            try APIKeyManager.saveAzureAPIKey(trimmedKey)
            hasCredentials = true
            isEditing = false
            newEndpoint = ""
            newKey = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
