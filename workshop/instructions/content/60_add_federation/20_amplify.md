---
title : "Update Amplify"
chapter : false
weight : 20
---

Amazon Cognito does support Identity Federation out of the box with [Login With Amazon](https://login.amazon.com/), [Login with Google](https://developers.google.com/identity/sign-in/web/sign-in), [Login with Facebook](https://developers.facebook.com/docs/facebook-login/), [Sign in with Apple](https://aws.amazon.com/blogs/security/how-to-set-up-sign-in-with-apple-for-amazon-cognito/), or any [OIDC](https://openid.net/connect/) or [SAMLv2](https://en.wikipedia.org/wiki/SAML_2.0) compliant identity provider.  

We use AWS Amplify command line to update the Amazon Cognito configuration on the backend and add support for Sign In with Apple.

{{% notice warning %}}
There are four values to be collected from previous step.  Be sure you have it all in a text editor before starting this section
{{% /notice %}}

In a terminal, type:

```bash 
cd $PROJECT_DIRECTORY
amplify update auth
```

1. What do you want to do? Choose **Update OAuth social providers** and **press enter** 

2. Select the identity providers you want to configure for your user pool:  Use the arrow keys to highlight **Sign in with Apple** and press **space**, then **press enter**.

3. Enter your Services ID for your OAuth flow. Type your **Service ID** and **press enter** (in my example `com.amazonaws.amplify.workshop.landmarks.signin`).

4. Enter your Team ID for your OAuth flow:  Type your **Team ID** and **press enter** (in my example `56********`).

5. Enter your Key ID for your OAuth flow:  Type your **Key ID** and **press enter** (in my example `3HL6GKYJ5L`)

6. Enter your Private Key for your OAuth flow: Type your **private key as a one-line PEM format** (in my example `-----BEGIN PRIVATE KEY-----MIG  (redacted)  y6P-----END PRIVATE KEY-----`)

`amplify` creates the required resources to deploy the Sign in with Apple configuration in the cloud.

![amplify update auth](/images/60-20-amplify-1.png)

## Create the API backend in the cloud

In a Terminal, assuming you are still in your project directory, type:

```bash 
amplify push
```

1. Are you sure you want to continue? Review the table and verify the Auth service is being Updated.  Accept the default (**Yes**) and **press enter**.

Amplify updates the backend infrastructure, it adds the federation configuration to Amazon Cognito.  After a while, you should see the familiar message :

```text 
Deployment completed.
```

![amplify update auth](/images/60-20-amplify-2.png)

That's it !  There is no change required in the code. The federation happens between Cognito and Apple on the server side. We can start our app and start to test immediately.