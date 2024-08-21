### Purpose of these templates
The templates in this folder enable [AWS Config](https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html)
in each account. AWS Config provides a detailed view of the configuration of AWS resources in your AWS account.
This includes how the resources are related to one another and how they were configured in the past so that you
can see how the configurations and relationships change over time.

It is in that respect very similar to CloudTrail as it implements an audit trail, but not of management
actions (API calls) but of the resources within each account itself. The results are stored and updated
every hour in a centralized S3 bucket within the LogArchive account. And again, similar to CloudTrail,
that S3 bucket can be the extension point to do further analysis, notification or modification for
example with [DivvyCloud](https://divvycloud.com/key-capabilities/#unified-visibility-and-monitoring)

> Note that this stack is only the inventory and does not deploy any
  [Config Rules](https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html) or
  [Conformance Packs](https://docs.aws.amazon.com/config/latest/developerguide/conformance-packs.html),
  which would also possibly provide a lot of value for an organization, but should be deployed separately
  in another subfolder (or delegated build) depending on this one.
