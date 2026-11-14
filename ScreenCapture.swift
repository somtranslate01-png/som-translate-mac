import AppKit
import ScreenCaptureKit

enum CaptureError: LocalizedError {
    case noDisplay
    var errorDescription: String? { "หาจอที่เลือกไม่เจอ" }
}

enum ScreenCapture {
    // rect is in Cocoa global coordinates (origin bottom left), screen is the screen it lies on.
    static func capture(rect: CGRect, screen: NSScreen) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
              let display = content.displays.first(where: { $0.displayID == number.uint32Value })
        else { throw CaptureError.noDisplay }

        // The program's own windows (the subtitle) are left out, so it never reads its own translation.
        let pid = ProcessInfo.processInfo.processIdentifier
        let own = content.windows.filter { $0.owningApplication?.processID == pid }
        let filter = SCContentFilter(display: display, excludingWindows: own)

        let config = SCStreamConfiguration()
        let scale = screen.backingScaleFactor
        // To the display's own coordinates: origin top left, in points.
        config.sourceRect = CGRect(x: rect.minX - screen.frame.minX,
                                   y: screen.frame.maxY - rect.maxY,
                                   width: rect.width, height: rect.height)
        config.width = max(1, Int(rect.width * scale))
        config.height = max(1, Int(rect.height * scale))
        config.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    // A cheap fingerprint of a picture, so that an unchanged frame is not read again.
    static func quickHash(_ image: CGImage) -> Int {
        guard let data = image.dataProvider?.data else { return 0 }
        let length = CFDataGetLength(data)
        guard let bytes = CFDataGetBytePtr(data) else { return 0 }
        var hasher = Hasher()
        hasher.combine(length)
        var i = 0
        while i < length { hasher.combine(bytes[i]); i += 97 }
        return hasher.finalize()
    }
}
