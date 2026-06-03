import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // This app is a background-only container for the Quick Look extension.
        // It has no UI; quit immediately after launch.
        NSApp.terminate(nil)
    }
}
