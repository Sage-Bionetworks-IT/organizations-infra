### Purpose of these stacks
The stacks created in this directory enable and improve cost-tracking capabilities.

#### Anomaly Detection
Deploy an anomaly detector service in every account in the organization, sending
email alerts to the account's root email.

#### Microservice Lambdas
A few microservices are developed and deployed as Lambdas:

* A service to provide read-only access to our MIP Chart of Accounts
* A service to generate a CloudFormation snippet based on current Chart of Accounts
* A service to send monthly per-user cloud-spend notifications via SES

#### Cost Category Template
The template in this directory creates two cost categories in AWS Cost Explorer.
