import Foundation
import FirebaseCore
import FirebaseFirestore
import SQLite

public func runBubblService() {
    logInfo(.general, "Starting Bubbl Chatbot…")
    logInfo(.general, "CWD: \(FileManager.default.currentDirectoryPath)")

    func findGoogleServiceInfoPlist() -> String? {
        if let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") {
            return url.path
        }
        let extras = [
            "/Applications/Bubbl/GoogleService-Info.plist",
            "./GoogleService-Info/GoogleService-Info.plist",
            "GoogleService-Info.plist",
            "../GoogleService-Info.plist"
        ]
        return extras.first { FileManager.default.fileExists(atPath: $0) }
    }

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
            logInfo(.firebase, "Loading plist from: \(plist)")
            if let fileOpts = FirebaseOptions(contentsOfFile: plist) {
                FirebaseApp.configure(options: fileOpts)
            } else {
                logWarning(.firebase, "Bad plist; using default configure()")
                FirebaseApp.configure()
            }
        }
        else {
            logWarning(.firebase, "No config found; defaulting")
            FirebaseApp.configure()
        }
        logInfo(.firebase, "Firebase configured")
    } catch {
        logError(.firebase, "Firebase config failed", error: error)
    }

    let ok = FirebaseApp.app() != nil
    logInfo(.firebase, "Firebase status: \(ok ? "OK" : "Not configured")")

    checkMessagesConnection()
    if ok {
        monitorMessages()
        processMessageQueueLoop()
        monitorGroupChanges()
    } else {
        monitorMessages()
    }

    RunLoop.main.run()
}