+++
title = "Create a user and test"
chapter = false
weight = 30

[[resources]]
  name = "LandingView"
  src = "images/30-20-test-1.png"
+++

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

In the Xcode console, you see some application debugging information: the username and profile of the signed in user as well as its Cognito token.  

```text 
2020-06-08 17:11:26.908420+0200 Landmarks[86260:7126165] [Amplify] Configuring
Amplify initialized
hostedUI()
2020-06-08 17:11:39.156307+0200 Landmarks[86260:7126165] [Amplify] AWSMobileClient Event listener - signedIn
Sign in succeeded
==HUB== User signed In, update UI
User attribtues - [Amplify.AuthUserAttribute(key: Amplify.AuthUserAttributeKey.unknown("email_verified"), value: "true"), Amplify.AuthUserAttribute(key: Amplify.AuthUserAttributeKey.email, value: "stormacq@amazon.com"), Amplify.AuthUserAttribute(key: Amplify.AuthUserAttributeKey.unknown("sub"), value: "ba12b222-b50c-498e-a911-08f11e53f624")]
2020-06-08 17:11:46.832938+0200 Landmarks[86260:7126165] [Amplify] AWSMobileClient Event listener - signedOut
Successfully signed out
==HUB== User signed Out, update UI
```

{{% notice warning %}}
This application displays user personal information, such as the email address and the Cognito ID in the console.  In real life DO NOT print these information in the console.  We did this for education purpose only.
{{% /notice %}}