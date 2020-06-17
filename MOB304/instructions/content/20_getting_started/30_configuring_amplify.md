+++
title = "Configuring Amplify"
chapter = false
weight = 30
+++

This workshop proposes to use [AWS Amplify](https://aws.amazon.com/amplify/) to create and integrate with a cloud-based backend.  AWS Amplify comprises two components: a [command line tool](https://aws-amplify.github.io/docs/cli-toolchain/quickstart) to easily provision cloud-based services from your laptop and a [library](https://aws-amplify.github.io/docs/ios/start) to access these services from your application code. You installed the CLI as part of the [prerequisites instructions](/10_prerequisites/20_installs.html#installing-or-updating).  Now we integrate Amplify tools with your Xcode project.

## Add Amplify to your application

Amplify for iOS is distribued through [Cocoapods](https://cocoapods.org/) as a Pod. In this section, you’ll setup cocoa pods and add the required Amplify packages.

Before starting this step, please make sure that **please close Xcode**.

{{% notice warning %}}
Did you really close Xcode ?
{{% /notice %}}

1. In order to initialize your project with the CocoaPods package manager, execute the command:
```bash
cd $PROJECT_DIRECTORY
pod init
```

1. After doing this, you should see a newly created file called Podfile. This file is used to describe what packages your project depends on.
{{% notice info %}}
You can safely ignore the "PBXNativeTarget name=`Landmarks` UUID=`B7394861229F194000C47603" warning, we will fix this in a minute.
{{% /notice %}}

1. **Type the below command** to include the following pods in the Podfile:
{{< highlight bash >}}
cd $PROJECT_DIRECTORY
echo "platform :ios, '13.0'

target 'Landmarks' do
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!

    # Pods for Landmarks
    pod 'Amplify', :git => 'https://github.com/aws-amplify/amplify-ios', :branch => 'master'           # required amplify dependency
    pod 'Amplify/Tools', :git => 'https://github.com/aws-amplify/amplify-ios', :branch => 'master'     # allows to cal amplify CLI from within Xcode

end" > Podfile
{{< /highlight >}}

1. To download and install the Amplify pod into your project, execute the command:
```bash
cd $PROJECT_DIRECTORY
pod install --repo-update
```
{{% notice info %}}
You can safely ignore the "PBXNativeTarget name=`Landmarks` UUID=`B7394861229F194000C47603" warning, we will fix this in a minute.
{{% /notice %}}

1. After doing this, you should now see file called `HandlingUserInput.xcworkspace`. You are required to use this file from now on instead of the `.xcodeproj` file. To open your workspace, execute the command:

```bash
xed .
```
This should open the newly generated `HandlingUserInput.xcworkspace` in Xcode.

## Update Target Configurations for CocoaPods

This step is specific to the project we downloaded.  This is **not required** when setting up new projects with Amplify. This step addresses the Cocoapods warning we saw when we issued the `pod init` command above.

In your Xcode project, click on **HandleUserInput** on the top left part of the screen, then **Info**.  Select **HandlingUserInput** under **Project**.  Open **Configurations**, **Debug**.  For the **landmarks** target, replace the configuration by **Pods-landmarks.debug**. Repeat the operation for the **release** target, using **Pods-landmarks.release** configuration.  Your project should look like this:  
![pod install](/images/30-20-pod-install-2.png)

## Initialize Amplify

The first time you use AWS Amplify in a project, Amplify needs to initialise your project directory and the cloud environment.  We assume *$PROJECT_DIRECTORY* is set and unchanged from [previous step](/20_getting_started/20_bootstrapping_the_app.html).

In a Terminal, type the following commands:

```bash
cd $PROJECT_DIRECTORY
amplify init
```

1. Enter a name for your project: enter **amplifyiosworkshop** and press enter.

1. Enter a name for your environment: enter **dev** and press enter.

1. Choose your default editor:  use the arrow keys to scroll to **None** and press enter.

1. Choose the type of app that you're building: accept the default **ios** and press enter.

1. Do you want to use an AWS profile? accept the default **Yes** and press enter.

1. Please choose the profile you want to use: accept the default **default** or type the name of the profile you created during [step 1.3](/10_prerequisites/30_configs.html#configuring-the-aws-command-line) (such as **workshop**) and press enter.

![amplify init](/images/30-10-amplify-init.png)

Amplify will create a local directory structure to host your project's meta-data.  In addition, it will create the backend resources to host your project : two IAM roles, an S3 bucket and a AWS Cloudformation template.  After 1 or 2 minutes, you should see the below messages:

![amplify init](/images/30-10-amplify-init-ok.png)

### Add Amplify configuration files to the project 

Rather than configuring each service through a constructor or constants file, the Amplify and the underlying AWS SDKs for iOS support configuration through centralized files called `awsconfiguration.json` and `amplifyconfiguration.json`. They defines all the regions and service endpoints to communicate. Whenever you run `amplify push`, these files are automatically created allowing you to focus on your Swift application code. On iOS projects the `awsconfiguration.json` and `amplifyconfiguration.json` are located at the root project directory. You have to add them manually to your Xcode project.

In the Finder, drag `awsconfiguration.json` into Xcode under the top Project Navigator folder (the folder named *HandleUserInput*). When the *Options* dialog box appears, do the following:

- Clear the **Copy items if needed** check box.
- Choose **Create groups**, and then choose **Finish**.

![Add awsconfiguration](/images/30-20-add-awsconfiguration.gif)

Repeat the process for `amplifyconfiguration.json`.

Before proceeding to the next step, ensure you have both files added to your project, like one the screenshot below.

![Two configuration files added](/images/30-20-two-configuration-files.png)

## Build the project

Now that we’ve added Amplify tools to the build process, it will run when you build you project.  Before proceeding to the next steps, **build** (&#8984;B) the project to ensure there is no compilation error. 

You are ready to start building with Amplify! 🎉