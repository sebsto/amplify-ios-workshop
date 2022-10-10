This is the source code for [https://amplify-ios-workshop.go-aws.com/](https://amplify-ios-workshop.go-aws.com/)

## Status 

Before re:Invent 2022, current builds are available at [https://main.d1p0aatx1581oy.amplifyapp.com/](https://main.d1p0aatx1581oy.amplifyapp.com/)

## In progress (status 10/3/2022)

[] Refactoring workshop instructions for Signin With Apple

**October 10 2022**

- Refactoring workshop instructions to take into account code modifications (sections 1-5)

**September 14 2022**

- Test workshop instructions with 2022 Amplify and report misses  
- using Amplify iOS dev-preview branch from here https://github.com/aws-amplify/amplify-ios/tree/dev-preview
- Reafactoring code for new concurrency model (`async`/`await` amongst others)
- no more dependencies on CocoaPods, will need to changes instructions 
- most of the rest works, modulo a few code changes.

- Auth : OK 
- API  : OK. Requires to patch generated code because of https://github.com/aws-amplify/amplify-ios/issues/1443 
- New code with Auth and API by this [commit](https://github.com/sebsto/amplify-ios-workshop/commit/d89d27b7ab600c436f522983d4d2407e9ac3bf09)

- Remove UIKit and Migrate to a 100% SwiftUI app ([commit](https://github.com/sebsto/amplify-ios-workshop/commit/5d0f776ab0a63ac96cf486498550adb68800b383))

- Storage : OK. Requires some changes in the threading code. Check this [commit](https://github.com/sebsto/amplify-ios-workshop/commit/ef04d4fe218bf9c956e196c041ac689c03125d32).

**September 8 2022** 

- Refresh directory structure to prepare for re:Invent 2022.  
- New TODO list  

## TODO - Code 

[X] ~~Resolve TODO left in the code~~

## TODO - Instructions 

[] Update instructions to support new AWS Workshop Studio 
[X] ~~Update instructions to use SPM vs CocoaPods~~
[X] ~~Update Signin part to use "Signin With Apple" instead of "Login with facebook"~~
[] Update instructions to add custom signin UI
[] Use Amplify Datastore rather than straigth API calls ?  (if we have time)

## TODO - Infrastructure 

[X] refresh hugo version in local docker (run.sh)  
[X] refresh hugo on Amplify Build (buildspec.yml)  
[] Deploy on https://workshop.aws  
[] Add Adbove Analytics tracking to web pages  
[X] fix error in hugo build  

<!-- ### Dir Structure

```text
x (you are here)
|
|-- code
      |-- Complete       <== this is the final result of the workshop
      |-- StartingPoint  <== this is the starting point of the app
|
|-- instructions         <== this is the static web site
``` -->

### Deploy

The instruction web site is generated with [Hugo](https://gohugo.io) and the [Learn theme](https://learn.netlify.com/en/).
To build the web site :
```
cd instructions
hugo
```

To serve the web site in development mode:
```
cd instructions
hugo serve
```

This site is automatically deployed to https://amplify-ios-workshop.go-aws.com
