import Foundation
import FirebaseCore
import FirebaseFirestore
import SQLite

func runBubblService() {
    logInfo(.general, "Starting Bubbl Chatbot…")
    logInfo(.general, "CWD: \(FileManager.default.currentDirectoryPath)")

    func findPlist() -> String? {
        [
            Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            Bundle.main.bundleURL.appendingPathComponent("GoogleService-Info.plist").path,
            "/Applications/Bubbl/GoogleService-Info.plist"
        ]
        .compactMap { $0 }
        .first { FileManager.default.fileExists(atPath: $0) }
    }

    do {
        let env = ProcessInfo.processInfo.environment
        let opts = FirebaseOptions(
            googleAppID: env["FIREBASE_APP_ID"] ?? "",
            gcmSenderID: env["FIREBASE_SENDER_ID"] ?? ""
        )
        opts.projectID     = env["FIREBASE_PROJECT_ID"]     ?? ""
        opts.apiKey        = env["FIREBASE_API_KEY"]        ?? ""
        opts.databaseURL   = env["FIREBASE_DATABASE_URL"]   ?? ""
        opts.storageBucket = env["FIREBASE_STORAGE_BUCKET"] ?? ""

        if !opts.googleAppID.isEmpty {
            FirebaseApp.configure(options: opts)
        }
        else if let p = findPlist(),
                let fileOpts = FirebaseOptions(contentsOfFile: p) {
            FirebaseApp.configure(options: fileOpts)
        }
        else {
            FirebaseApp.configure()
        }
        logInfo(.firebase, "Firebase configured")
    }
    catch {
        logError(.firebase, "Firebase config failed", error: error)
    }

    let ok = FirebaseApp.app() != nil
    logInfo(.firebase, "Firebase status: \(ok)")

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