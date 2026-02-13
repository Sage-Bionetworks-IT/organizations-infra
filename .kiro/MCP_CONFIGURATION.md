# MCP Server Configuration Documentation

## Overview

This document describes the Model Context Protocol (MCP) server configuration for the organizations-infra project. MCP servers extend Kiro's capabilities by providing specialized tools and integrations for AWS infrastructure management.

## Configuration Location

- **File**: `.kiro/settings/mcp.json`
- **Scope**: Workspace-level configuration
- **Format**: JSON

## Installed MCP Servers

### 1. AWS Knowledge (`aws-knowledge-mcp-server`)

**Purpose**: AWS regional availability, service information, and knowledge base access via HTTP.

**Configuration**:
```json
{
  "url": "https://knowledge-mcp.global.api.aws",
  "type": "http",
  "disabled": false
}
```

**Capabilities**:
- Get AWS regional availability for products, APIs, and CloudFormation resources
- List all AWS regions
- Access AWS knowledge base information
- Check service and feature availability across regions

**Connection Type**: HTTP (no local installation required)

**Status**: ✅ Enabled

---

### 2. AWS Documentation (`aws-docs`)

**Purpose**: Search and retrieve AWS documentation directly within Kiro.

**Configuration**:
```json
{
  "command": "uvx",
  "args": ["awslabs.aws-documentation-mcp-server@latest"],
  "env": {
    "FASTMCP_LOG_LEVEL": "ERROR",
    "AWS_DOCUMENTATION_PARTITION": "aws"
  },
  "autoApprove": ["search_documentation"],
  "disabled": false
}
```

**Capabilities**:
- Search AWS documentation
- Read AWS documentation pages
- Get recommendations for related docs
- Access to latest AWS service documentation

**Auto-Approved Tools**:
- `search_documentation` - Automatically approved for seamless doc searches

**Status**: ✅ Enabled

---

### 3. AWS Pricing (`aws-pricing-mcp-server`)

**Purpose**: Query AWS pricing information and perform cost analysis.

**Configuration**:
```json
{
  "command": "uvx",
  "args": ["awslabs.aws-pricing-mcp-server@latest"],
  "env": {
    "FASTMCP_LOG_LEVEL": "ERROR"
  }
}
```

**Capabilities**:
- Get pricing for AWS services
- Compare costs across regions
- Analyze infrastructure costs
- Generate cost reports
- Query pricing attributes and values

**AWS Configuration**:
- No AWS credentials required (uses public pricing API)

**Status**: ✅ Enabled

---

### 4. AWS IaC (`aws-iac-mcp-server`)

**Purpose**: Infrastructure as Code validation and troubleshooting for CloudFormation and CDK.

**Configuration**:
```json
{
  "command": "uvx",
  "args": ["awslabs.aws-iac-mcp-server@latest"],
  "env": {
    "FASTMCP_LOG_LEVEL": "ERROR"
  }
}
```

**Capabilities**:
- Validate CloudFormation templates (syntax and compliance)
- Troubleshoot CloudFormation deployment failures
- Search CDK and CloudFormation documentation
- CDK best practices guidance
- Pre-deployment validation

**AWS Configuration**:
- Uses default AWS credentials from environment

**Status**: ✅ Enabled

---

### 5. AWS Diagram (`aws-diagram-mcp-server`)

**Purpose**: Generate architecture diagrams from code using the Python diagrams library.

**Configuration**:
```json
{
  "command": "uvx",
  "args": ["awslabs.aws-diagram-mcp-server@latest"],
  "env": {
    "FASTMCP_LOG_LEVEL": "ERROR"
  }
}
```

**Capabilities**:
- Generate AWS architecture diagrams
- Create infrastructure visualizations
- List available diagram icons
- Get diagram examples
- Support for multiple cloud providers

**AWS Configuration**:
- No AWS credentials required

**Requirements**:
- Graphviz must be installed on the system

**Output Location**:
- Diagrams are saved to `generated-diagrams/` folder in workspace

**Status**: ✅ Enabled

---

### 6. AWS CloudFormation (`aws-cfn-mcp-server`)

**Purpose**: Direct CloudFormation resource management and operations.

**Configuration**:
```json
{
  "command": "uvx",
  "args": ["awslabs.cfn-mcp-server@latest"]
}
```

**Capabilities**:
- Get CloudFormation resource schema information
- List AWS resources of a specified type
- Get details of specific AWS resources
- Create, update, and delete AWS resources
- Track long-running operations
- Generate CloudFormation templates from existing resources (IaC Generator)

**AWS Configuration**:
- Uses default AWS credentials from environment
- Requires appropriate IAM permissions for resource operations

**Status**: ✅ Enabled

---

### 7. Filesystem (`filesystem`)

**Purpose**: File system operations within the workspace.

**Configuration**:
```json
{
  "command": "npx",
  "args": [
    "@modelcontextprotocol/server-filesystem",
    "."
  ]
}
```

**Capabilities**:
- Read files and directories
- Write and edit files
- Search files
- File metadata operations
- Directory tree operations

**Scope**: Current workspace directory (`.`)

**Status**: ✅ Enabled

---

## Environment Variables

### Common Settings

**FASTMCP_LOG_LEVEL**: `ERROR`
- Suppresses verbose logging from MCP servers
- Only shows error-level messages
- Keeps the interface clean

### AWS-Specific Settings

Most AWS MCP servers now use default AWS credentials from your environment rather than explicit profile/region configuration. This provides more flexibility and follows AWS SDK best practices.

**AWS Credentials**: Automatically detected from:
1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
2. AWS credentials file (`~/.aws/credentials`)
3. IAM role (if running on EC2/ECS/Lambda)
4. AWS SSO

**AWS_DOCUMENTATION_PARTITION**: `aws` (for aws-docs server)
- Standard AWS partition (not GovCloud or China)

---

## Prerequisites

### Required Software

1. **uv/uvx** - Python package manager
   - Install: `curl -LsSf https://astral.sh/uv/install.sh | sh`
   - Or via pip: `pip install uv`

2. **Node.js and npm** - For filesystem server
   - Install from: https://nodejs.org/

3. **AWS CLI** - For AWS credential management
   - Install: https://aws.amazon.com/cli/
   - Configure: `aws configure`

4. **Graphviz** (optional, for diagrams)
   - macOS: `brew install graphviz`
   - Ubuntu: `apt-get install graphviz`

### AWS Credentials

Ensure your AWS credentials are configured:

```bash
# Check if credentials exist
aws sts get-caller-identity

# If not configured, run:
aws configure
```

---

## Usage Examples

### Checking Regional Availability
```
"Is Lambda available in eu-south-2 region?"
"Check if CloudFormation resource AWS::Lambda::Function is available in ap-southeast-3"
```

### Searching AWS Documentation
```
"Search AWS documentation for Transit Gateway pricing"
```

### Getting Pricing Information
```
"How much does a Transit Gateway attachment cost per month?"
```

### Validating CloudFormation
```
"Validate this CloudFormation template for syntax errors"
```

### Generating Diagrams
```
"Draw a diagram for this CloudFormation template"
```

### CDK Guidance
```
"What are the best practices for CDK stack organization?"
```

### Managing CloudFormation Resources
```
"List all S3 buckets in my account"
"Get details for S3 bucket my-bucket-name"
"Create an S3 bucket with encryption enabled"
```

---

## Troubleshooting

### MCP Server Not Connecting

1. **Check if uvx is installed**:
   ```bash
   uvx --version
   ```

2. **Verify AWS credentials**:
   ```bash
   aws sts get-caller-identity --profile default
   ```

3. **Check MCP server logs**:
   - Look in Kiro's MCP Server view
   - Check for connection errors

### AWS Credential Errors

If you see AWS credential-related errors:

1. **Check your AWS credentials**:
   ```bash
   aws sts get-caller-identity
   ```

2. **Configure credentials if needed**:
   ```bash
   aws configure
   ```

3. **Or use environment variables**:
   ```bash
   export AWS_ACCESS_KEY_ID=your_access_key
   export AWS_SECRET_ACCESS_KEY=your_secret_key
   export AWS_DEFAULT_REGION=us-east-1
   ```

4. **For AWS SSO**:
   ```bash
   aws sso login --profile your-profile
   export AWS_PROFILE=your-profile
   ```

### Diagram Generation Fails

If diagrams fail with "Graphviz executables not found":

```bash
# macOS
brew install graphviz

# Ubuntu/Debian
sudo apt-get install graphviz

# Verify installation
dot -V
```

---

## Customization

### Using AWS SSO or Named Profiles

If you need to use a specific AWS profile, set it as an environment variable before starting Kiro:

```bash
export AWS_PROFILE=your-profile-name
```

Or add it to your shell configuration (~/.zshrc, ~/.bashrc):

```bash
echo 'export AWS_PROFILE=your-profile-name' >> ~/.zshrc
```

### Changing Default Region

Set the AWS region via environment variable:

```bash
export AWS_DEFAULT_REGION=us-west-2
```

### Disabling a Server

Add `"disabled": true` to any server configuration:

```json
"aws-diagram-mcp-server": {
  "command": "uvx",
  "args": ["awslabs.aws-diagram-mcp-server@latest"],
  "disabled": true
}
```

### Auto-Approving Tools

To skip approval prompts for specific tools, add an `autoApprove` array:

```json
"autoApprove": ["tool_name_1", "tool_name_2"]
```

---

## Maintenance

### Updating MCP Servers

MCP servers are configured to use `@latest`, so they auto-update. To force an update:

```bash
# Clear uvx cache
uvx cache clean

# Or manually update
uvx --refresh awslabs.aws-pricing-mcp-server@latest
```

### Viewing Active Servers

In Kiro:
1. Open the MCP Server view in the sidebar
2. Check connection status for each server
3. View logs for troubleshooting

---

## Security Considerations

1. **AWS Credentials**: MCP servers use your local AWS credentials
   - Never commit credentials to version control
   - Use IAM roles with least privilege
   - Rotate access keys regularly
   - Consider using AWS SSO for better security

2. **Auto-Approve**: Use cautiously
   - Only auto-approve read-only operations
   - Review tool permissions before enabling

3. **Workspace Access**: Filesystem server has access to workspace files
   - Ensure sensitive data is not in the workspace
   - Use `.gitignore` for secrets
   - Generated diagrams are saved to `generated-diagrams/` (excluded from git)

4. **CloudFormation Operations**: aws-cfn-mcp-server can create/modify/delete resources
   - Review operations carefully before approval
   - Ensure you have appropriate IAM permissions
   - Test in non-production environments first

---

## Support and Resources

- **MCP Documentation**: https://modelcontextprotocol.io/
- **AWS Labs MCP Servers**: https://github.com/awslabs/
- **Kiro Documentation**: Check Kiro's help menu
- **AWS Documentation**: https://docs.aws.amazon.com/

---

## Version Information

- **Configuration Version**: 1.0
- **Last Updated**: 2025
- **MCP Servers**: Using `@latest` versions (auto-update)
