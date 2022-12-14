### Purpose of these templates
The templates in this folder sets up a logging infrastructure for exporting all CloudWatch logs from
multiple accounts to a single S3 bucket. These can be logs from AWS itself or applications that we
run on AWS. The (audit) trail logs are stored in a central S3 bucket in the LogArchive account, which
is in the Shared OU and therefore considered a production account. Analytics can take place based on
the logs in that S3 buckets, for example, based on [S3 notifications](https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html).

A common use-case is to do analysis on application related events, anomaly detection or forensics.


### Forwarding application logs

To forward logs from member accounts to the logcentral account follow the
[pattern used to forward the VPN logs](https://github.com/Sage-Bionetworks-IT/organizations-infra/blob/master/org-formation/730-cloudwatch-to-S3/_tasks.yaml#L39-L48).


### Acknowledgement

This design and implementation of this solution is found at [CloudSnorkel/CloudWatch2S3 project](https://github.com/CloudSnorkel/CloudWatch2S3).
