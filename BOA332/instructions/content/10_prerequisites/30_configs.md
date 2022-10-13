---
title : "Configs"
chapter : false
weight : 30
---

{{% notice warning %}}
When attending this workshop during an event organised by AWS, you can choose to use a temporary account for the duration of this workshop.  If not done already, **follow [these instructions](05_event_engine.html) to access a temporary AWS account**.  Once you have access, [proceed to next section](/20_getting_started.html).
{{% /notice %}}

Now that the prerequisites are installed, let's finish the configuration.

### Configuring the aws command line

Before using `aws` command line, you need to configure a default **region** and give the **access key and secret key** of the IAM user created in [the previous step](http://localhost:1313/10_prerequisites/10_account.html).

A best practice is to deploy your infrastructure close to your customers, let's configure a default AWS Region for this workshop : Oregon (*us-west-2*) for North America or Frankfurt (*eu-central-1*) for Europe.

{{< tabs groupId="regions"  >}}
{{% tab name="North America" %}}
In the Terminal, type:

`aws configure`

(if the AWS CLI is already configured, you can create a new profile by typing `aws configure --profile workshop` )

1. At the **AWS Access Key** prompt, enter **the IAM user access key**

2. At the **AWS Secret Access Key** prompt, enter **the IAM user secret access key**

3. At the **Default region name**, enter the region close to your customers (in this workshop, we use **us-west-2** for Northern America)

4. At the Default output format, keep the defaut **None**

{{% /tab %}}

{{% tab name="Europe" %}}
In the Terminal, type:

`aws configure`

(if the AWS CLI is already configured, you can create a new profile by typing `aws configure --profile workshop` )

5. At the **AWS Access Key** prompt, enter **the IAM user access key**

6. At the **AWS Secret Access Key** prompt, enter **the IAM user secret access key**

7. At the **Default region name**, enter the region close to your customers (in this workshop, we use **eu-central-1** for Europe)

8. At the Default output format, keep the defaut **None**

{{% /tab %}}
{{< /tabs >}}

This should look like the below (actual values will vary):

![aws configure](/images/10-30-aws-config.png)