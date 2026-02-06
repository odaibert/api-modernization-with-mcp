# Modernize Your APIs for the AI Agent Era

## Expose a REST API as an MCP Server through Azure API Management

> *"Your APIs are becoming tools. Your users are becoming agents. Your platform needs to adapt."*
> — [Azure API Management now supports MCP](https://techcommunity.microsoft.com/blog/integrationsonazureblog/%F0%9F%9A%80-new-in-azure-api-management-mcp-in-v2-skus--external-mcp-compliant-server-sup/4440294)

---

## Why This Matters

The [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) is an open standard that lets AI agents discover and invoke tools — turning your REST APIs into first-class capabilities for large language models. Instead of writing custom glue code for every agent framework, you wrap your API once and every MCP-compatible client can use it.

**Azure API Management** acts as a **single, secure control plane** for exposing and governing these MCP capabilities. No new infrastructure. Secure by default. Built for the future.

This lab walks you through modernizing a traditional REST API — a **Product Catalog** service — into an MCP-compliant server that AI agents can discover and invoke, all governed through Azure API Management.

## What You'll Learn

| Concept | Description |
|---------|-------------|
| **MCP as a modernization pattern** | How MCP enables your existing APIs to be consumed by AI agents without rewriting business logic |
| **APIM as the governance layer** | How Azure API Management provides security, monitoring, and policy enforcement for MCP traffic |
| **Streamable HTTP transport** | The modern MCP transport that APIM v2 SKUs natively support |
| **Agent Framework integration** | How the [Microsoft Agent Framework](https://github.com/microsoft/agent-framework) connects to MCP tools through APIM |
| **Infrastructure as Code** | Full Bicep deployment for repeatable, production-like environments |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Azure Resource Group                          │
│                                                                        │
│  ┌──────────────┐    ┌────────────────────┐    ┌────────────────────┐  │
│  │  AI Foundry   │    │   Azure API Mgmt   │    │  Container App     │  │
│  │  (GPT-4o-mini)│    │   (v2 / BasicV2)   │    │  Product Catalog   │  │
│  │               │◄───┤                    │───►│  MCP Server        │  │
│  │  Inference    │    │  • MCP API (native) │    │  (FastMCP +        │  │
│  │  API          │    │  • Inference API    │    │   Starlette)       │  │
│  └──────────────┘    │  • Subscriptions    │    └────────────────────┘  │
│                       │  • Policies         │                           │
│                       └────────────────────┘                           │
│                              ▲                                         │
│  ┌──────────────┐           │            ┌────────────────────┐       │
│  │ Log Analytics │           │            │ Container Registry │       │
│  │ + App Insights│           │            │ (ACR)              │       │
│  └──────────────┘           │            └────────────────────┘       │
│                              │                                         │
└──────────────────────────────┼─────────────────────────────────────────┘
                               │
               ┌───────────────┼───────────────┐
               │               │               │
        ┌──────┴──────┐ ┌─────┴─────┐ ┌──────┴──────┐
        │  Agent       │ │  VS Code   │ │  MCP        │
        │  Framework   │ │  Copilot   │ │  Inspector  │
        │  (Python)    │ │  Agent Mode│ │  (Browser)  │
        └─────────────┘ └───────────┘ └─────────────┘
```

**Data flow:** MCP clients (Agent Framework, VS Code, Inspector) connect to APIM via Streamable HTTP → APIM authenticates, applies policies, and routes to the backend Container App → the MCP server exposes REST API capabilities as discoverable tools.

## What Gets Deployed

| Resource | Purpose |
|----------|---------|
| **Azure API Management (BasicV2 SKU)** | Unified gateway with native MCP support — handles authentication, rate limiting, and monitoring for both MCP and inference traffic |
| **Azure Container App** | Hosts the Product Catalog MCP server (FastMCP + Starlette over Streamable HTTP) |
| **Azure Container Registry** | Builds and stores the MCP server container image |
| **Azure AI Foundry** | Provides GPT-4o-mini for the Agent Framework demo |
| **Log Analytics + Application Insights** | Observability and monitoring for all deployed resources |

## MCP Tools Exposed

The Product Catalog MCP server exposes five tools that AI agents can discover and invoke:

| Tool | Description | Example Use |
|------|-------------|-------------|
| `get_categories` | List all product categories | Agent explores what's available |
| `get_products_by_category` | Get products in a given category | "Show me all Electronics" |
| `get_product` | Get product details by ID | Deep-dive on a specific item |
| `search_products` | Search products by name or description | "Find wireless accessories" |
| `check_stock` | Check stock availability by product ID | "Is PROD-001 in stock?" |

## Why Azure API Management for MCP?

APIM brings **enterprise-grade governance** to your MCP endpoints — the same way it governs your REST, GraphQL, and WebSocket APIs today:

- 🔐 **Security** — OAuth 2.0, Microsoft Entra ID, API keys, and JWT validation out of the box
- 📊 **Monitoring** — Full observability through Azure Monitor and Application Insights
- 🔍 **Discovery** — Publish MCP tools to Azure API Center for organization-wide discovery
- ⚙️ **Policy engine** — Rate limiting, caching, transformation, and custom policies on MCP traffic
- 🌐 **Unified control plane** — Manage MCP alongside your existing APIs in one place

## Prerequisites

- [Python 3.12 or later](https://www.python.org/) installed
- [VS Code](https://code.visualstudio.com/) with the [Jupyter extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter)
- [An Azure Subscription](https://azure.microsoft.com/free/) with **Contributor** and **RBAC Administrator** roles
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and signed in (`az login`)

## 🚀 Getting Started

1. **Clone and open** the repo in VS Code
2. **Open the notebook**: [`expose-rest-api-as-mcp.ipynb`](expose-rest-api-as-mcp.ipynb)
3. **Click `Run All`** or step through each cell

The notebook will:

| Step | What Happens |
|------|-------------|
| **0️⃣ Initialize** | Set variables and generate unique resource names for this run |
| **1️⃣ Verify Azure CLI** | Confirm you're logged in and have the right subscription |
| **🧪 Local test** | Start the MCP server locally and validate tools are discoverable |
| **2️⃣ Deploy to Azure** | Provision all resources via Bicep (APIM, Container App, AI Foundry, etc.) |
| **3️⃣ Get outputs** | Retrieve deployment outputs (URLs, keys, resource names) |
| **4️⃣ Build & deploy** | Build the container image and deploy to Container Apps |
| **🧪 Test tools via APIM** | Discover and call all 5 MCP tools through the APIM gateway |
| **🧪 Agent Framework** | Run an AI agent that uses MCP tools through APIM to answer questions |
| **🧪 VS Code integration** | Configure the MCP server in GitHub Copilot Agent Mode |
| **🗑️ Clean up** | Delete all Azure resources created during the lab |

## Connecting MCP to Your Development Tools

### VS Code + GitHub Copilot Agent Mode

Add the following to your `.vscode/mcp.json`:

```json
{
    "servers": {
        "product-catalog": {
            "type": "http",
            "url": "<your-apim-gateway-url>/product-catalog/mcp"
        }
    }
}
```

Then in Copilot chat, try: *"Search for products related to USB and check their stock"*

### MCP Inspector

Use the [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector) for interactive testing:

```bash
npx @modelcontextprotocol/inspector
```

Set transport to **Streamable HTTP** and point to your APIM MCP endpoint.

## The Bigger Picture: API Modernization with MCP

This lab demonstrates **one of two patterns** for bringing MCP to your organization through Azure API Management:

| Pattern | Description | This Lab |
|---------|-------------|----------|
| **Expose REST API as MCP** | APIM sits in front of a backend MCP server that wraps your existing APIs | ✅ |
| **Pass-through existing MCP servers** | APIM proxies and governs traffic to MCP servers already in production | — |

Both patterns let you **modernize without rewriting** — your existing business logic stays the same, while gaining AI-agent accessibility, enterprise security, and centralized governance.

## References

- 📝 [Blog: Azure API Management now supports MCP](https://techcommunity.microsoft.com/blog/integrationsonazureblog/%F0%9F%9A%80-new-in-azure-api-management-mcp-in-v2-skus--external-mcp-compliant-server-sup/4440294)
- 📖 [Expose APIs as MCP servers in Azure API Management](https://learn.microsoft.com/azure/api-management/expose-mcp-server)
- 📖 [Connect to external MCP-compliant servers](https://learn.microsoft.com/azure/api-management/connect-mcp-server)
- 🔐 [Secure access to MCP servers](https://learn.microsoft.com/azure/api-management/secure-mcp-server)
- 🔍 [Discover MCP tools in Azure API Center](https://learn.microsoft.com/azure/api-center/discover-mcp-tools)
- 🤖 [Microsoft Agent Framework](https://github.com/microsoft/agent-framework)
- 🌐 [Model Context Protocol specification](https://modelcontextprotocol.io/)
- 🏗️ [Azure-Samples/AI-Gateway](https://github.com/Azure-Samples/AI-Gateway)

---

> **Ready to modernize?** Open the [notebook](expose-rest-api-as-mcp.ipynb) and turn your REST API into tools that AI agents can use — governed, secure, and enterprise-ready.
