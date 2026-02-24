//
//  APIKeyManager.swift
//  BuyThat
//

import Foundation
import Security

enum APIKeyManager {
    private static let service = "com.buythat.azure-di"
    private static let endpointAccount = "azure-di-endpoint"
    private static let keyAccount = "azure-di-key"

    // MARK: - Azure Endpoint

    static func saveAzureEndpoint(_ endpoint: String) throws {
        try saveKeychainItem(endpoint, account: endpointAccount)
    }

    static func retrieveAzureEndpoint() -> String? {
        retrieveKeychainItem(account: endpointAccount)
    }

    static func deleteAzureEndpoint() {
        deleteKeychainItem(account: endpointAccount)
    }

    // MARK: - Azure API Key

    static func saveAzureAPIKey(_ key: String) throws {
        try saveKeychainItem(key, account: keyAccount)
    }

    static func retrieveAzureAPIKey() -> String? {
        retrieveKeychainItem(account: keyAccount)
    }

    static func hasAzureAPIKey() -> Bool {
        retrieveAzureAPIKey() != nil && retrieveAzureEndpoint() != nil
    }

    static func deleteAzureAPIKey() {
        deleteKeychainItem(account: keyAccount)
    }

    // MARK: - Keychain Helpers

    private static func saveKeychainItem(_ value: String, account: String) throws {
        let data = Data(value.utf8)

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw APIKeyError.saveFailed(status)
        }
    }

    private static func retrieveKeychainItem(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func deleteKeychainItem(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    enum APIKeyError: LocalizedError {
        case saveFailed(OSStatus)

        var errorDescription: String? {
            switch self {
            case .saveFailed(let status):
                return "Failed to save credential (status: \(status))"
            }
        }
    }
}
