+++
title = "Bring your own UI"
chapter = false
weight = 30
+++

Amazon Cognito provides low level API allowing you to implement your custom authentication flows, when needed.  It allows to build your own Signin, Signup, Forgot Password Views or to build your own flows.  Check the available APIs in the [Amplify documentation](https://docs.amplify.aws/lib/auth/signin/q/platform/ios).

In this section, we are going to implement our own Login user interface (a custom SwiftUI View) and interact with the `Amplify.Auth.signIn()` API instead of using the Cognito hosted UI.

## Add API based signin in Application Delegate

We start by adding a new method in the Application Delegate to sign in through the API instead of using the hosted UI.

Add the `signIn()` function in file *Landmarks/AppDelegate.swift* (you can safely copy/paste the whole file below, modified lines are highlighted):

{{< highlight swift "hl_lines=122-133">}}
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
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSS3StoragePlugin())

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
            
            // only load landmarks at start of app, when user signed in
            if (forSignInStatus && self.userData.landmarks.isEmpty) {
                self.queryLandmarks()
            }
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
    
    public func signIn(username: String, password: String) {
        _ = Amplify.Auth.signIn(username: username, password: password) { result in
            switch result {
            case .success(_):
                print("Sign in succeeded")
                // nothing else required, the event HUB will trigger the UI refresh
            case .failure(let error):
                print("Sign in failed \(error)")
                // in real life present a message to the user
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
    
    // MARK: API Access
    
    func queryLandmarks() {
        print("Query landmarks")
        
        _ = Amplify.API.query(request: .list(LandmarkData.self)) { event in
            switch event {
            case .success(let result):
                print("Landmarks query complete.")
                switch result {
                case .success(let landmarksData):
                    print("Successfully retrieved list of landmarks")
                    for f in landmarksData {
                        let landmark = Landmark.init(from: f)
                        DispatchQueue.main.async() {
                            self.userData.landmarks.append(landmark);
                        }
                    }
                    
                case .failure(let error):
                    print("Can not retrieve result : error  \(error.errorDescription)")
                }
            case .failure(let error):
                print("Can not retrieve landmarks : error \(error)")
            }
        }
    }
    
    // MARK: AWS S3 & Image Loading

    func image(_ name: String, callback: @escaping (Data) -> Void ) {
        
        print("Downloading image : \(name)")

        _ = Amplify.Storage.downloadData(key: "\(name).jpg",
            progressListener: { progress in
                // in case you want to monitor progress
//                    print("Progress: \(progress)")
            }, resultListener: { (event) in
                switch event {
                case let .success(data):
                    print("Image \(name) loaded")
                    callback(data)
                case let .failure(storageError):
                    print("Can not download image: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                }
            }
        )
    }
}
{{< /highlight >}}

## Add a Custom Login Screen

We implement our own custom login screen as a View.  To add a new Swift class to your project, use Xcode menu and click **File**, then **New** or press **&#8984;N** and then enter the file name : *CustomLoginView.swift*:

Copy / paste the code from below:

{{< highlight swift >}}
import SwiftUI
import Combine

//
// this is a custom view to capture username and password
//
struct CustomLoginView : View {
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    private let app = UIApplication.shared.delegate as! AppDelegate

    var body: some View { // The body of the screen view
        VStack {
            Image("turtlerock")
            .resizable()
            .aspectRatio(contentMode: ContentMode.fit)
            .padding(Edge.Set.bottom, 20)
            
            Text(verbatim: "Login").bold().font(.title)
            
            Text(verbatim: "Explore Landmarks of the world")
            .font(.subheadline)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 70, trailing: 0))
                                
            TextField("Username", text: $username)
            .autocapitalization(.none) //avoid autocapitalization of the first letter
            .padding()
            .cornerRadius(4.0)
            .background(Color(UIColor.systemFill))
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0))
            
            SecureField("Password", text: $password)
            .padding()
            .cornerRadius(4.0)
            .background(Color(UIColor.systemFill))
            .padding(.bottom, 10)

            Button(action: { self.app.signIn(username: self.username, password: self.password) }) {
                HStack() {
                    Spacer()
                    Text("Signin")
                        .foregroundColor(Color.white)
                        .bold()
                    Spacer()
                }
                                
            }.padding().background(Color.green).cornerRadius(4.0)
        }.padding()
        .keyboardAdaptive() // Apply the scroll on keyboard height
    }
}


// The code below
// scrolls the view when the keyboard appears
// thanks to https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(Publishers.keyboardHeight) { self.keyboardHeight = $0 }
            .animation(.easeOut(duration: 0.5))
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAdaptive())
    }
}

extension Publishers {
    // 1.
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        // 2.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        // 3.
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
static var previews: some View {
        CustomLoginView() // Renders your UI View on the Xcode preview
    }
}
#endif
{{< /highlight >}}

The code is straigthforward:

- the UI is structured around a vertical stack.  It has an Image, a title and subtitle.  There are two `TextField` controls allowing users to enter their username and password.  These text fields are bound to corresponding private variables.  At the bottom of the stack, there is a Login button.

- the Login button as an `action` code block.  The code calls the `AppDelegate.signIn()` function we added in the previous step.

- the last part of the code is shamelessy [copied from a blog post I found](https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/). It allows to scroll the View up when the keyboard appears.

The last step consists of using this `CustomLoginView` instead of the the hosted UI.

## Update LandingView 

The `LandingView` is the view displayed when the application starts.  It routes toward a login screen or the Landmark list based on user signin attribute.  

We update `LandingView` to make use of `CustomLoginView` with this code update:

```swift
// .wrappedValue is used to extract the Bool from Binding<Bool> type
if (!$user.isSignedIn.wrappedValue) {
    CustomLoginView()
} else {
    LandmarkList().environmentObject(user)
}
```

This code is making the `LandingView` code simpler.  It displays `CustomLoginView` when user is not signed in, or `LandmarkList` otherwise.  You can safely copy/paste the full code below to replace the content of *Landmarks/LandingView.swift*:

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
                
//                Button(action: {
//                            let app = UIApplication.shared.delegate as! AppDelegate
//                            app.authenticateWithHostedUI()
//                        }) {
//                    UserBadge().scaleEffect(0.5)
//                }
                CustomLoginView()
                
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

You can view the whole code changes for this section [from this commit]() TODO.

## Build and Test 

Build and launch the application to verify everything is working as expected. Click the **build** icon <i class="far fa-caret-square-right"></i> or press **&#8984;R**.
![build](/images/20-10-xcode.png)

If you are still authenticated, click **Sign Out** and click the user badge to sign in again. You should see this:

![customized drop in UI](/images/70-30-1.png)

Enter the username and password that you created in section 3 and try to authenticate.  After a second or two, you will see the Landmark list.

{{% notice info %}}
Implementing Social Signin with a Custom View requires a bit more work on your side. When the Social Provider authentication flow completes, the Social Identity provider issues a redirect to your app.  So far, the redirection was made to Amazon Cognito hosted UI and Cognito implemented the token exchange. When using a Custom View, you need to handle these details in your code.  The easiest is probably to use the Social Provider platform specific SDK (here is [the one for Facebook](https://developers.facebook.com/docs/facebook-login/ios)) and use the [Cognito SDK](https://docs.amplify.aws/sdk/auth/federated-identities/q/platform/ios) `federatedSignIn()` method. I am proposing this as an exercise for the most advanced readers.
{{% /notice %}}