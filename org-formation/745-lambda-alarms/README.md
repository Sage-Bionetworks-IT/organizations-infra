### Purpose of these templates
Deploys an account-wide CloudWatch alarm that notifies when any Lambda function in
the account reports errors (the `AWS/Lambda` `Errors` metric with no `FunctionName`
dimension, which covers function errors and timeouts, including functions created later).

* One stack per target account and per region in `allRegions`.
* Alarms when errors are greater than 1 in each of 3 consecutive 5-minute periods.
* Notifies on ALARM and OK via a per-stack SNS topic emailing `it-alert-inbox@sagebase.org`.
* The alarm description links to the CloudWatch metrics view by function name to
  identify the failing function.

### Notes
* Each email subscription must be confirmed from the inbox after the first deploy,
  otherwise the alarm fires but no notification is delivered.
* Target accounts are listed in `_tasks.yaml` under `DefaultOrganizationBinding.Account`.
