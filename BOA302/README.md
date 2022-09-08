This is the source code for [https://amplify-ios-workshop.go-aws.com/](https://amplify-ios-workshop.go-aws.com/)

## Status 

Before re:Invent 2022, current build are available at [https://main.d1p0aatx1581oy.amplifyapp.com/](https://main.d1p0aatx1581oy.amplifyapp.com/)

**September 8 2022** 

- Refresh directory structure to prepare for re:Invent 2022.
- New TODO list

## TODO - Code 

[] Test workshop instructions with 2022 Amplify and report misses
[] Review for Swift 5 / Xcode 13 compatibility 
[] Migrate callbacks to async / await pattern
[] Test workshop instructions with 2022 Amplify and report misses
[] Resolve TODO left in the code 

## TODO - Instructions 

[] Deploy on new AWS Event Engine 
[] Update instructions to support new AWS Event Engine 
[] Update Signin part to use "Signin With Apple" instead of "Login with facebook"
[] Deploy on https://workshop.aws
[] Add Adbove Analytics tracking to web pages

## TODO - Infrastructure 

[] refresh hugo version in local docker (run.sh) 
[] refresh hugo on Amplify Build (buildspec.yml)
[X] fix error in hugo build 

### Dir Structure

```text
x (you are here)
|
|-- code
      |-- Complete       <== this is the final result of the workshop
      |-- StartingPoint  <== this is the starting point of the app
|
|-- instructions         <== this is the static web site
```

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
