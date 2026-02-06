# Architecture

## Overview

This solution **modernizes an existing REST API** — a Product Catalog service — so that AI agents can discover and invoke it using the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/). Azure API Management acts as the **secure, enterprise-grade control plane** that fronts the MCP server, authenticates callers, applies policies, and provides full observability.

!!! quote "The API Modernization Imperative"
    *"Your APIs are becoming tools. Your users are becoming agents. Your platform needs to adapt."*

---

## Solution Architecture

```
                        ┌─────────────────────────────────────────────┐
                        │           MCP Clients                       │
                        │                                             │
                        │  ┌─────────────┐  ┌──────────┐  ┌────────┐ │
                        │  │ Agent       │  │ VS Code  │  │ MCP    │ │
                        │  │ Framework   │  │ Copilot  │  │Inspect.│ │
                        │  └──────┬──────┘  └────┬─────┘  └───┬────┘ │
                        └─────────┼──────────────┼────────────┼───────┘
                                  │              │            │
                          Streamable HTTP + api-key header
                                  │              │            │
┌─────────────────────────────────┼──────────────┼────────────┼─────────────────────┐
│ Azure Resource Group            │              │            │                      │
│                                 ▼              ▼            ▼                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                Azure API Management (BasicV2 SKU)                           │  │
│  │                                                                             │  │
│  │  ┌───────────────────────────┐    ┌───────────────────────────────┐         │  │
│  │  │ Product Catalog MCP API   │    │ Azure OpenAI Inference API    │         │  │
│  │  │ • Type: mcp (native)      │    │ • Type: REST (OpenAPI import) │         │  │
│  │  │ • Transport: streamable   │    │ • Auth: Managed Identity      │         │  │
│  │  │ • Path: /product-catalog  │    │ • Path: /inference            │         │  │
│  │  └─────────────┬─────────────┘    └──────────────┬────────────────┘         │  │
│  └────────────────┼─────────────────────────────────┼──────────────────────────┘  │
│                   │                                  │                             │
│                   ▼                                  ▼                             │
│  ┌──────────────────────────────┐  ┌──────────────────────────────────┐          │
│  │  Azure Container App         │  │  Azure AI Foundry                │          │
│  │  • FastMCP + Starlette       │  │  • GPT-4o-mini deployment        │          │
│  │  • Streamable HTTP at /mcp   │  │  • Chat completions + tool-use   │          │
│  │  • 5 tools (catalog ops)     │  │  • Foundry project               │          │
│  └──────────────────────────────┘  └──────────────────────────────────┘          │
│                                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │  Observability: Log Analytics + Application Insights                        │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────────┘
```

---

## End-to-End Request Flow

### MCP Tool Discovery & Invocation

```
MCP Client                    APIM                         Container App
    │                          │                                │
    │ ── POST /product-catalog ──►                              │
    │    Header: api-key=<key> │                                │
    │    Body: {"method":      │                                │
    │     "initialize"}        │                                │
    │                          │── Validate subscription key ──►│
    │                          │── Route to MCP backend ───────►│
    │                          │                                │── Initialize MCP session
    │                          │◄── Session ID + capabilities ──│
    │◄─── 200 OK ─────────────│                                │
    │                          │                                │
    │ ── POST /product-catalog ──►                              │
    │    Body: {"method":      │                                │
    │     "tools/list"}        │                                │
    │                          │── Forward to backend ─────────►│
    │                          │                                │── Return 5 tools
    │                          │◄── Tool schemas ───────────────│
    │◄─── 200 OK ─────────────│                                │
    │                          │                                │
    │ ── POST /product-catalog ──►                              │
    │    Body: {"method":      │                                │
    │     "tools/call",        │                                │
    │     "params": {          │                                │
    │       "name":            │                                │
    │       "search_products", │── Forward to backend ─────────►│
    │       "arguments":       │                                │── Execute tool logic
    │       {"query":"USB"}}}  │                                │── Return results
    │                          │◄── Tool results ───────────────│
    │◄─── 200 OK ─────────────│                                │
```

### AI Agent Orchestration (Agent Framework)

```
User               Agent Framework         APIM              Container App    AI Foundry
  │                     │                   │                      │              │
  │── "Find USB" ──────►│                   │                      │              │
  │                     │── Chat completion ►│                      │              │
  │                     │   (with tool defs) │── Managed ID auth ──►│              │
  │                     │                   │                      │              │
  │                     │◄─ tool_call ──────│◄─ GPT-4o-mini ───────│              │
  │                     │   search_products │                      │              │
  │                     │                   │                      │              │
  │                     │── MCP tools/call ►│                      │              │
  │                     │   api-key header  │── Forward ──────────►│              │
  │                     │                   │                      │── Execute     │
  │                     │◄─ Tool results ───│◄── Results ──────────│              │
  │                     │                   │                      │              │
  │                     │── Chat completion ►│                      │              │
  │                     │   (with results)  │── Managed ID auth ──►│              │
  │                     │◄─ Final answer ───│◄── Summary ──────────│              │
  │◄── "Found USB-C…" ─│                   │                      │              │
```

---

## Azure Services Deep Dive

### :material-api: Azure API Management (BasicV2 SKU)

**Role:** Unified gateway and governance layer for both MCP and LLM inference traffic.

| Requirement | How APIM Addresses It |
|---|---|
| **MCP protocol support** | v2 SKUs natively understand MCP — declare `type: 'mcp'` with `transportType: 'streamable'` |
| **Authentication** | Subscription key management (`api-key` header), OAuth 2.0, JWT validation, Microsoft Entra ID |
| **Single control plane** | Manage both MCP API and Inference API in one place |
| **Observability** | Integrated diagnostics → Log Analytics + Application Insights |
| **Policy engine** | Rate limiting, caching, IP filtering, request/response transformation |
| **Enterprise readiness** | Same APIM platform you may already use for REST APIs |

!!! info "Why BasicV2?"
    The v2 tier is **required** for native MCP support (Classic tiers do not support `type: 'mcp'` APIs). BasicV2 is the most cost-effective v2 SKU — sufficient for development and testing. Upgrade to StandardV2 or PremiumV2 for production (VNet integration, higher throughput).

```bicep
resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  sku: { name: 'Basicv2', capacity: 1 }
  identity: { type: 'SystemAssigned' }  // For managed identity auth to AI Services
}
```

---

### :material-docker: Azure Container Apps

**Role:** Hosts the Product Catalog MCP server — the containerized backend that APIM routes MCP traffic to.

| Requirement | How Container Apps Addresses It |
|---|---|
| **Run containers without managing infra** | Fully managed — no VMs, no Kubernetes cluster to operate |
| **HTTP ingress** | Built-in HTTPS with auto-TLS termination. MCP server on port 8080 |
| **Scale to demand** | 1–3 replicas, scales based on HTTP traffic |
| **ACR integration** | Pulls images using a User-Assigned Managed Identity — no credentials stored |
| **Logging** | stdout/stderr streams directly to Log Analytics |

!!! tip "Why not Azure Functions, App Service, or AKS?"
    - **Azure Functions:** MCP servers need long-lived HTTP connections; cold starts make this unreliable
    - **App Service:** Would work, but Container Apps provides better autoscaling semantics
    - **AKS:** Overkill for a single container — Container Apps gives Kubernetes benefits without operational complexity

**What runs inside:**
```
Python 3.13 slim → Uvicorn → Starlette ASGI app → FastMCP
                                  │
                    Mount("/product-catalog", app=mcp_asgi)
                                  │
                         MCP endpoint at /product-catalog/mcp
                                  │
                    5 tools: get_categories, get_products_by_category,
                             get_product, search_products, check_stock
```

---

### :material-database: Azure Container Registry (ACR)

**Role:** Builds and stores the MCP server container image in a private registry.

| Requirement | How ACR Addresses It |
|---|---|
| **Cloud build** | `az acr build` compiles in Azure — no local Docker daemon required |
| **Private storage** | Images stored in your subscription, no public registry dependency |
| **Managed Identity pull** | Container Apps uses UAI with `AcrPull` role |

---

### :material-brain: Azure AI Foundry (Cognitive Services)

**Role:** Provides the LLM (GPT-4o-mini) that powers the Agent Framework demo.

| Requirement | How AI Foundry Addresses It |
|---|---|
| **GPT-4o-mini** | Cost-effective model with strong tool-use capabilities |
| **Managed identity auth** | APIM authenticates using system-assigned MI — no API keys over the wire |
| **Foundry project** | Organizes deployments and provides a project endpoint |
| **Azure-native** | Same data residency, compliance, and networking as the rest of the solution |

**RBAC chain:**
```
APIM (System Assigned MI) ── Cognitive Services OpenAI Contributor ──► AI Foundry account
```

---

### :material-chart-line: Log Analytics + Application Insights

**Role:** Central observability layer — unified log collection, APM, and custom metrics.

```
APIM diagnostic settings ──────► Log Analytics Workspace
Container App Environment ──────►    (30-day retention)
Application Insights ──────────►
```

| Capability | Details |
|---|---|
| **KQL queries** | Analyze MCP tool invocation patterns, error rates, latency distributions |
| **Custom metrics** | OpenAI token consumption with subscription/client/API dimensions |
| **End-to-end tracing** | Distributed tracing across APIM → backend |
| **Alerting** | Error rates, latency thresholds, token consumption |

---

## Security Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      Security Layers                              │
│                                                                   │
│  Layer 1: APIM Gateway Authentication                             │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ • api-key subscription header (all APIs)                   │   │
│  │ • Can add: OAuth 2.0, JWT validation, Microsoft Entra ID   │   │
│  │ • Rate limiting and IP filtering via policies              │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Layer 2: APIM → Backend Authentication                           │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ MCP API:       APIM → Container App (TLS, no extra auth)  │   │
│  │ Inference API: APIM → AI Foundry (Managed Identity)        │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Layer 3: Resource-Level RBAC                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ APIM MI → Cognitive Services OpenAI Contributor            │   │
│  │ Container App UAI → AcrPull → ACR                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Layer 4: Network & Transport                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ • HTTPS everywhere (TLS at Container Apps ingress)         │   │
│  │ • Production: VNet integration, private endpoints, WAF     │   │
│  └────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## APIM API Configuration

### MCP API (Native Type)

The Product Catalog API is declared as a **native MCP type** — not a REST API with custom policies:

```bicep
resource mcp 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  properties: {
    type: 'mcp'                    // Native MCP protocol handling
    backendId: mcpBackend.name     // Routes to Container App
    path: 'product-catalog'        // Exposed at /product-catalog
    mcpProperties: {
      transportType: 'streamable'  // Streamable HTTP transport
    }
    subscriptionKeyParameterNames: {
      header: 'api-key'            // Same auth pattern as Inference API
    }
  }
}
```

!!! success "What `type: 'mcp'` gives you"
    - APIM understands MCP session lifecycle (initialize → tool discovery → tool calls)
    - The `/product-catalog` path serves MCP directly — no `/mcp` suffix needed in the APIM URL
    - Backend routing is MCP-aware — APIM forwards to `{backend-url}/mcp` automatically
    - Compatible with all MCP clients that support Streamable HTTP transport

### Inference API (REST / OpenAPI)

```bicep
resource inferenceAPI 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  properties: {
    path: 'inference'
    format: 'openapi-link'   // Imports the official Azure OpenAI spec
    subscriptionRequired: true
    subscriptionKeyParameterNames: { header: 'api-key' }
  }
}
```

**Policy pipeline:** `authentication-managed-identity` → `set-header Authorization` → `set-backend-service` → `azure-openai-emit-token-metric`

---

## Deployment Order

The Bicep template orchestrates deployment with implicit dependency resolution:

```
1. Log Analytics Workspace
   └──► 2. Application Insights
        └──► 3. API Management
             ├──► 4. AI Foundry + Model Deployments (RBAC)
             │    └──► 5. Inference API
             ├──► 6. Container Registry
             │    └──► 7. Container App Environment + Container App
             │         └──► 10. MCP API module
             └──► (Inference API deploys before MCP API — explicit dependsOn)
```

!!! note "Resource Naming"
    All resources use `uniqueString(subscription().id, resourceGroup().id)` as a suffix — deterministic within a subscription+RG pair, unique across pairs. The notebook adds a random `run_suffix` to the resource group name so each run is fully isolated.

---

## Design Decisions

| Decision | Rationale | Trade-off |
|---|---|---|
| **BasicV2 SKU** | Lowest-cost v2 SKU with native MCP | No VNet integration — use StandardV2+ for production |
| **Streamable HTTP** | Modern MCP transport, APIM v2 native support | Requires MCP clients that support streamable transport |
| **Single subscription** | One `api-key` for both MCP and inference | Production should use per-API subscriptions |
| **Public endpoints** | Lab simplicity | Production: VNet, private endpoints, WAF |
| **In-memory data** | No external dependencies for demo | Replace with a real data source for production |
| **Managed Identity** | Zero secrets in configuration | Slightly more complex Bicep (RBAC assignments) |

---

## Production Considerations

| Area | Lab | Production |
|---|---|---|
| **APIM SKU** | BasicV2 | StandardV2 or PremiumV2 (VNet, HA, zones) |
| **Networking** | Public endpoints | Private endpoints, VNet integration |
| **Authentication** | API key | OAuth 2.0, Microsoft Entra ID, JWT validation |
| **MCP server data** | In-memory Python list | Azure SQL, Cosmos DB, or existing data tier |
| **Scaling** | 1–3 replicas | HTTP concurrency rules, multiple APIM backends |
| **Monitoring** | Basic diagnostics | Custom dashboards, alerts, anomaly detection |
| **CI/CD** | Manual notebook | GitHub Actions / Azure DevOps pipelines |
| **Multi-region** | Single region | APIM Premium, geo-replicated ACR |
