### Purpose of these templates
Deploys an account-wide CloudWatch alarm that notifies when any Lambda function in
the account reports errors (the `AWS/Lambda` `Errors` metric with no `FunctionName`
dimension, which covers function errors and timeouts, including functions created later).

* One stack per target account and per region in `allRegions`.
* Alarms on the first error (errors > 0 in a 5-minute period), so infrequent lambdas
  (e.g. weekly/monthly finops jobs) are covered as well as frequent ones.
* Notifies on ALARM only (no OK notification, since infrequent lambdas return to OK on
  missing data alone) via a per-stack SNS topic emailing `it-alert-inbox@sagebase.org`.
* Notifications are sent on state change: a function that keeps failing stays in ALARM
  and sends one email; a new email is sent only after the alarm has returned to OK.
* The alarm description links to the CloudWatch metrics view by function name to
  identify the failing function.

### Notes
* Each email subscription must be confirmed from the inbox after the first deploy,
  otherwise the alarm fires but no notification is delivered.
* Target accounts are listed in `_tasks.yaml` under `DefaultOrganizationBinding.Account`.
