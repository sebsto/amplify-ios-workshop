## Status

**June 26** 
Brand new version using Amplify iOS Lib 1.0 

**June 7 2020**
Create `amplifylibs` branch to host version based on new [Amplify iOS Library](https://docs.amplify.aws/start/q/integration/ios)

**Dec 2**
First delivery at re:Invent 2019

**Nov 15**
Dry Run done

**Oct 27**
First draft of workshop instruction released

**Oct 23**
Workshop web site is scaffolded and deployment pipeline ready.

**Oct 22**
Final application is working and demo-able.  Some tweaks and improvements can be done, but I have a basis to start to write the core of the workshop now.

## TODO

### Workshop Code

- [ ] eliminate the TODO in the code

### Workshop Instructions

- [ ] global signout [is now the default](https://github.com/aws-amplify/amplify-ios/pull/542), should simplify signout code by removing the options
- [ ] add instruction to use other IDP (apple, google, amazon)
- [ ] use Hugo page resource to load images
- [ ] unify Xcode screenshots (bright vs dark theme) 
- [ ] add amplify build script to project as per [official doc](https://docs.amplify.aws/start/getting-started/setup/q/integration/ios), and remove 'add configuration files' steps in 30.20.

### Done

- [X] add commits at end of each steps
- [X] add s3 async download code to workshop instructions
- [X] remove re:invent specific instructions
- [X] use curl to download ZIP file
- [X] test presence of ~/.aws directory in setup instructions
- [X] refactor code to download images asynchronously (GitHub only)
- [X] add permissions to view Cognito in the console
- [X] debug ../../scripts/get_app_client.sh
- [X] test and dry run
- [X] refactor IAM permissions to use least priviledge
- [X] add reinvent specific instructions to use event engine accounts
- [X] scaffold the workshop web site
- [X] host the project on github + amplify console for hosting and CI/CD.  Use the shared evangelist account.
- [X] write the workshop instructions
- [X] add instructions for identity federation (section 6)
- [X] add instruction to use a custom GUI screen (section 7)
- [X] Fix landmark details page
- [X] code : cache downloaded images