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