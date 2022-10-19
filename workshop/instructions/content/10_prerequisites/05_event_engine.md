---
title : "AWS Temporary Account"
chapter : false
weight : 1
---

When attending this workshop during an event organised by AWS, such as [AWS re:Invent](https://reinvent.awsevents.com/), you may choose to use one of AWS' temporary AWS Account instead of using your personal or company AWS account.  Follow the instructions from this page and the AWS instructor in the room to access the temporary account.

{{% notice warning %}}
Should you attend this workshop on your own or in a non-AWS event, you can skip this section and [proceed to next section](/10_prerequisites/10_iam_user.html#aws-account).
{{% /notice %}}

## Access AWS Workshop Studio

1. Open your browser and navigate to [https://catalog.workshops.aws/join](https://catalog.workshops.aws/join).

2. Authenticate using one the proposed authentication mechanisms.
![authenticate](/images/10-05-authenticate.png)

3. Enter the event access code and select **Next** (your instructor will give you the event access code).
![hash code](/images/10-05-hashcode.png)

4. Read and accept the terms and conditions. Select **I agree with the Terms and Conditions** select **Join event**.
![terms and conditions](/images/10-05-terms.png)

The screen below has all the information you need to run the workshop
![start](/images/10-05-start.png)

5. Select **Get Started** on the right side to access workshop instructions.
![workshop](/images/10-05-workshop.png)

6. Select **Get AWS CLI Credentials** on the bottom left side to receive the AWS credentials you will use to access the AWS temporary account.
![credentials](/images/10-05-credentials.png)


7. Copy and paste the CLI credentials.  You will need these values thorough the workshop. Open a Terminal on your laptop and execute the set of `export` commands you copied from the event engine page:

```bash
# this is a copy paste from event engine console

# !! PASTE THE LINES FROM AWS EVENT ENGINE PAGE !!

export AWS_ACCESS_KEY_ID="AS (redacted) 6B"
export AWS_SECRET_ACCESS_KEY="pR (redacted) qr"
export AWS_SESSION_TOKEN="IQ (redacted) e94="
```

8. Finally, execute the following script to finish setting up your environment. 

```bash
# adjust region as desired 
export AWS_DEFAULT_REGION=us-west-2

# This will create an AWS CLI profile for this workshop
# IF YOU ALREADY HAVE A PROFILE NAMED "WORKSHOP" => CHOOSE ANOTHER NAME !

# AFTER EXECUTING THE LINES COPIED FROM EVENT ENGINE, EXECUTE THE LINES BELOW

mkdir ~/.aws &>/dev/null # harmless when the directory already exists
echo >> ~/.aws/config
echo "[workshop]"  >> ~/.aws/config
echo "region=$AWS_DEFAULT_REGION"  >> ~/.aws/config
echo >> ~/.aws/credentials
echo "[workshop]"  >> ~/.aws/credentials
echo "aws_access_key_id = $AWS_ACCESS_KEY_ID"  >> ~/.aws/credentials
echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY"  >> ~/.aws/credentials
echo "aws_session_token = $AWS_SESSION_TOKEN"  >> ~/.aws/credentials

# unset env variables to ensure CLI will use values from the profile.
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
```

9. Finally, select the **Open AWS Console** link on the bottom left side to open the AWS Console.  You can also copy the login link in case you want to return to the console later.

Now that you have an AWS Account and a pair of Access Key / Secret Key, let's proceed to [the installation of development tools on your local machine](/10_prerequisites/20_installs.html).