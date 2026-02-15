//
//  APIKeySetupView.swift
//  BuyThat
//

import SwiftUI

struct APIKeySetupView: View {
    let onKeyConfigured: () -> Void

    @State private var apiKey = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Text("BuyThat uses OpenAI's vision API to read receipt images and extract product and price information.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                    Label("Get an API key from OpenAI", systemImage: "arrow.up.right.square")
                }

                SecureField("API Key", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("OpenAI API Key")
            } footer: {
                Text("Your key is stored securely in the device Keychain and never leaves your device except for API calls.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("API Key Setup")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveKey()
                }
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
    }

    private func saveKey() {
        isSaving = true
        errorMessage = nil

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try APIKeyManager.saveAPIKey(trimmedKey)
            onKeyConfigured()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
