---
title : "Update application code"
chapter : false
weight : 20
---

Now that the storage backend is ready, let's modify the application code to load the images from Amazon S3.  We're going to make several changes in the application:

- [add the code](#add-storage-access-code-in-appdelegate) to query Amazon S3 to `AppDelegate`

- [update](#update-imagestore-class) the `ImageStore` class in the *Landmarks/Models/Data.swift* file to load the cloud images instead of the local ones.

- change [Landmarks and LandmarkRow](#update-the-landmark-landmarkrow-classes) classes to publish / observe changes on image.

{{% notice tip %}}
You can learn more about SwiftUI publish subscribe framework, called [Combine](https://developer.apple.com/documentation/combine), [in this article](https://developer.apple.com/documentation/combine/receiving_and_handling_events_with_combine).
{{% /notice %}}

## Add storage access code in AppDelegate

To add storage access code, we first add the `AWSS3StoragePlugin` to Amplify's runtime.  File upload and download capability is provided by `Amplify.Storage` class.  This class offers a high level interface to manage file uploads and downloads.  It also allows to pause and restart transfers and to monitor progress.  For this workshop, our usage will be simpler.  The code downloads a file by name. We'll wait for the download to happen with the `await` keyword. The function returns a `Data` object that we will tranform to a `Image`. We will cache the image to avoid to repeat the download operation.

As usual, you can safely copy/paste the entire `AppDelegate` from below.  Lines that have been added since last section are highlighted.

```swift {hl_lines=[6,25,"165-186"]}
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

What did we add ?

- line 6 : import the `AWSS3Storage` module

- line 25 : add code to initiliaze the storage plugin 

- line 165-186 : add a synchronous method to download files from S3.

Notice that `Amplify.Storage.downloadData()` class is synchronous when using the `await` keyword. 

## Update ImageStore class

The `ImageStore` class is part of the original code sample we started from. It is located in *Landmarks/Models/Data.swift* file.  This class takes care of caching images in memory to avoid loading them at each access. It also provider a placeholder when the image is not downloaded yet.  The placeholder is an empty white image generated with an extension of the `UIImage` class.

Open `Landmarks/Models/Data.swift` and paste the content below:

```swift {hl_lines=["39-48","52-60", "63-144"]}
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helpers for loading images and data.
*/

import UIKit
import SwiftUI
import CoreLocation

// this is just used for the previews. At runtime, data are now taken from UserData and loaded through AppDelegate
let landmarkData: [Landmark] = load("landmarkData.json")

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

// allow to create image with uniform color
// https://gist.github.com/isoiphone/031da3656d69c0d85805
extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

// Create an image from Data :
// Data -> UIImage -> Image
extension Image {
    init(fromData data:Data, scale: Int, name:String) {
        guard let uiImage = UIImage(data: data) else {
            fatalError("Couldn't convert image data \(name)")
        }
        self = Image(uiImage.cgImage!, scale: CGFloat(scale), label: Text(verbatim: name))

    }
}

// manage image cache and download
final class ImageStore {
        
    // our image cache
    private var images: [String: Image]
    private let placeholderName = "PLACEHOLDER"
    private let imageScale = 2
    
    // singleton (because of the cache)
    static var shared = ImageStore()

    init() {
        
        // initially empty cache
        images = [:]
        
        // create a place holder image
        images[self.placeholderName] = Image(uiImage: UIImage.imageWithColor(color: UIColor.lightGray, size: CGSize(width:300, height: 300)))
    }
    
    // retrieve an image.
    // first check the cache, otherwise trigger an asynchronous download and return a placeholder
    func image(name: String, landmark: Landmark) -> Image {
        var result : Image?
        
        if let img = images[name] {

            print("Image \(name) found in cache")
            // return cached image when we have it
            result = img
            
        } else {

            // trigger an asynchronous download
            // result will be store in landmark.image and that will trigger an UI refresh
            Task { await asyncDownloadImage(name, landmark) }
            
            // and return a placeholder while waiting for the result
            result = self.placeholder()

        }
        return result!
    }
    
    // asynchronously download the image
    @MainActor // to be sure to execute the UI update on the main thread
    private func asyncDownloadImage(_ name: String, _ landmark: Landmark) {
        
        // trigger asynchronous download
        Task {
            guard let app = AppDelegate.instance else {
                fatalError("AppDelegate is not initilized correctly")
            }
            
            // download the image from our API 
            let data = await app.downloadImage(name)
            
            // convert to an image : Data -> UIImage -> Image
            let img = Image(fromData: data, scale: imageScale, name: name)
            
            // store image in cache
            addImage(name: name, image: img)
            
            // update landmark object, this will trigger the UI refresh because image is Published
            // and Landmark is Observable in LandmarkRow UI component
            landmark.image = img
        }
    }
    
    // return the placeholder image from the cache
    func placeholder() -> Image {
        if let img = images[self.placeholderName] {
            return img
        } else {
            fatalError("Image cache is incorrectly initialized")
        }
    }

    // add image to the cache
    func addImage(name: String, image : Image) {
        images[name] = image
    }
}
```

What did we just change ?  

- line 39-48 : we created an `UIImage` extension to generate a white square image to be used as placeholder.

- line 52-60 : we added code to create an `Image` class from `Data`.  Notice how the image is generated : `Amplify.Storage.downloadData()` returns a [Data](https://developer.apple.com/documentation/foundation/data) while `Landmark.image` expects a SwiftUI [Image](https://developer.apple.com/documentation/swiftui/image).  To transform the [Data](https://developer.apple.com/documentation/foundation/data) to an [Image](https://developer.apple.com/documentation/swiftui/image), we first create an [UIImage](https://developer.apple.com/documentation/uikit/uiimage) using `UIImage(data:)` and then call `Image.init(cgImage:scale:label)` with `cgImage`.

- line 63-144 : we re-wrote `ImageStore` class. It now has three methods : `.addImage(name:String ,image: Image)` to add an image to the cache.  It uses `.image(name: String, landmark: Landmark)` to retrieve an image from the cache.  If the image is not present, it returns a placeholder and triggers the download. The download is implemented by `asyncDownloadImage(_ name: String, _ landmark: Landmark)`. This method triggers the download on a separate thread (`Task`). It transforms the `Data` to `Image` and adds the image to the cache and then to the landmark. This triggers a UI refresh. For this reason, the whole method must run on the main thread (`@MainActor`).

## Update the Landmark & LandmarkRow classes

Finally, we are adding a few fields and behaviours to the `Landmark` and `LandmarkRow` classes.

**LandmarkRow class**

A `LandmarkRow` is a UI row in the landmark table.  We mark the `Landmark` object as "observable" with the directive `@ObservedObject`

{{% notice tip %}}
`ObservedObject` directive is part of the [SwiftUI framework](https://developer.apple.com/documentation/swiftui/observedobject). It is a property wrapper type that subscribes to an observable object and invalidates a view whenever the observable object changes. 
{{% /notice %}}

You can just add the `@ObservedObject` directive in front of `var landmark: Landmark` line or copy / paste the whole file here:

```swift {hl_lines=[11]}
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A single row to be displayed in a list of landmarks.
*/

import SwiftUI

struct LandmarkRow: View {
    @ObservedObject var landmark: Landmark
    
    var body: some View {
        HStack {
            landmark.image
                .resizable()
                .frame(width: 50, height: 50)
            Text(verbatim: landmark.name)
            Spacer()

            if landmark.isFavorite {
                Image(systemName: "star.fill")
                    .imageScale(.medium)
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct LandmarkRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LandmarkRow(landmark: landmarkData[0])
            LandmarkRow(landmark: landmarkData[1])
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
```

**Landmark class** 

In order to make `Landmark` observable, we need to transform this `struct` into a full fledged `class`. This implies adding an initializer and a few fields, such as `CodingKeys` to make it conforming to [Decodable](https://developer.apple.com/documentation/swift/codable) protocol.

```swift {hl_lines=[11,22,"25-38",41,63,"80-89"]}
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The model for an individual landmark.
*/

import SwiftUI
import CoreLocation

class Landmark: Decodable, Identifiable, ObservableObject {
    var id: Int
    var name: String
    fileprivate var imageName: String
    fileprivate var coordinates: Coordinates
    var state: String
    var park: String
    var category: Category
    var isFavorite: Bool

    // advertise changes on this property.  This will allow Views to refresh when image is changed.
    @Published var image : Image = ImageStore.shared.placeholder()

    // consequence is that I need to add the constructor from decoder
    required init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: LandmarkKeys.self) // defining our (keyed) container
         id          = try container.decode(Int.self, forKey: .id)
         name        = try container.decode(String.self, forKey: .name)
         imageName   = try container.decode(String.self, forKey: .imageName)
         state       = try container.decode(String.self, forKey: .state)
         park        = try container.decode(String.self, forKey: .park)
         isFavorite  = try container.decode(Bool.self, forKey: .isFavorite)
         category    = try container.decode(Category.self, forKey: .category)
         coordinates = try container.decode(Coordinates.self, forKey: .coordinates)

        // returns a cached image or placeholder synchronously, and trigger an image download asynchronously
        image = ImageStore.shared.image(name: imageName, landmark: self)
    }

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

        // returns a cached image or placeholder synchronously, and trigger an image download asynchronously
        image = ImageStore.shared.image(name: imageName, landmark: self)
    }
    
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
    
    // part of Decodable protocol, I need to declare all keys from the jSON file
    enum LandmarkKeys: String, CodingKey {
        case id          = "id"
        case name        = "name"
        case imageName   = "imageName"
        case category    = "category"
        case isFavorite  = "isFavorite"
        case park        = "park"
        case state       = "state"
        case coordinates = "coordinates"
    }
}

struct Coordinates: Hashable, Codable {
    var latitude: Double
    var longitude: Double
}
```

What we did just change ?

- line 11 : we transformed the `struct` into a `class` to make it `Observable`.

- line 22 : we add a stored property to hold the SwiftUI image to be used by the user interface. This property is `@Published`, it means observers, such as `LandmarkRow`, will receive a notification when its value change.

- line 25-38 : we add a new initialiser `init(from: Decoder)` to comply to the `Decodable` protocol. The initiliazer also triggers the image download when an instance of `Landmark` is created.

- line 41 : because `Landmark` is now a class, we moved the initializer created in previosu step to the core class.

- line 63 : we added the image initialization code to the existing initializer.

- line 80-89 : we add the list of items available for decoding, as per `Decodable` protocol.


<!--
The list of all changes we made to the code is visible in [this commit](https://github.com/sebsto/amplify-ios-workshop/commit/3e77d8a992d6600ba8bee3169c2ff30f5122c608).
-->

## Launch the app 

Build and launch the application to verify everything is working as expected. Click the **build** icon <i class="far fa-caret-square-right"></i> or press **&#8984;R**.
![build](/images/20-20-xcode.png)

After a few seconds, you should see the application running in the iOS simulator.
![run](/images/40-30-appsync-code-2.png)

{{% notice tip %}}
When you start the app, you will notice the table's rows are populated as soon as the landmark data are fetched from the API.  At that moment, no image is shown (to be correct, the white square placeholder image is shown). As Amazon S3 downloads finish, images are added asynchronously to the table's rows.
{{% /notice %}}

Now that we have the basic building blocks of the app defined, let's explore the options offered to customize the authentication user interface and user experience.
