import Foundation

/// Utilities for validating and embedding YouTube learning material URLs.
enum YouTubeVideoHelper {
    static func extractVideoId(from rawURL: String) -> String? {
        let trimmedURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedURL),
              let host = url.host?.lowercased() else {
            return nil
        }

        if host.contains("youtu.be") {
            return cleanVideoId(url.pathComponents.dropFirst().first)
        }

        if host.contains("youtube.com") || host.contains("youtube-nocookie.com") {
            let pathComponents = url.pathComponents

            if let queryId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "v" })?
                .value {
                return cleanVideoId(queryId)
            }

            if let embedIndex = pathComponents.firstIndex(of: "embed"),
               pathComponents.indices.contains(embedIndex + 1) {
                return cleanVideoId(pathComponents[embedIndex + 1])
            }

            if let shortsIndex = pathComponents.firstIndex(of: "shorts"),
               pathComponents.indices.contains(shortsIndex + 1) {
                return cleanVideoId(pathComponents[shortsIndex + 1])
            }
        }

        return nil
    }

    static func thumbnailURL(for videoId: String) -> String {
        "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
    }

    private static func cleanVideoId(_ value: String?) -> String? {
        guard let value else { return nil }
        let id = value
            .split(separator: "?")
            .first?
            .split(separator: "&")
            .first
            .map(String.init) ?? ""

        return id.isEmpty ? nil : id
    }
}
