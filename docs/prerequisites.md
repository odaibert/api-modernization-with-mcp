# Prerequisites

Before starting the workshop, ensure you have the following tools and access configured.

---

## Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Python** | 3.12 or later | Run the Jupyter notebook and MCP server locally |
| **VS Code** | Latest | IDE with Jupyter notebook support |
| **Azure CLI** | Latest | Deploy infrastructure and manage Azure resources |
| **Azure Subscription** | — | Host all deployed resources |

---

## Detailed Setup

### :material-language-python: Python 3.12+

Download and install from [python.org](https://www.python.org/downloads/).

```bash
python3 --version  # Should show 3.12.x or later
```

### :material-microsoft-visual-studio-code: VS Code + Extensions

1. Install [VS Code](https://code.visualstudio.com/)
2. Install the [Jupyter extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter)
3. Install the [Python extension](https://marketplace.visualstudio.com/items?itemName=ms-python.python)

### :material-microsoft-azure: Azure CLI

Install from the [official documentation](https://learn.microsoft.com/cli/azure/install-azure-cli).

```bash
az --version    # Verify installation
az login        # Sign in to your Azure account
az account show # Verify the correct subscription is selected
```

### :material-key: Azure Subscription Roles

Your account needs the following roles on the target subscription:

| Role | Why |
|------|-----|
| **Contributor** | Create and manage all Azure resources (APIM, Container Apps, ACR, AI Foundry, etc.) |
| **RBAC Administrator** | Assign managed identity roles (APIM → AI Foundry, Container App → ACR) |

!!! tip "Check your roles"

    ```bash
    az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) \
        --query "[].roleDefinitionName" -o tsv
    ```

---

## Optional Tools

| Tool | Purpose |
|------|---------|
| [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector) | Browser-based interactive testing of MCP servers |
| [GitHub Copilot](https://github.com/features/copilot) | Use MCP tools directly in VS Code Agent Mode |

---

## Verify Your Setup

Run this quick check to confirm everything is ready:

```bash
# Python
python3 --version

# Azure CLI
az version --query '"azure-cli"' -o tsv

# Logged in
az account show --query name -o tsv
```

!!! success "Ready to go!"

    If all three commands return valid output, head to [Getting Started](getting-started.md) to begin the lab.
