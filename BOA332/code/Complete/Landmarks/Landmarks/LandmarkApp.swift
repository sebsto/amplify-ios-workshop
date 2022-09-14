import SwiftUI

@main
struct LandmarkApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            LandingView(user: appDelegate.userData)
        }
    }
}
