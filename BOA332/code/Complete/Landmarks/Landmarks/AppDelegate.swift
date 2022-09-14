import UIKit
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin

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
            Task {
                try await self.checkUserSignedIn()
            }
            
            // listen to auth events.
            // see https://github.com/aws-amplify/amplify-ios/blob/dev-preview/Amplify/Categories/Auth/Models/AuthEventName.swift
            let _ : UnsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
                switch payload.eventName {
                    
                case HubPayload.EventName.Auth.signedIn:
                    print("==HUB== User signed In, update UI")
                    
                    Task {
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
    @MainActor
    func updateUI(forSignInStatus : Bool) async {
            self.userData.isSignedIn = forSignInStatus
            
            // load landmarks at start of app when user signed in
            if (forSignInStatus && self.userData.landmarks.isEmpty) {
                await self.queryLandmarks()
            }
    }
    
    // when user is signed in, fetch its details
    func checkUserSignedIn() async throws {
        
        // every time auth status changes, let's check if user is signedIn or not
        // updating userData will automatically update the UI
        let session = try await Amplify.Auth.fetchAuthSession()
        await self.updateUI(forSignInStatus: session.isSignedIn)
        
    }
    
    // signin with Cognito web user interface
    public func authenticateWithHostedUI() async throws {
        
        print("hostedUI()")
        let result = try await Amplify.Auth.signInWithWebUI(presentationAnchor: UIApplication.shared.windows.first!)
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
        let result = await Amplify.Auth.signOut(options: options)
        print("Signed Out")
    }
    
    // MARK: API Access
    
    func queryLandmarks() async {
        print("Query landmarks")
        
        do {
            let result = try await Amplify.API.query(request: .list(LandmarkData.self))
            print("Landmarks query complete.")
            
            print("Successfully retrieved list of landmarks")
            for entry in try result.get() {
                let landmark = Landmark.init(from: entry)
                DispatchQueue.main.async() {
                    self.userData.landmarks.append(landmark);
                }
            }
        } catch let error as APIError {
            print("Failed to load data from api : \(error)")
        } catch {
            print("Unexpected error while calling API : \(error)")
        }
    }
}

