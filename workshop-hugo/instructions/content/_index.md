---
title: "Build an iOS Native App with a Cloud-Based Backend"
chapter: true
weight: 0
---

# Build an iOS App using a cloud-based backend

## Welcome!

By following the instructions from this workshop, you will create a data-driven native iOS app, integrated with a cloud-based backend.  We will use [Amazon Cognito](http://aws.amazon.com/cognito) to manage user authentication and we'll use [AWS AppSync](https://aws.amazon.com/appsync/) to get up and running quickly with a [GraphQL API](https://graphql.org/learn/) that backs our data in [Amazon DynamoDB](https://aws.amazon.com/dynamodb/). We'll demonstrate how to use the [AWS Amplify](https://aws.amazon.com/amplify/) library to authenticate users, to communicate with our API, and to download images from [Amazon S3](https://aws.amazon.com/s3/).

{{% notice info %}}
This guide assumes that you are familiar with iOS development and tools. If you are new to iOS development, you can follow [these steps](https://developer.apple.com/tutorials/SwiftUI) to create your first iOS application using Swift.
{{% /notice %}}

### Estimated run time

This workshop takes about 2h to 3h to complete.

### Learning Objectives

The main learning objective of this workshop is to let you discover how to take advantage of a secure, fully managed, scalable cloud backend for your iOS applications.  

We divided this workshop in three parts :

- In the first part ([section 3](30_add_authentication.html)) you will learn how to add a user authentication flow to your application.  In real life, multiple flows are required to support user authentication : SignIn, SignUp, Forgot Password, Email / Phone number verification etc. We are going to implement all of them with just a few lines of code.

- In the second part ([section 4](40_add_api.html) and [section 5](50_add_images.html)) you will learn how to deploy and call an API from your mobile application.

- Finally, you will learn how to add Identity Federation for your login screen (also known as "Sign in with Apple") ([section 6](60_add_federation.html)) and to create your own authentication user interface ([section 7](70_add_custom_gui.html)).

### Audience

This workshop assumes you are familiar with iOS development and tools: Xcode, the Swift programing language, and typing commands in the Terminal.

This workshop can be completed just with copy / paste - it is not required to type code or even to understand the code you copy/paste to follow instructions. However, familiarity with code will help you to get the most out of this workshop.

### Costs

This workshop runs entirely on the AWS Free Tier.  When following up workshop instructions on a new AWS Account, you are not charged for any costs.  When your AWS account is older than 12 months, you only pay for AWS AppSync and Amazon S3 storage.

Here is a breakdown of the costs for AWS Accounts older than 12 months:

- AppSync : $4.00 per million Query and Data Modification Operations

- Cognito : Free up to 50k monthly active user per month 

- DynamoDB : Free up to 25 units of read capacity, 25 units of write capacity, and 25Gb of storage. This is enough to handle up to 200M requests per month.

- Lambda : Free up to 1 million invocations and up to 3.2 million seconds (889 hours) of compute time per month

- S3 : $0.023 per GB. The workshop stores ~3Mb of images. Expected storage cost is $0.00007 / month + $0.0004 per 1000 GET requests + $0.09 / Gb of data transfer.