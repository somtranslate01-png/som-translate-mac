import Vision
import CoreGraphics

enum OCR {
    // Reads the text in a picture (Vision, on the machine, the language found by itself), top line first.
    static func recognize(_ image: CGImage) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true
            try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
            let lines = (request.results ?? [])
                .sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }   // (Vision's origin is the bottom left)
                .compactMap { $0.topCandidates(1).first?.string }
            return lines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
    }
}
