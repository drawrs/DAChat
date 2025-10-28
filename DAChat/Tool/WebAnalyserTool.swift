import Foundation
import FoundationModels
import SwiftSoup

struct WebAnalyserTool: Tool {
    let name: String = "WebAnalyser"
    let description: String = "Analyzes a website and returns the content in a structured way, like page title, description, and summary."
    private let session = URLSession.shared

    // Normalize input into a valid http/https URL
    private func normalizedURL(from raw: String) -> URL? {
        // Add scheme if missing
        if let url = URL(string: raw), url.scheme == "http" || url.scheme == "https" {
            return url
        } else if let url = URL(string: "https://" + raw) {
            return url
        }
        return nil
    }

    @Generable
    struct Arguments {
        @Guide(description: "The URL of the webpage to analyze")
        let url: String
    }

    // Define the structured metadata output
    struct WebPageMetadata: Codable {
        let title: String
        let thumbnail: String?
        let description: String?
    }

    func call(arguments: Arguments) async throws -> String {
        guard let url = normalizedURL(from: arguments.url) else {
            return #"{"error": "Invalid URL provided: \#(arguments.url)"}"#
        }
        let (data, _) = try await session.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            return #"{"error": "Failed to decode HTML content."}"#
        }

        let soup = try SwiftSoup.parse(html)
        let title = try soup.title()
        let thumbnail = try? soup.select("meta[property=og:image]").first()?.attr("content")
        let description = try? soup.select("meta[name=description]").first()?.attr("content")

        let metadata = WebPageMetadata(
            title: title,
            thumbnail: thumbnail,
            description: description
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let output = try encoder.encode(metadata)
        return String(data: output, encoding: .utf8) ?? "{}"
    }
}
