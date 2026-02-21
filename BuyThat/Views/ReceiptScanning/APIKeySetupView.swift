//
//  APIKeySetupView.swift
//  BuyThat
//

import SwiftUI

struct APIKeySetupView: View {
    let onKeyConfigured: () -> Void

    @State private var endpoint = ""
    @State private var apiKey = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Text("BuyThat uses Azure Document Intelligence to read receipt images and extract product and price information.")
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("Endpoint URL", text: $endpoint)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            } header: {
                Text("Azure Endpoint")
            } footer: {
                Text("The endpoint URL for your Azure Document Intelligence resource (e.g. https://your-resource.cognitiveservices.azure.com).")
            }

            Section {
                SecureField("API Key", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Azure API Key")
            } footer: {
                Text("Your credentials are stored securely in the device Keychain and never leave your device except for API calls.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Azure Setup")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCredentials()
                }
                .disabled(
                    endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || isSaving
                )
            }
        }
    }

    private func saveCredentials() {
        isSaving = true
        errorMessage = nil

        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try APIKeyManager.saveAzureEndpoint(trimmedEndpoint)
            try APIKeyManager.saveAzureAPIKey(trimmedKey)
            onKeyConfigured()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
