+++
title = "Update application code"
chapter = false
weight = 20
+++

Now that the cloud-based backend is ready, let's modify the application code to add an authentication screen.  We're going to make several changes in the application:

- add AWS Amplify [dependencies](#add-the-amplify-library-to-the-ios-project) to the project 
- add [the code](#add-authentication-code) to trigger the authentication UI and monitor the state of sessions
- add a [Landing view](#add-a-landing-view) to route users to the non-authenticated and authenticated views

The view navigation will look like this:

{{<mermaid align="left">}}
graph LR;
    A(SceneDelegate) -->|entry point| B(LandingView)
    B --> C{is user<br/>authenticated?}
    C -->|no| D(LoginView)
    C -->|Yes| E(LandmarkList)
{{< /mermaid >}}

We choose to write all AWS specific code in the `AppDelegate` class, to avoid spreading dependencies all over the project. This is a design decision for this project, you may adopt other design for your projects.

## Add the AWS Authentication client library

Edit `$PROJECT_DIRECTORY/Podfile` to add the Amplify Authentication dependency.  Your `Podfile` must look like this (you can safely copy/paste the entire file from below):

{{< highlight bash "hl_lines=11 ">}}
cd $PROJECT_DIRECTORY
echo "platform :ios, '13.0'

target 'Landmarks' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Landmarks
  pod 'Amplify', '~> 1.0.1'                             # required amplify dependency
  pod 'Amplify/Tools', '~> 1.0.1'                       # allows to cal amplify CLI from within Xcode
  pod 'AmplifyPlugins/AWSCognitoAuthPlugin', '~> 1.0.1' # support for Cognito user authentication
  
end" > Podfile
{{< /highlight >}}

In a Terminal, type the following commands to download and install the dependencies:

```bash
cd $PROJECT_DIRECTORY
pod install --repo-update
```

After one minute, you shoud see the below:

![Pod update](/images/30-20-pod-install-1.png)

## Add authentication code

Let's start to add a flag in the `UserData` class to keep track of authentication status. Highlighted lines show the update.  You can copy/paste the whole content to replace *Landmarks/Models/UserData.swift* :

{{< highlight swift "hl_lines=8-8 10">}}
// Landmarks/Models/UserData.swift
import Combine
import SwiftUI

final class UserData: ObservableObject {
    @Published var showFavoritesOnly = false
    @Published var landmarks = landmarkData
    @Published var isSignedIn : Bool = false
}
{{< /highlight >}}

Add user authentication logic to *Landmarks/AppDelegate.swift*:

{{< highlight swift "hl_lines=9-10 15-15 19-67 89-142" >}}
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import Amplify
import AmplifyPlugins

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    public let userData = UserData()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        do {
            Amplify.Logging.logLevel = .info
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            
            try Amplify.configure()
            print("Amplify initialized")
            
            // load data when user is signedin
            self.checkUserSignedIn()

            // listen to auth events.
            // see https://github.com/aws-amplify/amplify-ios/blob/master/Amplify/Categories/Auth/Models/AuthEventName.swift
            _ = Amplify.Hub.listen(to: .auth) { (payload) in

                switch payload.eventName {

                case HubPayload.EventName.Auth.signedIn:
                    print("==HUB== User signed In, update UI")

                    self.updateUI(forSignInStatus: true)

                    // if you want to get user attributes
                    _ = Amplify.Auth.fetchUserAttributes() { (result) in
                        switch result {
                        case .success(let attributes):
                            print("User attribtues - \(attributes)")
                        case .failure(let error):
                            print("Fetching user attributes failed with error \(error)")
                        }
                    }


                case HubPayload.EventName.Auth.signedOut:
                    print("==HUB== User signed Out, update UI")
                    self.updateUI(forSignInStatus: false)
                    
                case HubPayload.EventName.Auth.sessionExpired:
                    print("==HUB== Session expired, show sign in aui")
                    self.updateUI(forSignInStatus: false)

                default:
                    //print("==HUB== \(payload)")
                    break
                }
            }

        } catch {
            print("Failed to configure Amplify \(error)")
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: -- Authentication code
    
    // change our internal state, this triggers an UI update on the main thread
    func updateUI(forSignInStatus : Bool) {
        DispatchQueue.main.async() {
            self.userData.isSignedIn = forSignInStatus
        }
    }
    
    // when user is signed in, fetch its details
    func checkUserSignedIn() {

        // every time auth status changes, let's check if user is signedIn or not
        // updating userData will automatically update the UI
        _ = Amplify.Auth.fetchAuthSession { (result) in

            do {
                let session = try result.get()
                self.updateUI(forSignInStatus: session.isSignedIn)
            } catch {
                print("Fetch auth session failed with error - \(error)")
            }

        }
    }
    
    // signin with Cognito web user interface
    public func authenticateWithHostedUI() {

        print("hostedUI()")
        _ = Amplify.Auth.signInWithWebUI(presentationAnchor: UIApplication.shared.windows.first!) { result in
            switch result {
            case .success(_):
                print("Sign in succeeded")
            case .failure(let error):
                print("Sign in failed \(error)")
            }
        }
    }
    
    // signout globally
    public func signOut() {

        // https://docs.amplify.aws/lib/auth/signOut/q/platform/ios
        let options = AuthSignOutRequest.Options(globalSignOut: true)
        _ = Amplify.Auth.signOut(options: options) { (result) in
            switch result {
            case .success:
                print("Successfully signed out")
            case .failure(let error):
                print("Sign out failed with error \(error)")
            }
        }
    }

}
{{< /highlight >}}

What did we add ?

- line 9-10 : we import Amplify libraries

- line 15 : we move `userData` object from `SceneDelegate` to `AppDelegate` to be able to access it from anywhere in the app (we'll delete it from `SceneDelegate` in a minute)

- line 20-24 : we initialize Amplify

- line 31-63 :  we add an `Amplify.Hub.listen(to: .auth)` switch statement to listen for changes in authentication status. That code calls `self.updateUI()` to update the `isSignedIn` flag inside the `userData` object.  SwiftUI will automatically trigger a user interface refresh when the state of this object changes.  You can learn more about SwiftUI binding in [the SwiftUI documentation](https://developer.apple.com/documentation/swiftui/state_and_data_flow).

- line 116 : we add an `authenticateWithHostedUI()` method to trigger the UI flow using Cognito's [hosted web user interface](https://aws.amazon.com/premiumsupport/knowledge-center/cognito-hosted-web-ui/).

- line 130 : we add a `signOut()` method to sign the user out.

Before proceeding to the next steps, **build** (&#8984;B) the project to ensure there is no compilation error.

## Route authenticated and non-authenticated views

In this section, we're going to add a new application entry point: the LandingView.  This view will check if the user is authenticated and will display either the authentication view or the main application view.

Let's create two new Swift classes in `$PROJECT_DIRECTORY/Landmarks` (same directory as `AppDelegate.swift` or `LandmarkList.swift`)

- **UserBadge.swift** is the view to use when user is not authenticated
- **LandingView.swift** is the application entry point.  It displays either `UserBadge` or `LandmarkList` based on user's authentication status.

To add a new Swift class to your project, use Xcode menu and click **File**, then **New** or press **&#8984;N** and then enter the file name.

![add classes to xcode](/images/30-20-xcode-add-class.gif)

### UserBadge.swift 

The user badge is a very simple graphical view representing a big login button.

{{< highlight swift >}}
//
//  UserBadge.swift
//  Landmarks

import SwiftUI

struct UserBadge: View {
    var body: some View {
        GeometryReader { geometry in
        ZStack {
            Circle().stroke(Color.blue, lineWidth: geometry.size.width/50.0)

            VStack {
                Circle()
                    .frame(width:geometry.size.width / 2.0, height:geometry.size.width / 2.0, alignment: .center)
                    .foregroundColor(.blue)
                    .offset(x:0, y:geometry.size.width/3.3)

                Circle()
                    .frame(width:geometry.size.width, height:geometry.size.width, alignment: .center)
                    .foregroundColor(.blue)
                    .offset(x:0, y:geometry.size.width/3.0)

                
            }
        }
        .clipShape(Circle())
        .shadow(radius: geometry.size.width/30.0)
        }
    }
}

struct UserBadge_Previews: PreviewProvider {
    static var previews: some View {
        UserBadge()
    }
}
{{< /highlight >}}

### LandingView.swift

This `LandingView` selects the view to present based on authentication status.  When user is not authenticated, it shows the `UserBadge`.  Clicking on the `UserBadge` triggers the `authenticate()` method. When user is authenticated, it passes the user object to `LandmarkList`.

Pay attention to the `@ObservedObject` annotation.  This tells SwiftUI to invalidate and redraw the View when the state of the object changes.  When user signs in or signs out, `LandingView` will automatically adjust and render the `UserBadge` or the `LandmarkList` view.

{{< highlight swift >}}
//
//  LandingView.swift
//  Landmarks

// Landmarks/LandingView.swift

import SwiftUI

struct LandingView: View {
    @ObservedObject public var user : UserData

    var body: some View {
        
        return VStack {
            // .wrappedValue is used to extract the Bool from Binding<Bool> type
            if (!$user.isSignedIn.wrappedValue) {
                
                Button(action: {
                            let app = UIApplication.shared.delegate as! AppDelegate
                            app.authenticateWithHostedUI()
                        }) {
                    UserBadge().scaleEffect(0.5)
                }

            } else {
                LandmarkList().environmentObject(user)
            }
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        let app = UIApplication.shared.delegate as! AppDelegate
        return LandingView(user: app.userData)
    }
}
{{< /highlight >}}

### Update SceneDelegate.swift

Finally, we update `SceneDelegate.swift` to launch our new `LandingView` instead of launching `LandmarkList` when the application starts. Highlighted lines show the update.  You can copy/paste the whole content to replace *Landmarks/SceneDelegate.swift* :

{{< highlight swift "hl_lines=14-14 25-25 65" >}}
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The scene delegate.
*/

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let app = UIApplication.shared.delegate as! AppDelegate
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            
            window.rootViewController = UIHostingController(rootView: LandingView(user: app.userData))

            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

}
{{< /highlight >}}

## Add a signout button

To make our tests easier and to allow users to signout and invalidate their session, let's add a signout button on the top of the `LandmarkList` view.  Highlighted lines show the update.  You can copy/paste the whole content to replace `Landmarks/LandmarkList.swift`

{{< highlight swift "hl_lines=10-20 44-44 58" >}}
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view showing a list of landmarks.
*/

import SwiftUI

struct SignOutButton : View {
    let app = UIApplication.shared.delegate as! AppDelegate

    var body: some View {
        NavigationLink(destination: LandingView(user: app.userData)) {
            Button(action: { self.app.signOut() }) {
                Text("Sign Out")
            }
        }
    }
}

struct LandmarkList: View {
    @EnvironmentObject private var userData: UserData
    
    var body: some View {
        NavigationView {
            List {
                Toggle(isOn: $userData.showFavoritesOnly) {
                    Text("Show Favorites Only")
                }
                
                ForEach(userData.landmarks) { landmark in
                    if !self.userData.showFavoritesOnly || landmark.isFavorite {
                        NavigationLink(
                            destination: LandmarkDetail(landmark: landmark)
                                .environmentObject(self.userData)
                        ) {
                            LandmarkRow(landmark: landmark)
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Landmarks"))
            .navigationBarItems(trailing: SignOutButton())
        }
    }
}

struct LandmarksList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone SE", "iPhone XS Max"], id: \.self) { deviceName in
            LandmarkList()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
        .environmentObject(UserData())
    }
}
{{< /highlight >}}

What we did just change ?

- we created a `SignOutButton` struct that has a reference to `AppDelegate` and calls `signOut()` when pressed.  The button is just a text with a navigation link.

- we added that button as trailing item in the navigation bar.

## Configure URI for redirection after authentication

Uppon sucessful authentication, the Cognito server redirects to the URI we provided when we configured Amplify authentication in [step 3.1](/30_add_authentication/10_amplify.html#add-an-authentication-backend).  We used the `landmarks://` URI.  We need to tell iOS to launch our app when a request is made for this URI.

To do this, we add `landmarks://` to the app’s URL schemes:

1. In Xcode, right-click **Info.plist** and then choose **Open As** > **Source Code**.

1. Add the following entry in URL scheme:
{{< highlight xml "hl_lines=6-16" >}}
<plist version="1.0">

     <dict>
     <!-- YOUR OTHER PLIST ENTRIES HERE -->

     <!-- ADD AN ENTRY TO CFBundleURLTypes for Cognito Auth -->
     <!-- IF YOU DO NOT HAVE CFBundleURLTypes, YOU CAN COPY THE WHOLE BLOCK BELOW -->
     <key>CFBundleURLTypes</key>
     <array>
         <dict>
             <key>CFBundleURLSchemes</key>
             <array>
                 <string>landmarks</string>
             </array>
         </dict>
     </array>

     <!-- ... -->
     </dict>
{{< /highlight >}}

Before proceeding to the next steps, **build** (&#8984;B) the project to ensure there is no compilation error.

## Summary

The list of all changes we made to the code is visible in [this commit]() TODO.