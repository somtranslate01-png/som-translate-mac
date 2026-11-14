import Foundation

enum Translator {
    static var cache: [String: String] = [:]

    // Google's free text endpoint, the same service the Windows version uses. Source language: found by itself.
    static func translate(_ text: String, to target: String = "th") async throws -> String {
        let key = target + "|" + text
        if let hit = cache[key] { return hit }
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")!
        components.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: "auto"),
            URLQueryItem(name: "tl", value: target),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: text),
        ]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let root = try JSONSerialization.jsonObject(with: data) as? [Any],
              let parts = root.first as? [Any] else { throw URLError(.cannotParseResponse) }
        let result = parts.compactMap { ($0 as? [Any])?.first as? String }.joined()
        if cache.count > 500 { cache.removeAll() }
        cache[key] = result
        return result
    }
}
