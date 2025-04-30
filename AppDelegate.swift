import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        DispatchQueue.global(qos: .background).async {
            runBubblService()
        }
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: .squareLength)
        if let b = statusItem.button {
            b.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "Bubbl")
            b.action = #selector(showMenu(_:))
        }
        let m = NSMenu()
        m.addItem(NSMenuItem(title: "Bubbl is running", action: nil, keyEquivalent: ""))
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: "Quit Bubbl", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = m
    }

    @objc private func showMenu(_ sender: Any?) {
        statusItem.popUpMenu(statusItem.menu!)
    }
}