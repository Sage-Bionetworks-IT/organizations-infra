# MCP Server Configuration Documentation

## Overview

This document describes the Model Context Protocol (MCP) server configuration for the organizations-infra project. MCP servers extend Kiro's capabilities by providing specialized tools and integrations for AWS infrastructure management.

## Configuration Location

- **File**: `.kiro/settings/mcp.json`
- **Scope**: Workspace-level configuration
- **Format**: JSON

## Installed MCP Servers

### 1. AWS Core (`aws-core`)

**Purpose**: Core AWS functionality and prompt understanding for AWS-related queries.

**Configuration**:
```json
{
  "command": "uvx",
  "args": ["awslabs.core-mcp-server@latest"],
  "env": {
    "FASTMCP_LOG_LEVEL": "ERROR"
  },
  "disabled": false
}
```

**Capabilities**:
- AWS prompt understanding and translation
- Core AWS service guidance
- General AWS best practices

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
    "FASTMCP_LOG_LEVEL": "ERROR",
    "AWS_PROFILE": "default",
    "AWS_REGION": "us-east-1"
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
- Profile: `default`
- Region: `us-east-1`

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
    "FASTMCP_LOG_LEVEL": "ERROR",
    "AWS_PROFILE": "default",
    "AWS_REGION": "us-east-1"
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
- Profile: `default`
- Region: `us-east-1`

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
    "FASTMCP_LOG_LEVEL": "ERROR",
    "AWS_PROFILE": "default",
    "AWS_REGION": "us-east-1"
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
- Profile: `default`
- Region: `us-east-1`

**Requirements**:
- Graphviz must be installed on the system

**Status**: ✅ Enabled

---

### 6. AWS CDK (`aws-cdk-mcp-server`)

**Purpose**: AWS CDK-specific guidance, patterns, and best practices.

**Configuration**:
```json
{
  "command": "uvx",
  "args": ["awslabs.cdk-mcp-server@latest"],
  "env": {
    "FASTMCP_LOG_LEVEL": "ERROR",
    "AWS_PROFILE": "default",
    "AWS_REGION": "us-east-1"
  }
}
```

**Capabilities**:
- CDK general guidance and best practices
- CDK Nag rule explanations
- AWS Solutions Constructs patterns
- GenAI CDK constructs
- Lambda layer documentation

**AWS Configuration**:
- Profile: `default`
- Region: `us-east-1`

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

**AWS_PROFILE**: `default`
- Uses the default AWS CLI profile
- Ensure your `~/.aws/credentials` file has a `[default]` profile configured

**AWS_REGION**: `us-east-1`
- Default region for AWS operations
- Can be overridden by specific tool calls

**AWS_DOCUMENTATION_PARTITION**: `aws`
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

If you see "config profile (default) could not be found":

1. Run `aws configure` to set up credentials
2. Or specify a different profile in the MCP config:
   ```json
   "AWS_PROFILE": "your-profile-name"
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

### Changing AWS Profile

Edit `.kiro/settings/mcp.json` and update the `AWS_PROFILE` value:

```json
"env": {
  "AWS_PROFILE": "your-profile-name",
  "AWS_REGION": "us-east-1"
}
```

### Changing Default Region

Update the `AWS_REGION` value:

```json
"env": {
  "AWS_REGION": "us-west-2"
}
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

2. **Auto-Approve**: Use cautiously
   - Only auto-approve read-only operations
   - Review tool permissions before enabling

3. **Workspace Access**: Filesystem server has access to workspace files
   - Ensure sensitive data is not in the workspace
   - Use `.gitignore` for secrets

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
