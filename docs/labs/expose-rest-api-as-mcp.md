# Lab: Expose a REST API as an MCP Server

## Overview

In this hands-on lab, you'll modernize a traditional **Product Catalog REST API** into an MCP-compliant server that AI agents can discover and invoke — all governed through Azure API Management.

!!! abstract "What You'll Build"
    A complete end-to-end pipeline: **REST API → MCP Server → Container App → APIM Gateway → AI Agent**

---

## What You'll Learn

| Concept | Description |
|---------|-------------|
| :material-cog: **MCP as a modernization pattern** | How MCP enables your existing APIs to be consumed by AI agents without rewriting business logic |
| :material-shield-lock: **APIM as governance layer** | Security, monitoring, and policy enforcement for MCP traffic |
| :material-swap-horizontal: **Streamable HTTP transport** | The modern MCP transport that APIM v2 SKUs natively support |
| :material-robot: **Agent Framework integration** | How the Microsoft Agent Framework connects to MCP tools through APIM |
| :material-file-code: **Infrastructure as Code** | Full Bicep deployment for repeatable environments |

---

## What Gets Deployed

| Resource | Purpose |
|----------|---------|
| **Azure API Management (BasicV2)** | Unified gateway with native MCP support |
| **Azure Container App** | Hosts the Product Catalog MCP server (FastMCP + Starlette) |
| **Azure Container Registry** | Builds and stores the MCP server container image |
| **Azure AI Foundry** | Provides GPT-4o-mini for the Agent Framework demo |
| **Log Analytics + App Insights** | Observability for all deployed resources |

---

## MCP Tools Exposed

The Product Catalog MCP server exposes five tools that AI agents can discover and invoke:

| Tool | Description | Example Use |
|------|-------------|-------------|
| `get_categories` | List all product categories | Agent explores what's available |
| `get_products_by_category` | Get products in a category | "Show me all Electronics" |
| `get_product` | Get product details by ID | Deep-dive on a specific item |
| `search_products` | Search by name or description | "Find wireless accessories" |
| `check_stock` | Check stock availability | "Is PROD-001 in stock?" |

---

## Notebook Walkthrough

Open [`expose-rest-api-as-mcp.ipynb`](https://github.com/odaibert/api-modernization-with-mcp/blob/main/labs/expose-rest-api-as-mcp/expose-rest-api-as-mcp.ipynb) and step through each section:

| Step | What Happens | Duration |
|------|-------------|----------|
| **0️⃣ Initialize** | Set variables and generate unique resource names | ~1 min |
| **1️⃣ Verify Azure CLI** | Confirm login and subscription | ~1 min |
| **🧪 Local test** | Start MCP server locally, validate tools | ~2 min |
| **2️⃣ Deploy to Azure** | Provision all resources via Bicep | ~15 min |
| **3️⃣ Get outputs** | Retrieve URLs, keys, resource names | ~1 min |
| **4️⃣ Build & deploy** | Build container image, deploy to Container Apps | ~5 min |
| **🧪 Test via APIM** | Discover and call all 5 MCP tools through APIM | ~3 min |
| **🧪 Agent Framework** | AI agent uses MCP tools to answer questions | ~3 min |
| **🧪 VS Code integration** | Configure MCP server in Copilot Agent Mode | ~2 min |
| **🗑️ Clean up** | Delete all Azure resources | ~5 min |

!!! warning "Estimated Total Time"
    **~40 minutes** end-to-end. The APIM deployment step takes the longest (~15 minutes).

---

## Connecting MCP to Development Tools

### VS Code + GitHub Copilot Agent Mode

After deployment, add the following to your `.vscode/mcp.json`:

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

Then in Copilot chat, try:

!!! example "Copilot Agent Mode Prompts"
    - *"Search for products related to USB and check their stock"*
    - *"List all categories and show me what's in Electronics"*
    - *"Find me a wireless product and tell me if it's available"*

### MCP Inspector

Use the [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector) for interactive testing:

```bash
npx @modelcontextprotocol/inspector
```

Set transport to **Streamable HTTP** and point to your APIM MCP endpoint.

---

## The Bigger Picture

This lab demonstrates **one of two patterns** for bringing MCP to your organization through Azure API Management:

| Pattern | Description | This Lab |
|---------|-------------|----------|
| **Expose REST API as MCP** | APIM fronts a backend MCP server that wraps existing APIs | :material-check: |
| **Pass-through MCP servers** | APIM proxies and governs traffic to existing MCP servers | — |

Both patterns let you **modernize without rewriting** — your existing business logic stays the same, while gaining AI-agent accessibility, enterprise security, and centralized governance.

---

## Troubleshooting

??? question "APIM deployment is stuck or timing out"
    BasicV2 SKU deployments can take 15–20 minutes. This is normal. If it exceeds 25 minutes, check the Azure Portal for deployment status.

??? question "MCP tool calls return 401 Unauthorized"
    Verify the `api-key` header matches your APIM subscription key. Run the "Get outputs" cell in the notebook to retrieve the correct key.

??? question "Container App returns 503 Service Unavailable"
    The container may still be starting. Wait 1–2 minutes after deployment and retry. Check Container App logs in the Azure Portal.

??? question "Agent Framework demo returns empty responses"
    Ensure the AI Foundry deployment completed successfully and the GPT-4o-mini model is available. Check the Foundry project endpoint in the notebook outputs.
