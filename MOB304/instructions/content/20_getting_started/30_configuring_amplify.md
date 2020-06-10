+++
title = "Configuring Amplify"
chapter = false
weight = 30
+++

This workshop proposes to use [AWS Amplify](https://aws.amazon.com/amplify/) to create and integrate with a cloud-based backend.  AWS Amplify comprises two components: a [command line tool](https://aws-amplify.github.io/docs/cli-toolchain/quickstart) to easily provision cloud-based services from your laptop and a [library](https://aws-amplify.github.io/docs/ios/start) to access these services from your application code. You installed the CLI as part of the [prerequisites instructions](/10_prerequisites/20_installs.html#installing-or-updating).  Now we integrate Amplify tools with your Xcode project.

## Add Amplify to your application

Amplify for iOS is distribued through Cocoapods as a Pod. In this section, you’ll setup cocoa pods and add the required Amplify packages.

1. Before starting this step, please make sure that **please close Xcode**.

{{% notice warning %}}
Did you really close Xcode ?
{{% /notice %}}
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