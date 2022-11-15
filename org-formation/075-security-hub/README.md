### Purpose of these templates
The templates in this folder enable
[Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html)
in each account. Amazon Security Hub provides a comprehensive view of your security state in AWS
and helps you check your environment against security industry standards and best practices.

Security Hub collects security data from across AWS accounts, services, and supported third-party
partner products and helps you analyze your security trends and identify the highest priority
security issues.

The Security Hub findings are sent to EventBridge's default event bus. Rules are defined on the event bus
to filter findings that can be suppressed and send them to an SQS queue, where a lambda will suppress them.
See https://aws.amazon.com/blogs/security/how-to-create-auto-suppression-rules-in-aws-security-hub/ for
more details.

To suppress findings, add or modify rules in the security-hub-suppress-infra.yaml template. The event pattern
for Security Hub findings is defined at https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cwe-all-findings.html.

####List of suppression rules
| rule resourcename | description |
| --- | --- |
| SecurityHubSuppressionRule1 | Suppress<br>CIS4.3: Ensure the default security group of every VPC restricts all traffic<br>CIS1.14: Ensure hardware MFA is enabled for the root account<br>in all accounts |
