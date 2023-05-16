---
title : "Cleaning Up"
chapter : false
weight : 20
---

### Deleting via Amplify

Amplify does a pretty good job of removing the cloud resources we've provisioned for this workshop (just by attempting to delete the CloudFormation nested stacks it provisioned)

Let's amplify delete everything.  Open a Terminal and type:

```bash 
cd $PROJECT_DIRECTORY

# let amplify delete the backend infrastructure
amplify delete
```

**Wait** a few minutes while Amplify deletes all our resources.

![amplify delete](/images/80-20-amplify-delete.png)

Thank you for having followed these workshop instructions until the end.  Please let us know your feedback by opening an issue or a pull request on our [GitHub repository](https://github.com/sebsto/amplify-ios-workshop/tree/main/BOA332) or sending me a message on [Twitter](https://twitter.com/sebsto).