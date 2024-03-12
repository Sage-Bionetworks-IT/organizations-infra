### Purpose of these templates
The templates in this folder sets up a cross account CloudWatch monitoring dashboard.
It uses a management/member architecture, instead of using the Organizations account
as the cloudwatch management account we created org-sagebase-monitorcentral account
for that purpose.  Creating a separate account will allow us to isolate user access
to the dashboards.

* The Cloudwatch management account is org-sagebase-monitorcentral
* The monitorcentral account uses the AWS account list from the Organizations account.
  This will allow monitorcentral to include new AWS accounts as they are added.
* All other AWS accounts are Cloudwatch member accounts.
