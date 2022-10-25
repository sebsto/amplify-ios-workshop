---
title : "Bring your own UI"
chapter : false
weight : 30
---

Amazon Cognito provides low level API allowing you to implement your custom authentication flows, when needed.  It allows to build your own Signin, Signup, Forgot Password Views or to build your own flows.  Check the available APIs in the [Amplify documentation](https://docs.amplify.aws/lib/auth/signin/q/platform/ios).

In this section, we are going to implement our own Login user interface (a custom SwiftUI View) and interact with the `Amplify.Auth.signIn()` API instead of using the Cognito hosted UI.

## Add API based signin in Application Delegate

We start by adding a new method in the Application Delegate to sign in through the API instead of using the hosted UI.

Add the `signIn()` function in file *Landmarks/AppDelegate.swift* (you can safely copy/paste the whole file below, modified lines are explained right after the code snipet):

```swift { hl_lines=["138-151"]}
import SwiftUI
import ClientRuntime
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import AWSS3StoragePlugin

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    
    // https://stackoverflow.com/questions/66156857/swiftui-2-accessing-appdelegate
    static private(set) var instance: AppDelegate! = nil
    
    public let userData = UserData()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.instance = self
        
        do {
            // reduce verbosity of AWS SDK
            SDKLoggingSystem.initialize(logLevel: .warning)
            
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSS3StoragePlugin())

            try Amplify.configure()
            print("Amplify initialized")
            
            // asynchronously 
            Task {
                
                // check if user is already signed in from a previous run
                let session = try await Amplify.Auth.fetchAuthSession()
                
                // and update the GUI accordingly
                await self.updateUI(forSignInStatus: session.isSignedIn)
            }
            
            // listen to auth events.
            // see https://github.com/aws-amplify/amplify-ios/blob/dev-preview/Amplify/Categories/Auth/Models/AuthEventName.swift
            let _  = Amplify.Hub.listen(to: .auth) { payload in
                switch payload.eventName {
                    
                case HubPayload.EventName.Auth.signedIn:
                    
                    Task {
                        print("==HUB== User signed In, update UI")
                        await self.updateUI(forSignInStatus: true)
                    }
                    
                    // if you want to get user attributes
                    Task {
                        let authUserAttributes = try? await Amplify.Auth.fetchUserAttributes()
                        if let authUserAttributes {
                            print("User attribtues - \(authUserAttributes)")
                        } else {
                            print("Failed fetching user attributes failed")
                        }
                    }
                    
                case HubPayload.EventName.Auth.signedOut:
                    Task {
                        print("==HUB== User signed Out, update UI")
                        await self.updateUI(forSignInStatus: false)
                    }
                    
                case HubPayload.EventName.Auth.sessionExpired:
                    Task {
                        print("==HUB== Session expired, show sign in aui")
                        await self.updateUI(forSignInStatus: false)
                    }
                    
                default:
                    //print("==HUB== \(payload)")
                    break
                }
            }
            
        } catch let error as AuthError {
            print("Authentication error : \(error)")
        } catch {
            print("Error when configuring Amplify \(error)")
        }
        return true
    }
}

// MARK: -- Authentication code
extension AppDelegate {
    
    // change our internal state, this triggers an UI update on the main thread
    @MainActor
    func updateUI(forSignInStatus : Bool) async {
        self.userData.isSignedIn = forSignInStatus
        
        // load landmarks at start of app when user signed in
        if (forSignInStatus && self.userData.landmarks.isEmpty) {
            self.userData.landmarks = await self.queryLandmarks()
        } else {
            self.userData.landmarks = []
        }
    }
    
    // signin with Cognito web user interface
    public func authenticateWithHostedUI() async throws {
        
        print("hostedUI()")
        
        // UIApplication.shared.windows.first is deprecated on iOS 15
        // solution from https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0/57899013
        
        let w = UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        
        let result = try await Amplify.Auth.signInWithWebUI(presentationAnchor: w!)
        if (result.isSignedIn) {
            print("Sign in succeeded")
        } else {
            print("Signin failed or required a next step")
        }
    }
    
    // signout globally
    public func signOut() async throws {
        
        // https://docs.amplify.aws/lib/auth/signOut/q/platform/ios
        let options = AuthSignOutRequest.Options(globalSignOut: true)
        let _ = await Amplify.Auth.signOut(options: options)
        print("Signed Out")
    }
}

// MARK: CUSTOM AUTHENTICATION
extension AppDelegate {
    public func signIn(username: String, password: String) async {
        
        do {
            let _ = try await Amplify.Auth.signIn(username: username, password: password)
            print("Sign in succeeded")
            // nothing else required, the event HUB will trigger the UI refresh
        } catch {
            print("Sign in failed \(error)")
            // in real life present a message to the user
        }
    }
}

// MARK: API Access
extension AppDelegate {
    
    func queryLandmarks() async -> [ Landmark ] {
        print("Query landmarks")
        
        do {
            let queryResult = try await Amplify.API.query(request: .list(LandmarkData.self))
            print("Successfully retrieved list of landmarks")
            
            // convert [ LandmarkData ] to [ LandMark ]
            let result = try queryResult.get().map { landmarkData in
                Landmark.init(from: landmarkData)
            }
            
            return result
            
        } catch let error as APIError {
            print("Failed to load data from api : \(error)")
        } catch {
            print("Unexpected error while calling API : \(error)")
        }
        
        return []
    }
}

// MARK: AWS S3 & Image Loading
extension AppDelegate {

    func downloadImage(_ name: String) async -> Data {
                
        print("Downloading image : \(name)")
        
        do {
            
            let task = try await Amplify.Storage.downloadData(key: "\(name).jpg")
            let data = try await task.value
            print("Image \(name) downloaded")
            
            return data
            
        } catch let error as StorageError {
            print("Can not download image \(name): \(error.errorDescription). \(error.recoverySuggestion)")
        } catch {
            print("Unknown error when loading image \(name): \(error)")
        }
        return Data() // could return a default image
    }
}
```

What did we change?

- line 138 - 151 : we add code to call Cognito's `signIn(username, password)` API. This APi call is synchronous because of the `await` keyword.

## Add a Custom Login Screen

We implement our own custom login screen as a View.  To add a new Swift class to your project, use Xcode menu and click **File**, then **New** or press **&#8984;N** and then enter the file name : *CustomLoginView.swift*:

Copy / paste the code from below:

```swift 
import SwiftUI
import Combine

//
// this is a custom view to capture username and password
//
struct CustomLoginView : View {
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    @EnvironmentObject private var appDelegate: AppDelegate

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

            Button(action: {
                Task {
                    await self.appDelegate.signIn(username: self.username, password: self.password)
                }
            }) {
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
            .animation(.easeOut, value: 0.5)
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
```

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

```swift 
//
//  LandingView.swift
//  Landmarks

// Landmarks/LandingView.swift

import SwiftUI

struct LandingView: View {
    @ObservedObject public var user : UserData
    @EnvironmentObject private var appDelegate: AppDelegate
    
    var body: some View {
        
        return VStack {
            // .wrappedValue is used to extract the Bool from Binding<Bool> type
            if (!$user.isSignedIn.wrappedValue) {

//                Button(action: {
//
//                    Task {
//                        try await appDelegate.authenticateWithHostedUI()
//                    }
//
//                }) {
//                        UserBadge().scaleEffect(0.5)
//                    }
                CustomLoginView()
                
            } else {
                LandmarkList().environmentObject(user)
            }
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        let userDataSignedIn = UserData()
        userDataSignedIn.isSignedIn = true
        let userDataSignedOff = UserData()
        userDataSignedOff.isSignedIn = false
        return Group {
            LandingView(user: userDataSignedOff)
            LandingView(user: userDataSignedIn)
        }
    }
}
```

<!-- You can view the whole code changes for this section [from this commit](https://github.com/sebsto/amplify-ios-workshop/commit/bb8c87d359c8970ff10d5e06cc49786ee5965e4f). -->

## Build and Test 

Build and launch the application to verify everything is working as expected. Click the **build** icon <i class="far fa-caret-square-right"></i> or press **&#8984;R**.
![build](/images/20-20-xcode.png)

If you are still authenticated, click **Sign Out** and click the user badge to sign in again. You should see this:

![customized drop in UI](/images/70-30-1.png)

Enter the username and password that you created in section 3 and try to authenticate.  After a second or two, you will see the Landmark list.

{{% notice info %}}
Implementing Social Signin with a Custom View requires a bit more work on your side. When the Social Provider authentication flow completes, the Social Identity provider issues a redirect to your app.  So far, the redirection was made to Amazon Cognito hosted UI and Cognito implemented the token exchange. When using a Custom View, you need to handle these details in your code.  The easiest is probably to use the Social Provider platform specific SDK (the [Authentication Service](https://developer.apple.com/documentation/authenticationservices) framework in the case of Sign in with Apple) and use the [Cognito SDK](https://docs.amplify.aws/sdk/auth/federated-identities/q/platform/ios) `federatedSignIn()` method. I am proposing this as an exercise for the more advanced readers.
{{% /notice %}}