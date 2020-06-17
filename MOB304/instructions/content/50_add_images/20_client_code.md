+++
title = "Update application code"
chapter = false
weight = 20
+++

Now that the storage backend is ready, let's modify the application code to load the images from Amazon S3.  We're going to make several changes in the application:

- [add AWS Amplify dependencies](#add-amazon-s3-client-library) to the project 

- [add the code](#add-storage-access-code-in-appdelegate) to query Amazon S3 to `AppDelegate`

- [update](#update-imagestore-class) the `ImageStore` class in the *Landmarks/Models/Data.swift* file to load the cloud images instead of the local ones.

- change [Landmarks and LandmarkRow](#update-the-landmark-landmarkrow-classes) classes to publish / observe changes on image.

{{% notice tip %}}
You can learn more about SwiftUI publish subscribe framework, called [Combine](https://developer.apple.com/documentation/combine), [in this article](https://developer.apple.com/documentation/combine/receiving_and_handling_events_with_combine).
{{% /notice %}}

## Add Amazon S3 client library

Edit `$PROJECT_DIRECTORY/Podfile` to add the Amazon S3 client dependency.  Your `Podfile` must look like this (you can safely copy/paste the entire file from below):

{{< highlight bash "hl_lines=13">}}
cd $PROJECT_DIRECTORY
echo "platform :ios, '13.0'

target 'Landmarks' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Landmarks
  pod 'Amplify', :git => 'https://github.com/aws-amplify/amplify-ios', :branch => 'master'                             # required amplify dependency
  pod 'Amplify/Tools', :git => 'https://github.com/aws-amplify/amplify-ios', :branch => 'master'                       # allows to cal amplify CLI from within Xcode
  pod 'AmplifyPlugins/AWSCognitoAuthPlugin', :git => 'https://github.com/aws-amplify/amplify-ios', :branch => 'master' # support for Cognito user authentication
  pod 'AmplifyPlugins/AWSAPIPlugin', :git => 'https://github.com/aws-amplify/amplify-ios', :branch => 'master'         # support for GraphQL API
  pod 'AmplifyPlugins/AWSS3StoragePlugin', :git => 'https://github.com/aws-amplify/amplify-ios', :branch => 'master'   # support for Amazon S3 storage

end" > Podfile
{{< /highlight >}}

In a Terminal, type the following commands to download and install the dependencies:

```bash
cd $PROJECT_DIRECTORY
pod install --repo-update
```

After one minute, you shoud see the below:

![Pod update](/images/50-20-s3-code-1.png)

Now it's time to change the code.  At high level, this is what we are going to change:

- add AWS S3 file transfer code in `AppDelegate`
- modify `ImageStorage` class from the initial code sample to download images from the cloud instead of reading the file from the local bundle. (we simplified and redesigned that class to meet our needs)
- modify `Landmark` and `LandmarkRow` class to publish changes made to the former to the latter.

## Add storage access code in AppDelegate

To add storage access code, we first add the `AWSS3StoragePlugin` to Amplify's runtime.  File upload and download capability is provided by `Amplify.Storage` class.  This class offers a high level interface to manage file uploads and downloads.  It also allows to pause and restart transfers and to monitor progress.  For this workshop, our usage will be simpler.  The code downloads a file by name and calls a callback function when the `Data` object is available.

As usual, you can safely copy/paste the entire `AppDelegate` from below.  Lines that have been added since last section are highlighted.

{{< highlight swift "hl_lines=23 179-199" >}}
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
{{< /highlight>}}

Notice that `Amplify.Storage.downloadData()` class is asynchronous and returns immediately.  It takes a callback function as argument to be notified when the transfer completes. The callback takes care of passing the `Data` received to its caller.

## Update ImageStore class

The `ImageStore` class is part of the original code sample we started from. It is located in *Landmarks/Models/Data.swift* file.  This class takes care of caching images in memory to avoid loading them at each access. It also provider a placeholder when the image is not downloaded yet.  The placeholder is an empty white image generated with an extension of the `UIImage` class.

Open `Landmarks/Models/Data.swift` and paste the content below:

{{< highlight swift "hl_lines=37-48 50-106" >}}
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

func load<T: Decodable>(_ filename: String, as type: T.Type = T.self) -> T {
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

// manage iage cache and download
final class ImageStore {
    typealias _ImageDictionary = [String: Image]
    
    fileprivate let placeholderName = "PLACEHOLDER"
    fileprivate var images: _ImageDictionary
    static var scale = 2
    
    static var shared = ImageStore()

    init() {
        images = [:]
        images[self.placeholderName] = Image(uiImage: UIImage.imageWithColor(color: UIColor.white, size: CGSize(width:300, height: 300)))
    }
    
    func image(name: String, landmark: Landmark) -> Image {
        var result : Image?
        if let img = images[name] {
            result = img
        } else {
            
            DispatchQueue.main.async {
                // trigger asynchronous download
                let app = UIApplication.shared.delegate as! AppDelegate
                _ = app.image(name) { (data) in
                    
                    guard
                        let i = UIImage(data: data)
                    else {
                        fatalError("Couldn't convert image data \(name)")
                    }
                    let img = Image(i.cgImage!, scale: CGFloat(ImageStore.scale), label: Text(verbatim: name))
                    
                    // update UI on the main thread
                    DispatchQueue.main.async {
                        // update landmark object, this will trigger the UI refresh because image is Published
                        // and Landmark is Observable in LandmarkRow UI component
                        landmark.image = img
                    }
                }
            }
            result = self.placeholder()
        }
        return result!
    }
    
    func placeholder() -> Image {
        if let img = images[self.placeholderName] {
            return img
        } else {
            fatalError("Image cache is incorrectly initialized")
        }
    }

    func addImage(name: String, image : Image) {
        images[name] = image
    }
}
{{< /highlight >}}

What did we just change ?  

- line 39 : we created an `UIImage` extension to generate a white square image to be used as placeholder.

- line 51 : we re-wrote `ImageStore` class. It now has three methods : `.addImage(name:String ,image: Image)` to add an image to the cache.  `.image(name: String, callback: (Data) -> Void)` to retrieve an image from the cache.  If the image is not present, it returns a placeholder and triggers the download. When download completes, the callback function is called. The callback function creates the Image and updates the matching `Landmark` object. Finally, `.placeholder()` returns the placeholder image. 

Notice how the image is generated : `Amplify.Storage.downloadData()` returns a [Data](https://developer.apple.com/documentation/foundation/data) while `Landmark.image` expects a SwiftUI [Image](https://developer.apple.com/documentation/swiftui/image).  To transform the [Data](https://developer.apple.com/documentation/foundation/data) to an [Image](https://developer.apple.com/documentation/swiftui/image), we first create an [UIImage](https://developer.apple.com/documentation/uikit/uiimage) using `UIImage(data:)` and then call `cgImage` to pass to `Image.init(cgImage:scale:label)`.

## Update the Landmark & LandmarkRow classes

Finally, we are adding a few fields and behaviours to the `Landmark` and `LandmarkRow` classes.

**LandmarkRow class**

A `LandmarkRow` is a UI row in the landmark table.  We mark the `Landmark` object as "observable" with the directive `@ObservedObject`

{{% notice tip %}}
`ObservedObject` directive is part of the [SwiftUI framework](https://developer.apple.com/documentation/swiftui/observedobject). It is a property wrapper type that subscribes to an observable object and invalidates a view whenever the observable object changes. 
{{% /notice %}}

You can just add the directive in front of `var landmark: Landmark` or copy / paste the whole file here:

{{% highlight swift "hl_lines=11" %}}
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
{{% /highlight %}}

**Landmark class** 

In order to make `Landmark` observable, we need to transform this `struct` into a full fledged `class`. Tis implies adding an initializer and a few fields, such as `CodingKeys` to make it conform to [Decodable](https://developer.apple.com/documentation/swift/codable) protocol.

{{< highlight swift "hl_lines=22-36 54-55 72-82 84-85">}}
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The model for an individual landmark.
*/

import SwiftUI
import CoreLocation

// migrated Landmark from struct to class to make it Observable
class Landmark: Decodable, Identifiable, ObservableObject {
    var id: Int
    var name: String
    fileprivate var imageName: String
    fileprivate var coordinates: Coordinates
    var state: String
    var park: String
    var category: Category
    var isFavorite: Bool
    
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

        // trigger image download & set placeholder
        image = ImageStore.shared.image(name: imageName, landmark: self)
    }

     // construct from API Data
     init(from : LandmarkData) {
                
        guard let i = Int(from.id) else {
            preconditionFailure("Can not create Landmark, Invalid ID : \(from.id) (expected Int)")
        }
        
        self.id = i
        name = from.name
        imageName = from.imageName!
        coordinates = Coordinates(latitude: from.coordinates!.latitude!, longitude: from.coordinates!.longitude!)
        state = from.state!
        park = from.park!
        category = Category(rawValue: from.category!)!
        isFavorite = from.isFavorite!
        
        // trigger image download & set placeholder
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
    
    // advertise changes on this property.  This will allow Views to refresh when image is changed.
    @Published var image : Image = Image("temp")
}

struct Coordinates: Hashable, Codable {
    var latitude: Double
    var longitude: Double
}
{{< /highlight >}}

What we did just change ?

- line 36 : we add a new initialiser `init(from: Decoder)` to comply to the `Decodable` protocol. The initiliazer also triggers the image download when an instance of `Landmark` is created.

- line 72 : we add the list of items available for decoding, as per `Decodable` protocol.

- line 85 : we add a stored property to hold the SwiftUI image to be used by the user interface. This property is `@Published`, it means observers, such as `LandmarkRow`, will receive a notification when its value change.

The list of all changes we made to the code is visible in [this commit](https://github.com/sebsto/amplify-ios-workshop/commit/3e77d8a992d6600ba8bee3169c2ff30f5122c608).

## Launch the app 

Build and launch the application to verify everything is working as expected. Click the **build** icon <i class="far fa-caret-square-right"></i> or press **&#8984;R**.
![build](/images/20-10-xcode.png)

After a few seconds, you should see the application running in the iOS simulator.
![run](/images/40-30-appsync-code-2.png)

{{% notice tip %}}
When you start the app, you will notice the table's rows are populated as soon as the landmark data are fetched from the API.  At that moment, no image is shown (to be correct, the white square placeholder image is shown). As Amazon S3 downloads finish, images are added asynchronously to the table's rows.
{{% /notice %}}

Now that we have the basic building blocks of the app defined, let's explore the options offered to customize the authentication user interface and user experience.
