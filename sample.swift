import Cocoa
import FirebaseCore
import FirebaseFirestore
import SQLite

fileprivate func findGoogleServiceInfoPlist() -> String? {
    let possiblePaths = [
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
        "GoogleService-Info.plist",
        "../GoogleService-Info.plist",
        "/Applications/Bubbl/GoogleService-Info/GoogleService-Info.plist",
        "/Applications/Bubbl/GoogleService-Info.plist",
        "./GoogleService-Info/GoogleService-Info.plist"
        Bundle.main.bundleURL.appendingPathComponent("GoogleService-Info.plist").path
    ].compactMap { $0 }
    
    for path in possiblePaths {
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
    }
    return nil
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        DispatchQueue.global(qos: .background).async {
            self.startBubblService()
        }
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "Bubbl")
            btn.action = #selector(showMenu(_:))
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Bubbl is running", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Bubbl", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc private func showMenu(_ sender: Any?) {
        statusItem.popUpMenu(statusItem.menu!)
    }

    private func startBubblService() {
        logInfo(.general, "Starting Bubbl Chatbot (app bundle)…")

        do {
            let env = ProcessInfo.processInfo.environment
            let opts = FirebaseOptions(
                googleAppID: env["FIREBASE_APP_ID"] ?? "",
                gcmSenderID: env["FIREBASE_SENDER_ID"] ?? ""
            )
            opts.projectID     = env["FIREBASE_PROJECT_ID"] ?? ""
            opts.apiKey        = env["FIREBASE_API_KEY"] ?? ""
            opts.databaseURL   = env["FIREBASE_DATABASE_URL"] ?? ""
            opts.storageBucket = env["FIREBASE_STORAGE_BUCKET"] ?? ""

            if !opts.googleAppID.isEmpty {
                logInfo(.firebase, "Configuring Firebase from ENV")
                FirebaseApp.configure(options: opts)
            }
            else if let plist = findGoogleServiceInfoPlist() {
                logInfo(.firebase, "Loading Firebase plist at \(plist)")
                if let fileOpts = FirebaseOptions(contentsOfFile: plist) {
                    FirebaseApp.configure(options: fileOpts)
                } else {
                    logWarning(.firebase, "Invalid plist; using default configure()")
                    FirebaseApp.configure()
                }
            }
            else {
                logWarning(.firebase, "No Firebase config found; using default")
                FirebaseApp.configure()
            }
            logInfo(.firebase, "Firebase configured")
        }
        catch {
            logError(.firebase, "Firebase configuration failed", error: error)
        }

        let firebaseOK = FirebaseApp.app() != nil
        logInfo(.firebase, "Firebase status: \(firebaseOK ? "OK" : "Not configured")")
        checkMessagesConnection()

        if firebaseOK {
            monitorMessages()
            processMessageQueueLoop()
            monitorGroupChanges()
        } else {
            monitorMessages()
        }

        logInfo(.general, "Entering run loop")
        RunLoop.main.run()
    }
}