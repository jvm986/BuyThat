//
//  OpenAIClient.swift
//  BuyThat
//

import Foundation
import UIKit

enum OpenAIClient {
    private static let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private static let model = "gpt-4o-mini"
    private static let maxImageBytes = 2_000_000
    private static let timeoutInterval: TimeInterval = 30

    static func analyzeReceipt(
        image: UIImage,
        existingProducts: [String],
        existingBrands: [String],
        existingStores: [String],
        existingTags: [String]
    ) async throws -> LLMReceiptResponse {
        guard let apiKey = APIKeyManager.retrieveAPIKey() else {
            throw OpenAIError.noAPIKey
        }

        let base64Image = try compressAndEncode(image)
        let prompt = buildPrompt(
            existingProducts: existingProducts,
            existingBrands: existingBrands,
            existingStores: existingStores,
            existingTags: existingTags
        )

        let requestBody = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "user", content: [
                    .init(type: "text", text: prompt),
                    .init(type: "image_url", image_url: .init(url: "data:image/jpeg;base64,\(base64Image)"))
                ])
            ],
            response_format: .init(type: "json_object"),
            max_tokens: 4096
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw OpenAIError.invalidAPIKey
        case 429:
            throw OpenAIError.rateLimited
        default:
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw OpenAIError.emptyResponse
        }

        guard let contentData = content.data(using: .utf8) else {
            throw OpenAIError.invalidJSON
        }

        return try JSONDecoder().decode(LLMReceiptResponse.self, from: contentData)
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
            throw OpenAIError.imageCompressionFailed
        }

        return finalData.base64EncodedString()
    }

    // MARK: - Prompt

    private static func buildPrompt(
        existingProducts: [String],
        existingBrands: [String],
        existingStores: [String],
        existingTags: [String]
    ) -> String {
        let productsList = existingProducts.isEmpty ? "None" : existingProducts.joined(separator: ", ")
        let brandsList = existingBrands.isEmpty ? "None" : existingBrands.joined(separator: ", ")
        let storesList = existingStores.isEmpty ? "None" : existingStores.joined(separator: ", ")
        let tagsList = existingTags.isEmpty ? "None" : existingTags.joined(separator: ", ")

        return """
        You are a receipt parser. Analyze this receipt image and extract ALL purchased product line items.

        I have the following existing data in my shopping app:
        - Products: [\(productsList)]
        - Brands: [\(brandsList)]
        - Stores: [\(storesList)]
        - Tags: [\(tagsList)]

        Return a JSON object with this exact structure:
        {
          "storeName": "Store name from receipt or null",
          "matchedStoreName": "Best match from my stores list or null",
          "receiptDate": "YYYY-MM-DD or null",
          "items": [
            {
              "receiptText": "Text as shown on receipt",
              "price": 2.99,
              "quantity": 1,
              "unit": "Package size if visible (e.g. 1L, 500g, 0.242kg) or null",
              "unitPrice": 5.99,
              "unitPriceUnit": "kg",
              "matchedProductName": "Best match from my products list or null",
              "matchedBrandName": "Best match from my brands list or null",
              "matchedTagNames": ["Organic"]
            }
          ]
        }

        Rules:
        - IMPORTANT: Extract EVERY purchasable product line item on the receipt. Do not skip any items. Receipts often have many items — include all of them.
        - Skip ONLY totals, subtotals, tax lines, payment method lines, change, loyalty points, and receipt headers/footers
        - "price" is the total line price paid for that item (after any discounts)
        - "unitPrice" is the per-unit price (e.g. price per kg, per L) when shown on the receipt — this is common for weighed items like produce, meat, deli. Set to null if not shown.
        - "unitPriceUnit" is the unit for unitPrice (e.g. "kg", "L"). Set to null if unitPrice is null.
        - If quantity > 1, "price" should still be the per-item price (total line price divided by quantity)
        - Match to existing products/brands only when confident — use null otherwise
        - For matchedProductName, match the core product (e.g. receipt "TES ORG MLK 1L" → "Milk", "PAPRIKA" → "Paprika")
        - Receipt text is often abbreviated — use your knowledge to identify products even from short codes
        - "matchedTagNames" is an array of tags from my tags list that apply to this product (e.g. "Organic", "Gluten Free"). Only use tags from the provided list. Use an empty array if no tags apply.
        """
    }

    // MARK: - Error Types

    enum OpenAIError: LocalizedError {
        case noAPIKey
        case invalidAPIKey
        case rateLimited
        case apiError(statusCode: Int, message: String)
        case invalidResponse
        case emptyResponse
        case invalidJSON
        case imageCompressionFailed

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No API key configured. Please add your OpenAI API key in Settings."
            case .invalidAPIKey:
                return "Invalid API key. Please check your OpenAI API key in Settings."
            case .rateLimited:
                return "Rate limited by OpenAI. Please wait a moment and try again."
            case .apiError(let statusCode, let message):
                return "API error (\(statusCode)): \(message)"
            case .invalidResponse:
                return "Invalid response from OpenAI."
            case .emptyResponse:
                return "Empty response from OpenAI."
            case .invalidJSON:
                return "Failed to parse receipt data from response."
            case .imageCompressionFailed:
                return "Failed to compress receipt image."
            }
        }
    }
}

// MARK: - Request/Response Models

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let response_format: ResponseFormat
    let max_tokens: Int
}

private struct ChatMessage: Encodable {
    let role: String
    let content: [ContentPart]
}

private struct ContentPart: Encodable {
    let type: String
    var text: String?
    var image_url: ImageURL?

    struct ImageURL: Encodable {
        let url: String
    }
}

private struct ResponseFormat: Encodable {
    let type: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String?
    }
}
