+++
title = "Update application code"
chapter = false
weight = 30
+++

Now that we have a GraphQL API to support access our data model from the cloud, let's modify the application code to call the GraphQL endpoint instead of listing hard coded values.

At high level, here is how we gonna proceed

- first, we're going [to add](#add-the-aws-appsync-client-library) the `pod` dependency to access the Amplify API client library

- then we will add the [app sync client code](#add-client-code-in-the-application-delegate) in `AppDelegate` class, as we did for authentication.

- `UserData` class holds a hard code reference to the list of Landmarks loaded at application startup time.  [We are going to replace with an empty list](#modify-userdata-class) (`[]`) and we're going to add code to query the API and populate the list after sucesfull sign in.

## Add the AWS AppSync client library

Edit `$PROJECT_DIRECTORY/Podfile` to add the AppSync dependency.  Your `Podfile` must look like this (you can safely copy/paste the entire file from below):

{{< highlight bash "hl_lines=13">}}
cd $PROJECT_DIRECTORY
echo "platform :ios, '13.0'

target 'Landmarks' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Landmarks
  pod 'Amplify', '~> 1.0'                             # required amplify dependency
  pod 'Amplify/Tools', '~> 1.0'                       # allows to cal amplify CLI from within XCode

  pod 'AmplifyPlugins/AWSCognitoAuthPlugin', '~> 1.0' # support for Cognito user authentication
  pod 'AmplifyPlugins/AWSAPIPlugin', '~> 1.0'         # support for GraphQL API

end" > Podfile
{{< /highlight >}}

In a Terminal, type the following commands to download and install the dependencies:

```bash
cd $PROJECT_DIRECTORY
pod install --repo-update
```

After one minute, you shoud see the below:

![Pod update](/images/40-30-appsync-code-1.png)

## Modify UserData class

`UserData` holds a hard coded list of landmarks, loaded from a JSON files (*Landmarks/Resources/landmarkData.json*).  The `Landmarks/Models/Data.swift` class loads the JSON file at application startup time using this line:

```swift
let landmarkData: [Landmark] = load("landmarkData.json")
```

Let's replace `UserData.swift` with the below 

{{< highlight swift "hl_lines=13" >}}
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model object that stores app data.
*/

import Combine
import SwiftUI

final class UserData: ObservableObject {
    @Published var showFavoritesOnly = false
    @Published var landmarks : [Landmark] = []
    @Published var isSignedIn : Bool = false
}
{{< /highlight >}}

On line 13, we initialise the list of landmarks with an empty array, while preserving the type of the variable.

## Generate code and add it to the XCode project 

Thanks to the strongly typed nature of GraphQL, Amplify generates Swift code to access the data types, the queries and the mutations of the API. 

In a Terminal, type the following commands to generate Swift code based on your GraphQL model:

```bash
cd $PROJECT_DIRECTORY
amplify codegen models
```

Wait for the generation to complete and check there is no error.

![amplify codegen](/images/40-30-amplify-codegen-1.png)

Add the generated files in your project.  In the Finder, locate 5 files in *amplify/generated/models* and drag them into your XCode project.

![amplify codegen files](/images/40-30-amplify-codegen-2.png)

When the *Options* dialog box appears, do the following:

- Clear the **Copy items if needed** check box.
- Choose **Create groups**, and then choose **Finish**.

![add amplify codegen files](/images/40-30-amplify-codegen-3.png)

## Add client code in the application delegate 

We modify `AppDelegate.swift` to add code to call the GraphQL API.  You can safely copy/paste the entire file from below. 

{{< highlight swift "hl_lines=23-23 98-101 151-177" >}}
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
      
    // MARK: Amplify - Authentication

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
}    
{{< /highlight >}}

What we did change ?

- line 22 : add the API Amplify plugin.

- line 98-100 : when authentication status changes to 'signed in' and no landmark data is loaded, trigger the API call.

- line 152 : we added `func queryLandmarks()` to call the API.  This function uses the generated code to pass arguments to the API Query method.  `Amplify.API.query` is asynchronous and returns immediately.   We pass a callback inline function `(event) in ...` to be notified when the data are available.  When data are available, the code transforms the JSON object received in `Landmark` object (as defined in `Landmarks/Models/Landmark.swift`).  Newly created objects are added to the array of Landmarks in `UserData` with this line of code `self.userData.landmarks.append(l)`.

To allow the creation of the application `Landmark` model object from the API `LandmarkData` generated code, we add the following code to `Landmarks/Models/Landmark.swift`

Open `Landmarks/Models/Landmark.swift` and copy/paste the code below.

{{< highlight swift "hl_lines=52-68" >}}
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The model for an individual landmark.
*/

import SwiftUI
import CoreLocation

struct Landmark: Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    fileprivate var imageName: String
    fileprivate var coordinates: Coordinates
    var state: String
    var park: String
    var category: Category
    var isFavorite: Bool

    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude)
    }

    enum Category: String, CaseIterable, Codable, Hashable {
        case featured = "Featured"
        case lakes = "Lakes"
        case rivers = "Rivers"
        case mountains = "Mountains"
    }
}

extension Landmark {
    var image: Image {
        ImageStore.shared.image(name: imageName)
    }
}

struct Coordinates: Hashable, Codable {
    var latitude: Double
    var longitude: Double
}

// assume all fields are non null.
// real life project must spend more time thinking about null values and
// maybe convert the above code (original Landmark class) to optionals
// I am not doing it for this workshop as this would imply too many changes in UI code
// MARK: - TODO

extension Landmark {
    init(from : LandmarkData) {
        
        guard let i = Int(from.id) else {
            preconditionFailure("Can not create Landmark, Invalid ID : \(from.id) (expected Int)")
        }
        
        id = i
        name = from.name
        imageName = from.imageName!
        coordinates = Coordinates(latitude: from.coordinates!.latitude!, longitude: from.coordinates!.longitude!)
        state = from.state!
        park = from.park!
        category = Category(rawValue: from.category!)!
        isFavorite = from.isFavorite!

    }
}
{{< /highlight >}}

What did we change ?

- line 52: we created an extension to the provided `Landmark` data object, allowing to initialize an instance of it from a `LandmarkData` object returned by the API.

The list of all changes we made to the code is visible in [this commit](https://github.com/sebsto/amplify-ios-workshop/commit/ad92eada6607a76236f3b9597f4ac867399e20cf).

## Launch the app

Build and launch the application to verify everything is working as expected. Click the **build** icon <i class="far fa-caret-square-right"></i> or press **&#8984;R**.
![build](/images/20-10-xcode.png)

After a few seconds, you should see the application running in the iOS simulator.
![run](/images/40-30-appsync-code-2.png)

{{% notice tip %}}
If you did not sign out last time you started the application, you are still signed in.  This is expected as the Amplify` library stores the token locally and automatically refresh the token when it expires.
{{% /notice %}}

At this stage, we have hybrid data sources.  The Landmark list is loaded from the GraphQL API, but the images are still loaded from the local bundle.  In the next section, we are going to move the images to Amazon S3.
