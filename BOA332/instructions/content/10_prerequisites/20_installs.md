---
title : "Installs"
chapter : false
weight : 20
---

Before we begin coding, there are a few things we need to install, update, and configure on your laptop.

### Apple Software

In order to develop native applications for iOS, you need to have [Xcode](https://apple.com/xcode) installed on your laptop.
You can download and install Xcode from [Apple's App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12).  The download is ~2Gb, so it might take up to one hour depending on your network connection.

{{% notice note %}}
This workshop requires at least [Swift 5.7](https://swift.org) and [Swift UI](https://developer.apple.com/xcode/swiftui/) framework.  These are provided by [Xcode 14](https://apple.com/xcode) or more recent.
{{% /notice %}}

### Installing or updating

You need different command line tools to be installed : `aws`, `amplify`, and `jq`.  To install and configure these, open a Terminal on your laptop and type the following commands:

{{< tabs groupId="installs" >}}
{{% tab name="Install" %}}

Follow these instructions to install the prerequisites using [HomeBrew](https://brew.sh/) package manager. 

```bash
# install brew itself
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install the AWS CLI
brew install awscli

# install the AWS Amplify CLI 
curl -sL https://aws-amplify.github.io/amplify-cli/install | bash && $SHELL

# install jq
# required to import some data into our API and
# to automate local tasks, such as cleanup
brew install jq

```
{{% /tab %}}
{{% tab name="Verify" %}}

If you already have one or several of these dependencies installed, just verify you have the latest version.  Here are the versions we tested the workshop instructions with.  Any more recent version should work as well.

```bash
brew --version
# Homebrew 3.6.1
# Homebrew/homebrew-core (git revision 796afdb1481; last commit 2022-09-16)
# Homebrew/homebrew-cask (git revision b9570a8169; last commit 2022-09-16)

aws --version
# aws-cli/2.7.31 Python/3.10.6 Darwin/21.6.0 source/arm64 prompt/off

amplify --version
# 10.2.2
```
{{% /tab %}}
{{< /tabs >}}

{{% notice note %}}
These commands will take a few minutes to finish.
{{% /notice %}}

To learn more about the tools we are instaling, you can follow the following links:

- [AWS CLI](https://docs.aws.amazon.com/en_pv/cli/latest/userguide/cli-chap-welcome.html)
- [AWS Amplify CLI](https://aws-amplify.github.io/docs/cli-toolchain/quickstart)
- [jq](https://stedolan.github.io/jq/)
