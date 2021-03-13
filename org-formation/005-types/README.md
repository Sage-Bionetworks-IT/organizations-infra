### Purpose of these templates
There are no templates in this folder, only a tasks file. The tasks are deployments of various [Resource Types](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-types.html). The implementation of these Resource Types are currently within the scope of org-formation ([see here](https://github.com/org-formation/aws-resource-providers)) but one can also include Resource Types from other sources.

Note that the deployment of the Resource Types only makes those types available to be deployed as resources elsewhere. Many of the Resource Types deployed here are used for in `020-secure-defaults`. For details about the resource provider, consult the documentation referenced above.
