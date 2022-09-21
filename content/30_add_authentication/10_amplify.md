---
title : "Add an authentication backend"
chapter : false
weight : 10
---

Now that we have the application up and running and all the pre-requisites installed, let's add user authentication.

## Add an authentication backend

We will now set up an [Amazon Cognito](https://aws.amazon.com/cognito/) User Pool to act as the backend for letting users sign up and sign in. (More about Amazon Cognito and what a User Pool is below).

Amazon Cognito also offers a hosted user interface, i.e. a web based authentication view that can be shared between your mobile and web clients. The hosted UI is a customisable OAuth 2.0 flow that allows to launch a login screen without embedding the SDK for Cognito or a Social provider in your application.

You can learn more about the Hosted UI experience in the [Amplify documentation]https://docs.amplify.aws/lib/auth/signin_web_ui/q/platform/ios) or in the [Amazon Cognito documentation](https://docs.aws.amazon.com/en_pv/cognito/latest/developerguide/cognito-user-pools-configuring-app-integration.html).

In a Terminal, type the following commands:

```bash
cd $PROJECT_DIRECTORY
amplify add auth
```

1. Do you want to use the default authentication and security configuration? Use the arrow keys to select **Default configuration with Social Provider (Federation)** and press enter

1. How do you want users to be able to sign in? Accept the default **Username** and press enter.

1. Do you want to configure advanced settings? Accept the default **No, I am done.** and press enter.

1. What domain name prefix you want us to create for you? Accept the default (**amplifyiosworkshopxxxxxx**) and press enter.

1. Enter your redirect signin URI: Type **landmarks://** and press enter.

1. Do you want to add another redirect signin URI? Accept the default **N** and press enter.

1. Enter your redirect signout URI: Type **landmarks://** and press enter.

1. Do you want to add another redirect signout URI? Accept the default **N** and press enter.

1. Select the social providers you want to configure for your user pool. **Do not select any other provider at this stage**, press **enter**.

![amplify init](/static/images/30-10-amplify-add-auth.png)

Amplify generates configuration files in `$PROJECT_DIRECTORY/amplify`. To actually create the backend resources, type the following command:

```bash
amplify push
```

1. Are you sure you want to continue? Accept the default **Y** and press enter.

![amplify init](/static/images/30-10-amplify-push-1.png)

After a while, you should see:

![amplify init](/static/images/30-10-amplify-push-2.png)

::alert[Amazon Cognito lets you add user sign-up, sign-in, and access control to your web and mobile apps quickly and easily. We just made a User Pool, which is a secure user directory that will let our users sign in with the username and password pair they create during registration. Amazon Cognito (and the Amplify CLI) also supports configuring sign-in with social identity providers, such as Facebook, Google, and Amazon, and enterprise identity providers via SAML 2.0. If you'd like to learn more, we have a lot more information on the [Amazon Cognito Developer Resources page](https://aws.amazon.com/cognito/dev-resources/) as well as the [AWS Amplify Authentication documentation.](https://aws-amplify.github.io/docs/ios/authentication)]{header="Tip" type="success"}

