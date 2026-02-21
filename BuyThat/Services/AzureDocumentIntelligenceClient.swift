//
//  AzureDocumentIntelligenceClient.swift
//  BuyThat
//

import Foundation
import UIKit

struct AzureReceiptResult {
    let merchantName: String?
    let transactionDate: String?
    let items: [AzureReceiptItem]
}

struct AzureReceiptItem {
    let description: String
    let quantity: Double?
    let price: Decimal?
    let totalPrice: Decimal?
}

enum AzureDocumentIntelligenceClient {
    private static let apiVersion = "2024-11-30"
    private static let maxImageBytes = 4_000_000
    private static let totalTimeout: TimeInterval = 60
    private static let pollInterval: UInt64 = 1_000_000_000 // 1 second in nanoseconds

    static func analyzeReceipt(image: UIImage) async throws -> AzureReceiptResult {
        guard let endpoint = APIKeyManager.retrieveAzureEndpoint() else {
            throw AzureError.noCredentials
        }
        guard let apiKey = APIKeyManager.retrieveAzureAPIKey() else {
            throw AzureError.noCredentials
        }

        let base64Image = try compressAndEncode(image)
        let imageData = Data(base64Encoded: base64Image)!

        // Submit analysis request
        let operationLocation = try await submitAnalysis(
            endpoint: endpoint,
            apiKey: apiKey,
            imageData: imageData
        )

        // Poll for result
        let result = try await pollForResult(
            operationURL: operationLocation,
            apiKey: apiKey
        )

        return result
    }

    // MARK: - Submit

    private static func submitAnalysis(
        endpoint: String,
        apiKey: String,
        imageData: Data
    ) async throws -> URL {
        let trimmedEndpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = "\(trimmedEndpoint)/documentintelligence/documentModels/prebuilt-receipt:analyze?api-version=\(apiVersion)"

        guard let url = URL(string: urlString) else {
            throw AzureError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = imageData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 202:
            guard let operationLocationString = httpResponse.value(forHTTPHeaderField: "Operation-Location"),
                  let operationURL = URL(string: operationLocationString) else {
                throw AzureError.missingOperationLocation
            }
            return operationURL
        case 401:
            throw AzureError.invalidCredentials
        case 404:
            throw AzureError.invalidEndpoint
        default:
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AzureError.apiError(statusCode: httpResponse.statusCode, message: body)
        }
    }

    // MARK: - Poll

    private static func pollForResult(
        operationURL: URL,
        apiKey: String
    ) async throws -> AzureReceiptResult {
        let startTime = Date()

        while true {
            try Task.checkCancellation()

            if Date().timeIntervalSince(startTime) > totalTimeout {
                throw AzureError.timeout
            }

            try await Task.sleep(nanoseconds: pollInterval)

            var request = URLRequest(url: operationURL)
            request.httpMethod = "GET"
            request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw AzureError.invalidResponse
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let status = json?["status"] as? String else {
                throw AzureError.invalidResponse
            }

            switch status {
            case "succeeded":
                return try parseResult(json: json!)
            case "failed":
                let error = (json?["error"] as? [String: Any])?["message"] as? String ?? "Analysis failed"
                throw AzureError.analysisFailed(error)
            case "running", "notStarted":
                continue
            default:
                continue
            }
        }
    }

    // MARK: - Parse

    private static func parseResult(json: [String: Any]) throws -> AzureReceiptResult {
        guard let analyzeResult = json["analyzeResult"] as? [String: Any],
              let documents = analyzeResult["documents"] as? [[String: Any]] else {
            return AzureReceiptResult(merchantName: nil, transactionDate: nil, items: [])
        }

        guard let firstDoc = documents.first,
              let fields = firstDoc["fields"] as? [String: Any] else {
            return AzureReceiptResult(merchantName: nil, transactionDate: nil, items: [])
        }

        let merchantName = extractStringValue(fields["MerchantName"])
        let transactionDate = extractStringValue(fields["TransactionDate"])
            ?? extractDateValue(fields["TransactionDate"])

        var items: [AzureReceiptItem] = []
        if let itemsField = fields["Items"] as? [String: Any],
           let valueArray = itemsField["valueArray"] as? [[String: Any]] {
            for itemEntry in valueArray {
                guard let itemFields = itemEntry["valueObject"] as? [String: Any] else { continue }

                let description = extractStringValue(itemFields["Description"]) ?? ""
                guard !description.isEmpty else { continue }

                let quantity = extractNumberValue(itemFields["Quantity"])
                let price = extractCurrencyValue(itemFields["Price"])
                let totalPrice = extractCurrencyValue(itemFields["TotalPrice"])

                items.append(AzureReceiptItem(
                    description: description,
                    quantity: quantity,
                    price: price,
                    totalPrice: totalPrice
                ))
            }
        }

        return AzureReceiptResult(
            merchantName: merchantName,
            transactionDate: transactionDate,
            items: items
        )
    }

    // MARK: - Field Extraction Helpers

    private static func extractStringValue(_ field: Any?) -> String? {
        guard let dict = field as? [String: Any] else { return nil }
        return dict["valueString"] as? String
    }

    private static func extractDateValue(_ field: Any?) -> String? {
        guard let dict = field as? [String: Any] else { return nil }
        return dict["valueDate"] as? String
    }

    private static func extractNumberValue(_ field: Any?) -> Double? {
        guard let dict = field as? [String: Any] else { return nil }
        return dict["valueNumber"] as? Double
    }

    private static func extractCurrencyValue(_ field: Any?) -> Decimal? {
        guard let dict = field as? [String: Any] else { return nil }
        if let currencyObj = dict["valueCurrency"] as? [String: Any],
           let amount = currencyObj["amount"] as? Double {
            return Decimal(amount)
        }
        if let number = dict["valueNumber"] as? Double {
            return Decimal(number)
        }
        return nil
    }

    // MARK: - Image Compression

    private static func compressAndEncode(_ image: UIImage) throws -> String {
        var quality: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: quality)

        while let d = data, d.count > maxImageBytes, quality > 0.1 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)
        }

        guard let finalData = data else {
            throw AzureError.imageCompressionFailed
        }

        return finalData.base64EncodedString()
    }

    // MARK: - Errors

    enum AzureError: LocalizedError {
        case noCredentials
        case invalidCredentials
        case invalidEndpoint
        case invalidResponse
        case missingOperationLocation
        case apiError(statusCode: Int, message: String)
        case timeout
        case analysisFailed(String)
        case imageCompressionFailed

        var errorDescription: String? {
            switch self {
            case .noCredentials:
                return "Azure Document Intelligence credentials not configured. Please add them in Settings."
            case .invalidCredentials:
                return "Invalid Azure credentials. Please check your API key in Settings."
            case .invalidEndpoint:
                return "Invalid Azure endpoint URL. Please check your endpoint in Settings."
            case .invalidResponse:
                return "Invalid response from Azure Document Intelligence."
            case .missingOperationLocation:
                return "Azure did not return an operation location for polling."
            case .apiError(let statusCode, let message):
                return "Azure API error (\(statusCode)): \(message)"
            case .timeout:
                return "Receipt analysis timed out. Please try again."
            case .analysisFailed(let message):
                return "Receipt analysis failed: \(message)"
            case .imageCompressionFailed:
                return "Failed to compress receipt image."
            }
        }
    }
}
