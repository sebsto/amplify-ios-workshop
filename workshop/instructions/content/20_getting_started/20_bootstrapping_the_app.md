---
title : "Bootstrapping the App"
chapter : false
weight : 20
---

The starting point for the workshop is the [Apple Swift UI tutorial](https://developer.apple.com/tutorials/swiftui/tutorials) at the "Handling User Input" step. I slightly modified the app to make it a SwiftUI-only application. Start with the ZIP file provided below.

1. Download the {{% button href="/20_getting_started/20_bootstrapping_the_app.files/HandlingUserInput.zip" icon="fas fa-download" %}}project zip file{{% /button %}}  
The file has the following directory structure
![Directory Structure](/images/20-10-directory-structure.png)

2. This workshop will start from the *Complete* version of the tutorial project.  In the remaining part of this workshop, `$PROJECT_DIRECTORY` will refer to `~/Downloads/amplify-ios-workshop/Complete/Landmarks`.  

    Unzip the file and open the Xcode project:

 ```bash
 # download the workshop ZIP file
 # TODO update download URL when final
 # curl -o ~/Downloads/HandlingUserInput.zip https://amplify-ios-workshop-new.go-aws.com/20_getting_started/20_bootstrapping_the_app.files/HandlingUserInput.zip

 # unzip 
 cd ~/Downloads
 unzip HandlingUserInput.zip
 cd amplify-ios-workshop

 # set env variable
 PROJECT_DIRECTORY=~/Downloads/amplify-ios-workshop/Complete/Landmarks
 cd $PROJECT_DIRECTORY

 # open xcode 
 open HandlingUserInput.xcodeproj
 ```

You can safely ackowledge Xcode's message informing you this app has been downloaded from Internet.
![Xcode warning](/images/20-20-xcode-warning.png)

3. In Xcode, **Choose** the iOS Simulator you want to use (I am using iPhone 14) and click the **build** icon <i class="far fa-caret-square-right"></i> or press **&#8984;R**.
![First build](/images/20-20-xcode.png)

After a few seconds, you should see the application running in the iOS simulator.
![First run](/images/20-20-app-start.png)

In the following steps, we will guide you through step by step instructions to modify this app to add user authentication and a data-driven API.

{{% notice warning %}}
If the example application in not starting or not working as described above, do not proceed to the next section. The instructions will fail at some point.</a>
{{% /notice %}}

<!--
{{%attachments title="Project files" pattern=".*.zip"/%}}
-->

**🧷 Project Files:**

- [HandlingUserInput.zip](/20_getting_started/20_bootstrapping_the_app.files/HandlingUserInput.zip)