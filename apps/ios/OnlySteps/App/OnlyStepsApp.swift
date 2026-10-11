import SwiftUI
import UIKit

@main
struct OnlyStepsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .tint(OSColor.primary)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // HealthKit background delivery relaunches the app in the background;
        // the observer query must be registered again on every launch.
        Task { await StepSync.shared.startObservingIfAuthorized() }
        return true
    }
}
