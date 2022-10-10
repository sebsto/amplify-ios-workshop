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

