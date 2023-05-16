---
title : "Update application code"
chapter : false
weight : 30
---

Now that we have a GraphQL API to support access our data model from the cloud, let's modify the application code to call the GraphQL endpoint instead of listing hard coded values.

At high level, here is how we gonna proceed

- First we will add the [app sync client code](#add-client-code-in-the-application-delegate) in `AppDelegate` class, as we did for authentication.

- Then we will call the API to bind data with the UI. `UserData` class holds a hard coded reference to the list of Landmarks loaded at application startup time.  [We are going to replace with an empty list](#modify-userdata-class) (`[]`) and we're going to add code to query the API and populate the list after sucesfull sign in.

## Modify UserData class

`UserData` holds a hard coded list of landmarks, loaded from a JSON file (*Landmarks/Resources/landmarkData.json*).  The `Data.swift` class loads the JSON file at application startup time using this line:

```swift 
let landmarkData: [Landmark] = load("landmarkData.json")
```

Let's modify `UserData.swift` to initialize the `landmarkData` variable with an empty array `[]` instead. Open *Landmarks/Models/UserData.swift* and copy / paste the code below.

```swift {hl_lines=[13]}
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
```

On line 13, we initialise the list of landmarks with an empty array, while preserving the type of the variable.

## Generate code and add it to the XCode project 

Thanks to the strongly typed nature of GraphQL, Amplify generates Swift code to access the data types, the queries and the mutations of the API. 

In a Terminal, type the following commands to generate Swift code based on your GraphQL model:

```bash 
cd $PROJECT_DIRECTORY
amplify codegen models
```

Wait for the generation to complete and check there is no error (the xcodeProject not found error can be ignored).

![amplify codegen](/images/40-30-amplify-codegen-1.png)

Add the generated files in your project.  In the Finder, locate 5 files in *amplify/generated/models* and drag them into your XCode project.

When the *Options* dialog box appears, do the following:

- Clear the **Copy items if needed** check box.
- Choose **Create groups**
- Be sure **Add to Target: Landmarks** is selected, and then choose **Finish**.

![amplify codegen files](/images/40-30-amplify-codegen-2.gif)

Finally, patch the generated `LandMarkData+Schema.swift` with the following line.
This is required until this [issue](https://github.com/aws-amplify/amplify-ios/issues/1443) will be fixed. You can follow progress on [this pull request](https://github.com/aws-amplify/amplify-codegen/pull/255).

In *Landmarks/Models/LandmarkData+Schema.swift*, on line 32, replace 

```swift 
model.pluralName = "LandmarkData" // BAD TO BE REMOVED
```

with 

```swift 
    model.listPluralName = "LandmarkData"
```

## Add client code in the application delegate 

We modify *Landmarks/AppDelegate.swift* to add code to call the GraphQL API.  You can safely copy/paste the entire file from below to replace the existing file. 

```swift {hl_lines=[5,23,"95-100","137-161"]}
import SwiftUI
import ClientRuntime
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin

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
```

What we did change ?

- line 5 : import the AWS API module

- line 23 : add the API Amplify plugin.

- line 95-100 : when authentication status changes to 'signed in' and no landmark data is loaded, trigger the API call.

- line 137-161 : we added `func queryLandmarks()` to call the API.  This function uses the generated code to pass arguments to the API Query method.  `Amplify.API.query` is called synchronously when using the `await` keyword. The API call returns an array of `LandmarkData` objects. The code transforms this array to an array of `Landmark` objects(as defined in `Landmarks/Models/Landmark.swift`). We use the `map` function to map one array type to another.

To allow the creation of the application `Landmark` model object from the API `LandmarkData` generated code, we add the following code to `Landmark.swift`

Open *Landmarks/Models/Landmark.swift* and copy/paste the code below.

```swift {hl_lines=["46-69"]}
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

extension Landmark {
    // construct from API Data
    init(from : LandmarkData)  {

        guard let i = Int(from.id) else {
            preconditionFailure("Can not create Landmark, Invalid ID : \(from.id) (expected Int)")
        }

        // assume all fields are non null.
        // real life project must spend more time thinking about null values and
        // maybe convert the above code (original Landmark class) to optionals
        // I am not doing it for this workshop as this would imply too many changes in UI code
        // MARK: - TODO
        
        id          = i
        name        = from.name
        imageName   = from.imageName!
        coordinates = Coordinates(latitude: from.coordinates!.latitude!, longitude: from.coordinates!.longitude!)
        state       = from.state!
        park        = from.park!
        category    = Category(rawValue: from.category!)!
        isFavorite  = from.isFavorite!
    }
}
```

What did we change ?

- line 46: we created an extension to the provided `Landmark` data object, allowing to initialize an instance of it from a `LandmarkData` object returned by the API.

<!--
The list of all changes we made to the code is visible in [this commit](https://github.com/sebsto/amplify-ios-workshop/commit/ad92eada6607a76236f3b9597f4ac867399e20cf).
-->

## Launch the app

Build and launch the application to verify everything is working as expected. Click the **build** icon <i class="far fa-caret-square-right"></i> or press **&#8984;R**.
![build](/images/20-20-xcode.png)

After a few seconds, you should see the application running in the iOS simulator.
![run](/images/40-30-appsync-code-2.png)

{{% notice tip %}}
If you did not sign out last time you started the application, you are still signed in.  This is expected as the Amplify library stores the token locally and automatically refreshes the token when it expires.
{{% /notice %}}

At this stage, we have hybrid data sources.  The Landmark list is loaded from the GraphQL API, but the images are still loaded from the local bundle.  In the next section, we are going to move the images to Amazon S3.
