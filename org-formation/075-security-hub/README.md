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

#### Adding rules or conditions to suppress findings
To suppress findings, add or modify rules in the [security-hub-suppress-infra.yaml](https://github.com/Sage-Bionetworks-IT/organizations-infra/tree/master/org-formation/075-security-hub/security-hub-suppress-infra.yaml) template. Rules are created as required by their use case (e.g. SuppressFindingsInAllAccountsRule covers the case where findings (identified by generatorId) are suppressed accross all accounts). Each rule is preceded by a comment describing its use case.
The information (AccountId, GeneratorId and ResourceIds) necessary to either add conditions to an existing rule or to create a new rule are in the JIRA issue created from findings.

The event pattern for Security Hub findings is defined at https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cwe-all-findings.html.
