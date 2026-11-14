import AppKit

// The subtitle: a dark rounded bar at the bottom of the screen, over every window and every Space, that takes no clicks.
// Its size follows the screen (80 % of the width, letters 3.2 % of the height), so it looks the same on any display.
final class SubtitleWindow {
    private var panel: NSPanel?
    private let label = NSTextField(labelWithString: "")
    private var hideTask: Task<Void, Never>?

    func show(_ text: String, on screen: NSScreen, hideAfter seconds: Double? = nil) {
        let width = screen.frame.width * 0.8
        let fontSize = max(18, screen.frame.height * 0.032)
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let textWidth = width - 40
        let box = (text as NSString).boundingRect(with: NSSize(width: textWidth, height: .greatestFiniteMagnitude),
                                                  options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                  attributes: [.font: font])
        let height = ceil(box.height) + 26

        if panel == nil {
            let p = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.level = .statusBar
            p.ignoresMouseEvents = true
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            let content = NSView()
            content.wantsLayer = true
            content.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.74).cgColor
            content.layer?.cornerRadius = 14
            label.alignment = .center
            label.textColor = .white
            label.maximumNumberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            content.addSubview(label)
            p.contentView = content
            panel = p
        }
        label.stringValue = text
        label.font = font
        label.frame = NSRect(x: 20, y: 13, width: textWidth, height: ceil(box.height))
        let frame = NSRect(x: screen.frame.midX - width / 2, y: screen.visibleFrame.minY + screen.frame.height * 0.06,
                           width: width, height: height)
        panel?.setFrame(frame, display: true)
        panel?.orderFrontRegardless()

        hideTask?.cancel()
        if let seconds {
            hideTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                if !Task.isCancelled { self?.panel?.orderOut(nil) }
            }
        }
    }

    func hide() { hideTask?.cancel(); panel?.orderOut(nil) }
}
