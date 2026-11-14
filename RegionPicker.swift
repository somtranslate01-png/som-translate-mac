import AppKit

// A dimmed layer over the screen under the pointer: drag a box round the text to translate (Esc cancels).
final class PickerView: NSView {
    var start: NSPoint?
    var current: NSPoint?
    var onDone: ((NSRect?) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    var selection: NSRect? {
        guard let a = start, let b = current else { return nil }
        return NSRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.28).setFill()
        bounds.fill()
        if let r = selection {
            NSColor.clear.setFill()
            r.fill(using: .copy)
            NSColor(calibratedRed: 1, green: 0.55, blue: 0.1, alpha: 1).setStroke()
            let path = NSBezierPath(rect: r)
            path.lineWidth = 2
            path.stroke()
        }
    }
    override func mouseDown(with event: NSEvent) { start = convert(event.locationInWindow, from: nil); current = start; needsDisplay = true }
    override func mouseDragged(with event: NSEvent) { current = convert(event.locationInWindow, from: nil); needsDisplay = true }
    override func mouseUp(with event: NSEvent) {
        current = convert(event.locationInWindow, from: nil)
        if let r = selection, r.width > 20, r.height > 12 { onDone?(r) } else { onDone?(nil) }
    }
    override func keyDown(with event: NSEvent) { if event.keyCode == 53 { onDone?(nil) } }   // Esc
}

final class RegionPicker {
    private var window: NSWindow?
    private let completion: ((rect: CGRect, screen: NSScreen)?) -> Void

    init(completion: @escaping ((rect: CGRect, screen: NSScreen)?) -> Void) { self.completion = completion }

    func begin() {
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let view = PickerView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.onDone = { [weak self, weak window] rect in
            guard let self, let window else { return }
            var result: (rect: CGRect, screen: NSScreen)? = nil
            if let rect { result = (rect: window.convertToScreen(rect), screen: screen) }
            window.orderOut(nil)
            self.window = nil
            self.completion(result)
        }
        window.contentView = view
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        NSCursor.crosshair.push()
    }
}
