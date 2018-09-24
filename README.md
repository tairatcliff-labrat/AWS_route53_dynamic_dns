# AWS Route 53 with Dynamic DNS
This is a bash script that will automatically update route53 DNS records
This can be used if you don't have a static IP for your domain.

This script is specifically configured for an Ubiquity Edge Router and is installed on the Edge Router itself. 

If you don't want to run this script from the router then you can use an external source to return the external IP with the following curl commands
  curl ifconfig.me
  curl icanhazip.com
  curl ipecho.net/plain
  curl ifconfig.co


# Install Instructions

Log into the AWS console and create an IAM user with console access and restrict the user to the following route53 actions:

    {
      "Version": "2012-10-17",
      "Statement": [{
          "Sid": "Stmt1442169892000",
          "Effect": "Allow",
          "Action": ["route53:ChangeResourceRecordSets"],
          "Resource": ["arn:aws:route53:::hostedzone/{HOSTED_ZONE_ID}"]
        },
        {
          "Sid": "Stmt1442170030000",
          "Effect": "Allow",
          "Action": ["route53:GetChange"],
          "Resource": ["arn:aws:route53:::change/*"]
        }
      ]
    }

Save the IAM User Access Key ID and Secret Access Key

Install the AWS CLI on the edge router

Download the AWS CLI bundle to a computer (not directly to the router because it won't be able to unzip it)
````
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
````
Unzip the bundle and copy the files to the edge router
```    
    unzip awscli-bundle.zip
    scp -r awscli-bundle user@192.168.1.1:~
```
Copy the route53_update_dns script to the router
```
    scp route53_update_dns.sh user@192.168.1.1:/config/scripts
```
SSH to the router and install the AWS CLI
```
    cd ~/awscli-bundle
    sudo ./install -b /bin/aws
```
Check AWS CLI is installed by validating the version
```
    sudo aws --version
```    
Configure the AWS CLI and provide the IAM User Access Key ID and Secret Access Key
```
    sudo aws configure
```
Make the route53_update_dns script executable
```
    sudo chmod +x /config/scripts
```
Create a cron job or a scheduled task to execute the script at a pre-defined interval (e.g 1m, 5m, 60m)
```
    configure
    set system task-scheduler task route53_update_dns executable path /config/scripts/route53_update_dns.sh
    set system task-scheduler task route53_update_dns interval 1m
    commit
```
For the Ubiquity routers, make the changes persistent by adding the scheduled task to the config.gateway.json file and forcing a reprovision. 
