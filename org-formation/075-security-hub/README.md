### Purpose of these templates
The templates in this folder enable
[Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html)
in each account.  Portions of SecurityHub were setup and configured in the AWS console
because cloudformation does not support setting up in an organization configuration.
Cloudformation only supports setting up in an invitation/authorization configuration
which is not the preferred approach.  Detailed info can be found at
https://sagebionetworks.jira.com/wiki/spaces/IT/pages/3352756226/SecurityHub+Set-Up

Amazon Security Hub provides a comprehensive view of your security state in AWS
and helps you check your environment against security industry standards and best practices.

Security Hub collects security data from across AWS accounts, services, and supported third-party
partner products and helps you analyze your security trends and identify the highest priority
security issues.

The Security Hub findings are sent to EventBridge's default event bus. Rules are defined on the event bus
to filter findings that can be suppressed and send them to an SQS queue, where a lambda will suppress them.
See https://aws.amazon.com/blogs/security/how-to-create-auto-suppression-rules-in-aws-security-hub/ for
more details.

To suppress findings, add or modify rules in the
[security-hub.yaml](https://github.com/Sage-Bionetworks-IT/organizations-infra/tree/master/org-formation/075-security-hub/security-hub.yaml)
template. The event pattern for Security Hub findings is defined at
https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cwe-all-findings.html.
