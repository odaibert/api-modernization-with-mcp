# :rocket: Modernize Your APIs for the AI Agent Era

## Expose REST APIs as MCP Servers through Azure API Management

> *"Your APIs are becoming tools. Your users are becoming agents. Your platform needs to adapt."*
> — [Azure API Management now supports MCP](https://techcommunity.microsoft.com/blog/integrationsonazureblog/%F0%9F%9A%80-new-in-azure-api-management-mcp-in-v2-skus--external-mcp-compliant-server-sup/4440294)

---

## About This Workshop

The [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) is an open standard that turns your APIs into **tools** that AI agents can discover, understand, and invoke. Instead of writing custom glue code for every agent framework, you wrap your API once and every MCP-compatible client can use it.

**Azure API Management** acts as a **single, secure control plane** for exposing and governing these MCP capabilities. No new infrastructure. Secure by default. Built for the future.

This workshop walks you through modernizing a traditional REST API — a **Product Catalog** service — into an MCP-compliant server that AI agents can discover and invoke, all governed through Azure API Management.

!!! info "What Makes This Workshop Unique"

    :material-wrench: **Learn by Building** — Deploy real Azure infrastructure, not simulated environments

    :material-shield-lock: **Enterprise-Grade Security** — API keys, managed identity, RBAC — all wired up from the start

    :material-robot: **Agent-Ready** — Test with Microsoft Agent Framework, VS Code Copilot, and MCP Inspector

    :material-code-braces: **Infrastructure as Code** — Full Bicep deployment you can adapt for production

    :material-notebook: **Interactive Notebook** — Step through at your own pace with a Jupyter notebook

---

## The Modernization Journey

Your journey follows a step-by-step progression. Each stage builds on the last, from local validation to a fully governed MCP endpoint with AI agent orchestration.

<div class="grid cards" markdown>

-   :material-cog:{ .lg .middle } **Step 0: Initialize**

    ---

    Set variables and generate unique resource names for isolated, repeatable runs

-   :material-check-circle:{ .lg .middle } **Step 1: Verify Azure CLI**

    ---

    Confirm you're logged in with the right subscription and permissions

-   :material-test-tube:{ .lg .middle } **Local Test: Validate MCP Server**

    ---

    Start the MCP server locally and verify all 5 tools are discoverable before deploying

-   :material-rocket-launch:{ .lg .middle } **Step 2: Deploy to Azure**

    ---

    Provision APIM, Container Apps, AI Foundry, and monitoring via Bicep

-   :material-download:{ .lg .middle } **Step 3: Get Outputs**

    ---

    Retrieve gateway URLs, subscription keys, and resource names

-   :material-cube-send:{ .lg .middle } **Step 4: Build & Deploy**

    ---

    Build the container image in ACR and deploy to Container Apps

-   :material-connection:{ .lg .middle } **Test: Discover & Call Tools**

    ---

    Connect to APIM and invoke all 5 MCP tools end-to-end through the gateway

-   :material-robot:{ .lg .middle } **Test: Agent Framework**

    ---

    Run an AI agent that autonomously discovers and calls MCP tools to answer questions

-   :material-microsoft-visual-studio-code:{ .lg .middle } **Test: VS Code Integration**

    ---

    Configure the MCP server in GitHub Copilot Agent Mode for developer inner-loop

-   :material-delete:{ .lg .middle } **Clean Up**

    ---

    Delete all Azure resources created during the lab with a single command

</div>

[:octicons-arrow-right-24: Start the lab](labs/expose-rest-api-as-mcp.md)

---

## What You'll Build

By the end of this workshop, you'll have modernized a REST API into a fully governed MCP endpoint:

!!! success "Deliverables"

    :material-check-bold: **MCP Server** — Product Catalog API wrapped with FastMCP, serving 5 discoverable tools over Streamable HTTP

    :material-check-bold: **APIM Gateway** — Native MCP API type with subscription key authentication, monitoring, and policy enforcement

    :material-check-bold: **AI Agent Demo** — Microsoft Agent Framework orchestrating LLM + MCP tools, all through APIM

    :material-check-bold: **VS Code Integration** — MCP server configured for GitHub Copilot Agent Mode

    :material-check-bold: **Infrastructure as Code** — Complete Bicep templates you can adapt for your own APIs

---

## Why Azure API Management for MCP?

APIM brings **enterprise-grade governance** to your MCP endpoints — the same way it governs your REST, GraphQL, and WebSocket APIs today:

| Capability | What APIM Provides |
|---|---|
| :material-lock: **Security** | OAuth 2.0, Microsoft Entra ID, API keys, JWT validation |
| :material-chart-line: **Monitoring** | Azure Monitor, Application Insights, real-time analytics |
| :material-magnify: **Discovery** | Publish MCP tools to Azure API Center for organization-wide visibility |
| :material-cog: **Policies** | Rate limiting, caching, transformation on MCP traffic |
| :material-earth: **Unified plane** | Manage MCP alongside existing REST, GraphQL, and WebSocket APIs |

---

## The Bigger Picture

This workshop demonstrates **one of two patterns** for bringing MCP to your organization through Azure API Management:

| Pattern | Description | This Workshop |
|---------|-------------|:---:|
| **Expose REST API as MCP** | APIM sits in front of a backend MCP server that wraps your existing APIs | :material-check: |
| **Pass-through existing MCP servers** | APIM proxies and governs traffic to MCP servers already in production | — |

Both patterns let you **modernize without rewriting** — your existing business logic stays the same, while gaining AI-agent accessibility, enterprise security, and centralized governance.

---

## Getting Started

Ready to modernize your APIs? Follow these three simple steps:

=== "Step 1: Clone the Repository"

    ```bash
    git clone https://github.com/odaibert/api-modernization-with-mcp.git
    cd api-modernization-with-mcp
    ```

=== "Step 2: Verify Prerequisites"

    See the [Prerequisites](prerequisites.md) page for detailed setup instructions.

=== "Step 3: Open the Notebook"

    Open `labs/expose-rest-api-as-mcp/expose-rest-api-as-mcp.ipynb` in VS Code and click **Run All**.

!!! tip "No MCP Expertise Required"

    This workshop is designed for developers of all skill levels. If you can write Python code and navigate the Azure Portal, you're ready to modernize!

---

## Reference Materials

Throughout this workshop, we reference the official Azure documentation for MCP support in API Management:

- :material-file-document: [Blog: Azure API Management now supports MCP](https://techcommunity.microsoft.com/blog/integrationsonazureblog/%F0%9F%9A%80-new-in-azure-api-management-mcp-in-v2-skus--external-mcp-compliant-server-sup/4440294)
- :material-book-open-variant: [Expose APIs as MCP servers](https://learn.microsoft.com/azure/api-management/expose-mcp-server)
- :material-book-open-variant: [Connect external MCP servers](https://learn.microsoft.com/azure/api-management/connect-mcp-server)
- :material-shield-lock: [Secure MCP access](https://learn.microsoft.com/azure/api-management/secure-mcp-server)
- :material-magnify: [Discover tools in API Center](https://learn.microsoft.com/azure/api-center/discover-mcp-tools)
- :material-robot: [Microsoft Agent Framework](https://github.com/microsoft/agent-framework)
- :material-protocol: [Model Context Protocol specification](https://modelcontextprotocol.io/)
- :material-github: [Azure-Samples/AI-Gateway](https://github.com/Azure-Samples/AI-Gateway)
