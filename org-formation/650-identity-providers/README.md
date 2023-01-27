### Purpose of these templates

The templates in this folder enable OIDC for CI systems.

A common use-case is to setup [Github OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
for a more secure integration between github action and AWS.

To setup github OIDC:
1. Create a PR similar to [#688](https://github.com/Sage-Bionetworks-IT/organizations-infra/pull/688)
and have it reviewed and approved.
2. Merge the PR and the CI will deploy the cloudformation template to the specified AWS account.
3. Find the role for the OIDC integration.
Login to the AWS account then navigate
```
-> cloudformation -> find the stack named something like `Sagebase-github-oidc-*` -> outputs -> ProviderRoleArn
```

![Cloudformation ProviderRoleArn value](aws-console-oidc-provider-role.png)

4. Take the ProviderRoleArn output value and set it to `role-to-assume`
in the `configure-aws-credentials` github action.

Example:
```
  - name: Assume AWS Role
    uses: aws-actions/configure-aws-credentials@v1
    with:
      aws-region: us-east-1
      role-to-assume: arn:aws:iam::XXXXXXXX:role/sagebase-github-oidc-sage-ProviderRoleXXXXXXXX-XXXXXXXX
      role-session-name: GitHubActions-${{ github.repository_owner }}-${{ github.event.repository.name }}-${{ github.run_id }}
      role-duration-seconds: 1200
```
