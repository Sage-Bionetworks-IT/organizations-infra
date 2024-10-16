## Purpose of these templates
The templates in this folder enable
[AWS Systems Manager](https://aws.amazon.com/systems-manager/)
in each account. Amazon Systems Manager is a secure end-to-end management solution for AWS cloud environments.
It is the operations hub for your AWS applications and resources, and is broken into four core feature groups:
* Operations Management
* Application Management
* Change Management
* Node Management

### Patch Manager

We have setup a centralized multi-account patch management system
with AWS Systems Manager.  The templates for this setup are found in
the [aws-samples repo](https://github.com/aws-samples/aws-systems-manager-schedule-central-patch-example)
which is referenced from the
[AWS cloud operations and migrations blog](https://aws.amazon.com/blogs/mt/scheduling-centralized-multi-account-multi-region-patching-aws-systems-manager-automation/)


### Script Execution

This folder contain the automation required to run a given script on appropriately tagged EC2 instances on a schedule.
Its primary application is to run the script that installs the Stack Armor monitoring agent on a set of target EC2s
but it's general enough that it can be used to run other scripts on other machines.  It allows passing in script
parameters as key-value pairs.  In each pair the 'value' is the name of a secure SSM parameter which is then 
retrieved, paired with the key and passed along to the script as an environment variable. E.g., if we pass in "foo:/my/param"
and if SSM parameter store contains the secure, encrypted value "bar" for the parameter named "/my/param", then the environment
variable "foo=bar" will be passed along to the script.

WARNING: This automation depends upon EC2 instances being appropriately tagged and will not work if the tags
are absent. A likely approach is to specify the tags in the CloudFormation template that deploys the target instances.

### Deployments

The templates for setting up the AWS system manager are deployed
using org-formation.
