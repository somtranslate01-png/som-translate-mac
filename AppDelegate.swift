import AppKit
import Carbon

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var toggleItem: NSMenuItem!
    private var region: (rect: CGRect, screen: NSScreen)?
    private var live = false
    private var loop: Task<Void, Never>?
    private let subtitle = SubtitleWindow()
    private var picker: RegionPicker?
    private var lastHash = 0
    private var lastText = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        // Control + Option + 1: pick the box. Control + Option + 2: start / stop. (F-keys need Fn on a Mac, so these are used.)
        let mods = UInt32(controlKey | optionKey)
        HotKey.register(keyCode: 18, modifiers: mods, id: 1) { [weak self] in MainActor.assumeIsolated { self?.pickRegion() } }
        HotKey.register(keyCode: 19, modifiers: mods, id: 2) { [weak self] in MainActor.assumeIsolated { self?.toggleLive() } }
        if !CGPreflightScreenCaptureAccess() { _ = CGRequestScreenCaptureAccess() }
    }

    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "ส้ม"
        let menu = NSMenu()
        menu.addItem(withTitle: "เลือกกรอบที่จะแปล   ⌃⌥1", action: #selector(pickRegion), keyEquivalent: "").target = self
        toggleItem = menu.addItem(withTitle: "เริ่มแปล   ⌃⌥2", action: #selector(toggleLive), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(withTitle: "แปลครั้งเดียว", action: #selector(translateOnce), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "ออกจากโปรแกรม", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
    }

    @objc private func pickRegion() {
        picker = RegionPicker { [weak self] result in
            guard let self else { return }
            self.picker = nil
            NSCursor.pop()
            guard let result else { return }
            self.region = result
            self.lastHash = 0
            self.lastText = ""
            self.subtitle.show("เลือกกรอบแล้ว · กด ⌃⌥2 เพื่อเริ่มแปล", on: result.screen, hideAfter: 3)
        }
        picker?.begin()
    }

    @objc private func toggleLive() {
        guard region != nil else { pickRegion(); return }
        live.toggle()
        toggleItem.title = live ? "หยุดแปล   ⌃⌥2" : "เริ่มแปล   ⌃⌥2"
        statusItem.button?.title = live ? "ส้ม ●" : "ส้ม"
        loop?.cancel()
        if live {
            loop = Task { [weak self] in
                while !Task.isCancelled {
                    await self?.tick()
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        } else {
            subtitle.hide()
        }
    }

    @objc private func translateOnce() {
        guard region != nil else { pickRegion(); return }
        lastHash = 0
        lastText = ""
        Task { await tick() }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func tick() async {
        guard let region else { return }
        do {
            let image = try await ScreenCapture.capture(rect: region.rect, screen: region.screen)
            let hash = ScreenCapture.quickHash(image)
            if hash == lastHash { return }
            lastHash = hash
            let text = try await OCR.recognize(image)
            guard !text.isEmpty, text != lastText else { return }
            lastText = text
            let thai = try await Translator.translate(text, to: "th")
            subtitle.show(thai, on: region.screen)
        } catch {
            subtitle.show("ผิดพลาด: \(error.localizedDescription)", on: region.screen, hideAfter: 4)
        }
    }
}
