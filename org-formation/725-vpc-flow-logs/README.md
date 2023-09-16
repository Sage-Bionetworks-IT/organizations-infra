### Purpose of these templates

The templates in this folder is used to implement the
[AWS blog post](https://aws.amazon.com/blogs/mt/how-to-enable-vpc-flow-logs-automatically-using-aws-config-rules/)
to  automatically enable VPC flow logs in every VPC using
[AWS Config](https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html) rules.

The idea is to enable VPC flow logs in every VPC in our organization and send the logs to
a central S3 bucket in our AWS LogCentral account.
