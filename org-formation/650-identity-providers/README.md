### Purpose of these templates

The templates in this folder enable OIDC for CI systems.

A common use-case is to setup [Github OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
for a more secure integration between github action and AWS.

To setup github OIDC:
1. Create a PR similar to [#688](https://github.com/Sage-Bionetworks-IT/organizations-infra/pull/688)
and have it reviewed and approved. Note the following important parameters:
* DefaultOrganizationBinding - Set this to the AWS accounts that your repo will deploy to.
* ManagedPolicyArns - Allows the repo to access the AWS accounts with an AWS managed policy.
* PolicyDocument - Allows the repo to access the AWS accounts with an AWS custom policy.

  Please take care to set a [least privileged policy](https://csrc.nist.gov/glossary/term/least_privilege) for your OIDC integration.

2. Merge the PR and the CI will deploy the new resource to the AWS account(s) specified in the `DefaultOrganizationBinding` parameter.
3. Find the newly created role for the OIDC integration.

Login to the AWS account(s) specified in `DefaultOrganizationBinding` then navigate to
```
-> cloudformation -> search for a stack named something like `Sagebase-github-oidc-*` -> outputs -> ProviderRoleArn
```

![Cloudformation ProviderRoleArn value](aws-console-oidc-provider-role.png)

4. Take the ProviderRoleArn output value and set it to `role-to-assume`
in a github action to assume a role.

Example using [configure-aws-credentials GH action](https://github.com/aws-actions/configure-aws-credentials):
```
  - name: Assume AWS Role
    uses: aws-actions/configure-aws-credentials@v1
    with:
      aws-region: us-east-1
      role-to-assume: arn:aws:iam::XXXXXXXX:role/sagebase-github-oidc-sage-ProviderRoleXXXXXXXX-XXXXXXXX
      role-session-name: GitHubActions-${{ github.repository_owner }}-${{ github.event.repository.name }}-${{ github.run_id }}
      role-duration-seconds: 1200
```
