---
title : "Installs"
chapter : false
weight : 20
---

Before we begin coding, there are a few things we need to install, update, and configure on your laptop.

### Apple Software

In order to develop native applications for iOS, you need to have [Xcode](https://apple.com/xcode) installed on your laptop.
You can download and install Xcode from [Apple's App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12).  The download is ~2Gb, so it might take up to one hour depending on your network connection.

::alert[This workshop requires at least [Swift 5.1](https://swift.org/) and [Swift UI](https://developer.apple.com/xcode/swiftui/) framework. These are provided by [Xcode 11](https://apple.com/xcode) or more recent.]{header="Note" type="info"}

### Installing or updating

You need different command line tools to be installed : `aws`, `amplify`, `cocoapods` and `jq`.  These tools have themselves requirements on `python`, `pip`, `nodejs` and `npm`.  To install and configure these, open a Terminal on your laptop and type the following commands:

{{% tabs %}}
{{% tab "install" "Install" %}}

Follow these instructions to install the prerequisites using [HomeBrew](https://brew.sh/) package manager. 

```bash
# install brew itself
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# install python3 and pip3
brew install python3

# install the AWS CLI
brew install awscli

# install Node.js & npm
brew install node

# install the AWS Amplify CLI 
npm install -g @aws-amplify/cli

# install jq
# required to import some data into our API and
# to automate local tasks, such as cleanup)
brew install jq

# install cocoa pods
sudo gem install cocoapods
```

::alert[These commands will take a few minutes to finish.]{header="Note" type="info"}

If you already have one or several of these dependencies installed, just verify you have the latest version.  Here are the versions we tested the workshop instructions with.  Any more recent version should work as well.


```bash
brew --version
# Homebrew 2.3.0
# Homebrew/homebrew-core (git revision 467e0; last commit 2020-06-05)
# Homebrew/homebrew-cask (git revision 8a0acb; last commit 2020-06-05)

python3 --version
# Python 3.7.3

aws --version
# aws-cli/2.0.19 Python/3.7.4 Darwin/19.5.0 botocore/2.0.0dev23

node --version
# v14.4.0

amplify --version
# Scanning for plugins...
# Plugin scan successful
# 4.22.0

pod --version
# 1.9.3
```

::alert[These commands will take a few minutes to finish.]{header="Note" type="info"}

To learn more about the tools we are instaling, you can follow the following links:

- [AWS CLI](https://docs.aws.amazon.com/en_pv/cli/latest/userguide/cli-chap-welcome.html)
- [AWS Amplify CLI](https://aws-amplify.github.io/docs/cli-toolchain/quickstart)
- [jq](https://stedolan.github.io/jq/)
- [Node.js](https://nodejs.org/en/)
- [Cocoa Pods](https://cocoapods.org/)