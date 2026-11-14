import Carbon
import AppKit

// Global hot keys that work without the Accessibility permission (Carbon RegisterEventHotKey).
enum HotKey {
    static var handlers: [UInt32: () -> Void] = [:]
    static var installed = false
    static var refs: [EventHotKeyRef?] = []

    static func register(keyCode: UInt32, modifiers: UInt32, id: UInt32, action: @escaping () -> Void) {
        handlers[id] = action
        if !installed {
            installed = true
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
                var hk = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                  nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
                let action = HotKey.handlers[hk.id]
                DispatchQueue.main.async { action?() }
                return noErr
            }, 1, &spec, nil, nil)
        }
        var ref: EventHotKeyRef?
        let hkID = EventHotKeyID(signature: OSType(0x534F4D54), id: id)   // "SOMT"
        RegisterEventHotKey(keyCode, modifiers, hkID, GetApplicationEventTarget(), 0, &ref)
        refs.append(ref)
    }
}
