import AppKit

// Som Translate for Mac (prototype): a menu-bar app, no Dock icon.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
