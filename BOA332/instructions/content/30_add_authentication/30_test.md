---
title : "Create a user and test"
chapter : false
weight : 30
---

You just add a bit of logic in `AppDelegate` class to sign in and to sign out users.  You also modified the screen flow to start the app with a `LandingView` that controls the routing towards a `UserBadge` or the `LandmarkList` view based on the user authentication status.

Let's now verify everythign works as expected.  Start the application using Xcode's menu and click **Product**, then **Run** (or press **&#8984;R**).

The application starts and shows the `LandingView`.  Click on the user icon in the middle of the screen to trigger the user authentication, using Cognito's web user interface. Click on **Sign up** at the bottom of the screen to signup a new user.

Landing View | Login View (Cognito) | Signup View (Cognito)
:---: | :---: | :---: |
![Landing View](/images/30-20-test-1.png) | ![App Login Screen](/images/30-20-test-5.png) | ![App Signup Screen](/images/30-20-test-3.png) |

After clicking **Sign Up**, check your email.  Cognito sends you a confirmation code.

Code View (Cognito) | Landmarks List View
:---: | :---: |
![Confirmation Code](/images/30-20-test-4.png) | ![Landmark list](/images/30-20-test-6.png) |

Click **Sign Out** to end the session and, after a short redirection to Cognito's signout page, you return to the `LandingView`.

In the Xcode console, you see some application debugging information like the username and profile of the signed in user.  

```text 
Sign in succeeded
==HUB== User signed In, update UI
2022-10-06T10:16:01+0200 info CognitoIdentityProviderClient : [Logging] Request: POST https:443 
 Path: / 
 X-Amz-Target: AWSCognitoIdentityProviderService.GetUser, 
Host: cognito-idp.eu-central-1.amazonaws.com, 
x-amz-user-agent: aws-sdk-swift/1.0, 
Content-Length: 1113, 
Content-Type: application/x-amz-json-1.1, 
User-Agent: aws-sdk-swift/1.0 api/cognito-identity-provider/1.0 os/iOS/16.0.0 lang/swift/5.7 lib/amplify-ios/1.27.1-swift-sdk-dev-preview.0 
 Optional([])

... (redacted for brevity) ...

User attribtues - [Amplify.AuthUserAttribute(key: Amplify.AuthUserAttributeKey.sub, value: "cab0d396-008a-4131-87ee-4c6ae13436cc"), Amplify.AuthUserAttribute(key: Amplify.AuthUserAttributeKey.emailVerified, value: "true"), Amplify.AuthUserAttribute(key: Amplify.AuthUserAttributeKey.email, value: "stormacq@amazon.com")]
```

{{% notice warning %}}
This application displays user personal information, such as the email address and the Cognito ID in the console.  In real life DO NOT print these information in the console.  We did this for education purpose only.
{{% /notice %}}