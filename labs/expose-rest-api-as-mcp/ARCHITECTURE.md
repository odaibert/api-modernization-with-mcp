# Architecture: Expose a REST API as an MCP Server through Azure API Management

## Overview

This solution **modernizes an existing REST API** — a Product Catalog service — so that AI agents can discover and invoke it using the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/). Azure API Management acts as the **secure, enterprise-grade control plane** that fronts the MCP server, authenticates callers, applies policies, and provides full observability — the same way it governs REST, GraphQL, and WebSocket APIs today.

> *"Your APIs are becoming tools. Your users are becoming agents. Your platform needs to adapt."*

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
┌─────────────────────────────────┼──────────────┼────────────┼───────────────────────────┐
│ Azure Resource Group            │              │            │                            │
│                                 ▼              ▼            ▼                            │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                    Azure API Management (BasicV2 SKU)                           │    │
│  │                                                                                 │    │
│  │  ┌─────────────────────────────┐    ┌──────────────────────────────────┐        │    │
│  │  │  Product Catalog MCP API    │    │  Azure OpenAI Inference API      │        │    │
│  │  │  • Type: mcp (native)       │    │  • Type: REST (OpenAPI import)   │        │    │
│  │  │  • Transport: streamable    │    │  • Auth: Managed Identity → AI   │        │    │
│  │  │  • Path: /product-catalog   │    │  • Path: /inference              │        │    │
│  │  │  • Auth: api-key (sub key)  │    │  • Policy: set-backend-service,  │        │    │
│  │  │  • Backend: Container App   │    │    token metrics, auth header    │        │    │
│  │  └──────────────┬──────────────┘    └────────────────┬─────────────────┘        │    │
│  │                 │                                    │                           │    │
│  │  ┌──────────────┴───────────────────┐   ┌───────────┴───────────────────┐      │    │
│  │  │ Subscription: api-key header     │   │ Subscription: api-key header  │      │    │
│  │  │ Logging: Azure Monitor + AppIns. │   │ Logging: Azure Monitor + AppI.│      │    │
│  │  │ System-Assigned Managed Identity │   │ RBAC: Cognitive Svcs OpenAI   │      │    │
│  │  └──────────────────────────────────┘   │        Contributor            │      │    │
│  │                                         └──────────────────────────────-┘      │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                 │                                        │                              │
│                 ▼                                        ▼                              │
│  ┌──────────────────────────────────┐    ┌──────────────────────────────────┐          │
│  │  Azure Container App             │    │  Azure AI Foundry                │          │
│  │  ┌────────────────────────────┐  │    │  (Cognitive Services)            │          │
│  │  │ Product Catalog MCP Server │  │    │  ┌────────────────────────────┐  │          │
│  │  │ • FastMCP + Starlette      │  │    │  │ GPT-4o-mini deployment     │  │          │
│  │  │ • Streamable HTTP at /mcp  │  │    │  │ • Chat completions         │  │          │
│  │  │ • 5 tools (catalog ops)    │  │    │  │ • Tool-use / function call │  │          │
│  │  │ • Port 8080 (Uvicorn)      │  │    │  │ • Foundry project          │  │          │
│  │  └────────────────────────────┘  │    │  └────────────────────────────┘  │          │
│  │  Identity: UAI (ACR pull)        │    │  RBAC: APIM has Contributor role │          │
│  └──────────────────────────────────┘    └──────────────────────────────────┘          │
│                 ▲                                                                       │
│                 │ Image pull                                                            │
│  ┌──────────────────────────────────┐    ┌──────────────────────────────────┐          │
│  │  Azure Container Registry (ACR)  │    │  Azure Container App Environment│          │
│  │  • Basic SKU                     │    │  • Managed environment           │          │
│  │  • Stores MCP server image       │    │  • Logs → Log Analytics          │          │
│  │  • Admin auth disabled (UAI)     │    │  • Scaling: 1–3 replicas         │          │
│  └──────────────────────────────────┘    └──────────────────────────────────┘          │
│                                                                                        │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │  Observability Layer                                                            │   │
│  │  ┌────────────────────────────┐    ┌────────────────────────────────────────┐   │   │
│  │  │  Log Analytics Workspace   │◄───│  Application Insights                  │   │   │
│  │  │  • 30-day retention        │    │  • Tracks APIM requests + latency      │   │   │
│  │  │  • APIM diagnostics        │    │  • Custom token metrics (OpenAI)       │   │   │
│  │  │  • Container App logs      │    │  • End-to-end distributed tracing      │   │   │
│  │  └────────────────────────────┘    └────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘
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
User                    Agent Framework            APIM                    Container App    AI Foundry
  │                          │                      │                          │               │
  │── "Find USB products" ──►│                      │                          │               │
  │                          │── Chat completion ──►│                          │               │
  │                          │   (with tool defs)   │── Managed ID auth ──────►│               │
  │                          │                      │                          │               │
  │                          │◄─ tool_call: ────────│◄─ GPT-4o-mini response ──│               │
  │                          │   search_products    │                          │               │
  │                          │   {"query":"USB"}    │                          │               │
  │                          │                      │                          │               │
  │                          │── MCP tools/call ───►│                          │               │
  │                          │   api-key header     │── Forward ──────────────►│               │
  │                          │                      │                          │── Execute tool │
  │                          │◄─ Tool results ──────│◄── Results ──────────────│               │
  │                          │                      │                          │               │
  │                          │── Chat completion ──►│                          │               │
  │                          │   (with tool result) │── Managed ID auth ──────►│               │
  │                          │                      │                          │               │
  │                          │◄─ Final answer ──────│◄── Summarized response ──│               │
  │◄── "Found USB-C Hub..." ─│                      │                          │               │
```

---

## Azure Services: Why Each Was Chosen

### 1. Azure API Management (BasicV2 SKU)

**Role:** Unified gateway and governance layer for both MCP and LLM inference traffic.

**Why this service:**

| Requirement | How APIM Addresses It |
|---|---|
| **MCP protocol support** | APIM v2 SKUs natively understand the MCP protocol — you declare an API with `type: 'mcp'` and `transportType: 'streamable'`, and APIM handles the Streamable HTTP semantics (session management, bidirectional messaging) without custom policy hacks |
| **Authentication** | Built-in subscription key management (`api-key` header). Could also use OAuth 2.0, JWT validation, or Microsoft Entra ID — same auth mechanisms you'd use for any API |
| **Single control plane** | One place to manage both the MCP API (for AI agent tool access) and the Inference API (for LLM calls). Agents route all traffic through one gateway URL |
| **Observability** | Integrated diagnostics → Log Analytics + Application Insights. Every MCP request is logged with latency, status codes, and caller identity |
| **Policy engine** | Rate limiting, caching, IP filtering, request/response transformation — all applicable to MCP traffic. The policy pipeline runs on every tool invocation |
| **Enterprise readiness** | The same APIM service you may already use for REST APIs. No new platform to learn or operate |

**Why BasicV2 specifically:**
- The v2 tier is **required** for native MCP support (Classic tiers do not support `type: 'mcp'` APIs)
- BasicV2 is the most cost-effective v2 SKU — sufficient for development and testing
- Supports system-assigned managed identity for passwordless auth to backend services
- Can upgrade to StandardV2 or PremiumV2 for production workloads (VNet integration, higher throughput)

**Bicep configuration highlights:**
```bicep
resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  sku: { name: 'Basicv2', capacity: 1 }
  identity: { type: 'SystemAssigned' }  // For managed identity auth to AI Services
}
```

---

### 2. Azure Container Apps

**Role:** Hosts the Product Catalog MCP server — the containerized backend that APIM routes MCP traffic to.

**Why this service:**

| Requirement | How Container Apps Addresses It |
|---|---|
| **Run containers without managing infra** | Fully managed — no VMs, no Kubernetes cluster to operate. You push a container image and it runs |
| **HTTP ingress** | Built-in HTTPS ingress with auto-TLS termination. The MCP server receives plain HTTP on port 8080; Container Apps handles TLS at the edge |
| **Scale to demand** | Configured for 1–3 replicas. Scales based on HTTP traffic — more agent requests, more replicas. Scales to 1 at rest to save cost |
| **ACR integration** | Pulls images from Azure Container Registry using a User-Assigned Managed Identity — no registry credentials stored anywhere |
| **Logging** | Container stdout/stderr streams directly to Log Analytics via the managed environment |

**Why not Azure Functions / App Service / AKS:**
- **Azure Functions:** MCP servers need long-lived HTTP connections (Streamable HTTP sessions). Functions' request-response model and cold starts make this unreliable
- **App Service:** Would work, but Container Apps provides better autoscaling semantics and is purpose-built for containerized microservices
- **AKS:** Overkill for a single container. Container Apps gives you the Kubernetes benefits (scaling, health checks, revisions) without the operational complexity

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

### 3. Azure Container Registry (ACR)

**Role:** Builds and stores the MCP server container image in a private registry.

**Why this service:**

| Requirement | How ACR Addresses It |
|---|---|
| **Cloud build** | `az acr build` compiles the Dockerfile in Azure — no local Docker daemon required. The image never leaves Azure's network |
| **Private storage** | Images are stored in your own subscription. No public registry dependency at runtime |
| **Managed Identity pull** | Container Apps uses a User-Assigned Managed Identity with the `AcrPull` role — no admin credentials or connection strings |
| **Integrated with Container Apps** | Native registry integration in the Container App configuration — just reference the ACR server and identity |

**Why Basic SKU:** Sufficient for development (10 GiB storage, 2 webhooks). Upgrade to Standard or Premium for geo-replication and private endpoints in production.

---

### 4. Azure AI Foundry (Cognitive Services)

**Role:** Provides the LLM (GPT-4o-mini) that powers the Agent Framework demo — the AI agent uses this model to decide which MCP tools to call.

**Why this service:**

| Requirement | How AI Foundry Addresses It |
|---|---|
| **GPT-4o-mini** | Cost-effective model with strong tool-use (function calling) capabilities. Understands MCP tool schemas and generates correct `tool_call` payloads |
| **Managed identity auth** | APIM authenticates to AI Foundry using its system-assigned managed identity — no API keys passed over the wire. The Bicep template assigns `Cognitive Services OpenAI Contributor` role to APIM's identity |
| **Foundry project** | Organizes deployments and provides a project endpoint. The Agent Framework connects through this endpoint |
| **Azure-native** | Same data residency, compliance, and networking as the rest of the solution. No external LLM provider dependency |

**Why not direct OpenAI / other providers:**
- **Managed Identity:** APIM can authenticate to Azure AI Services using its managed identity — zero secrets management. External providers would require storing API keys
- **Policy enforcement:** APIM's inference API policy emits token metrics, applies rate limiting, and can route across multiple backends for load balancing
- **Data residency:** All data stays within your chosen Azure region

**RBAC chain:**
```
APIM (System Assigned MI) ──── Cognitive Services OpenAI Contributor ────► AI Foundry account
         │
         └── policy.xml: authentication-managed-identity resource="https://cognitiveservices.azure.com"
                         set-header Authorization: Bearer <managed-id-access-token>
```

---

### 5. Log Analytics Workspace

**Role:** Central log store for all diagnostic data — APIM request logs, Container App logs, and platform metrics.

**Why this service:**

| Requirement | How Log Analytics Addresses It |
|---|---|
| **Unified log collection** | Receives logs from APIM diagnostic settings, Container App Environment, and Application Insights — one place to query everything |
| **KQL queries** | Analyze MCP tool invocation patterns, error rates, latency distributions using Kusto Query Language |
| **Retention** | 30-day retention (configurable). Sufficient for development; extend for production audit requirements |
| **Cost model** | Pay-per-GB ingestion (PerGB2018 SKU). Predictable costs for development workloads |

**Connected sources:**
```
APIM diagnostic settings ──────► Log Analytics Workspace
Container App Environment ──────►    (30-day retention)
Application Insights ──────────►
```

---

### 6. Application Insights

**Role:** Application Performance Monitoring (APM) — tracks request-level telemetry for APIM, including MCP tool calls and LLM inference requests.

**Why this service:**

| Requirement | How Application Insights Addresses It |
|---|---|
| **APIM integration** | APIM's built-in logger sends every request/response to App Insights — including MCP session initiation, tool listing, and tool invocations |
| **Custom metrics** | The inference API policy emits OpenAI token metrics (prompt tokens, completion tokens) with dimensions for subscription ID, client IP, and API ID |
| **End-to-end tracing** | Distributed tracing across APIM → backend. See the full request chain from agent to MCP tool execution |
| **Alerting** | Set up alerts on error rates, latency thresholds, or token consumption |

**Configuration:** `CustomMetricsOptedInType: 'WithDimensions'` — enables multi-dimensional custom metrics for rich token analytics.

---

### 7. User-Assigned Managed Identity

**Role:** Provides the Container App with a credential to pull images from ACR — without storing any secrets.

**Why this approach:**

| Alternative | Why Not |
|---|---|
| ACR admin credentials | Stores passwords in Container App config — security anti-pattern |
| Service principal + secret | Requires secret rotation. Managed Identity is automatically rotated by Azure |
| System-assigned MI | Would work, but a User-Assigned MI can be created before the Container App and pre-granted ACR access in the same Bicep deployment |

**RBAC assignment:**
```
User-Assigned MI ──── AcrPull role ────► Azure Container Registry
         │
         └── Referenced in Container App registry configuration
```

---

## Security Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Security Layers                              │
│                                                                      │
│  Layer 1: APIM Gateway Authentication                                │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ • api-key subscription header (all APIs)                       │  │
│  │ • Can add: OAuth 2.0, JWT validation, Microsoft Entra ID       │  │
│  │ • Rate limiting and IP filtering via policies                  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Layer 2: APIM → Backend Authentication                              │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ MCP API:       APIM → Container App (TLS, no additional auth)  │  │
│  │ Inference API: APIM → AI Foundry (Managed Identity + Bearer)   │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Layer 3: Resource-Level RBAC                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ APIM MI → Cognitive Services OpenAI Contributor → AI Foundry   │  │
│  │ Container App UAI → AcrPull → Azure Container Registry         │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Layer 4: Network & Transport                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ • HTTPS everywhere (TLS termination at Container Apps ingress) │  │
│  │ • Container App ingress: external (can restrict to APIM only)  │  │
│  │ • ACR: public network (can enable private endpoint)            │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

---

## APIM API Configuration Details

### MCP API (Native Type)

The Product Catalog API is declared as a **native MCP type** in APIM — not a REST API with custom policies:

```bicep
resource mcp 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  properties: {
    type: 'mcp'                    // Native MCP protocol handling
    backendId: mcpBackend.name     // Routes to Container App
    path: 'product-catalog'        // Exposed at /product-catalog
    mcpProperties: {
      transportType: 'streamable'  // Streamable HTTP (not SSE, not stdio)
    }
    subscriptionKeyParameterNames: {
      header: 'api-key'            // Same auth pattern as Inference API
    }
  }
}
```

**What `type: 'mcp'` gives you:**
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
    value: 'https://raw.githubusercontent.com/.../inference.json'
    subscriptionRequired: true
    subscriptionKeyParameterNames: { header: 'api-key' }
  }
}
```

**Policy pipeline for inference:**
1. `authentication-managed-identity` — acquires a token for `cognitiveservices.azure.com`
2. `set-header Authorization` — injects `Bearer <token>` for the backend
3. `set-backend-service` — routes to the AI Foundry backend
4. `azure-openai-emit-token-metric` — emits token consumption metrics with subscription/client/API dimensions

---

## Infrastructure as Code: Deployment Order

The Bicep template orchestrates deployment with implicit dependency resolution:

```
1. Log Analytics Workspace
   └──► 2. Application Insights (needs LAW ID)
        └──► 3. API Management (needs LAW ID + App Insights)
             ├──► 4. AI Foundry + Model Deployments (needs APIM principal ID for RBAC)
             │    └──► 5. Inference API (needs AI Services config + APIM logger)
             ├──► 6. Container Registry
             │    └──► 7. Container App Environment + User-Assigned MI + Container App
             │         └──► 10. MCP API module (needs APIM name + Container App FQDN)
             └──► (Inference API must deploy before MCP API — explicit dependsOn)
```

**Resource naming:** All resources use `uniqueString(subscription().id, resourceGroup().id)` as suffix — deterministic within a subscription+RG pair, unique across pairs. The notebook adds a random `run_suffix` to the resource group name so each run is fully isolated.

---

## Design Decisions & Trade-offs

| Decision | Rationale | Trade-off |
|---|---|---|
| **BasicV2 SKU** | Lowest-cost v2 SKU with native MCP support | No VNet integration. Use StandardV2/PremiumV2 for production isolation |
| **Streamable HTTP (not SSE)** | Modern MCP transport — single HTTP endpoint, bidirectional, no long-polling. APIM v2 supports it natively | Requires MCP clients that support streamable transport (most modern clients do) |
| **Single APIM subscription for all APIs** | Simplifies the demo — one `api-key` works for both MCP and inference | Production should use per-API or per-consumer subscriptions for granular control |
| **Public endpoints** | All resources are publicly accessible for lab simplicity | Production should use VNet integration, private endpoints, and WAF |
| **In-memory product data** | MCP server uses a static Python list — no database | Demonstrates the pattern without external dependencies. Replace with a real data source for production |
| **Managed Identity everywhere** | APIM → AI Foundry (system MI), Container App → ACR (user MI) | Zero secrets in configuration. Slightly more complex Bicep (RBAC assignments) but significantly better security posture |

---

## Production Considerations

To evolve this lab into a production deployment, consider:

| Area | Lab Configuration | Production Recommendation |
|---|---|---|
| **APIM SKU** | BasicV2 | StandardV2 or PremiumV2 (VNet, higher throughput, availability zones) |
| **Networking** | Public endpoints | Private endpoints for ACR, AI Foundry. VNet integration for APIM and Container Apps |
| **Authentication** | API key (`api-key` header) | OAuth 2.0 with Microsoft Entra ID, JWT validation policy, per-consumer tokens |
| **MCP server data** | In-memory Python list | Connect to Azure SQL, Cosmos DB, or any existing data tier |
| **Scaling** | 1–3 Container App replicas | Set scaling rules based on HTTP concurrency; consider multiple backends behind APIM |
| **Monitoring** | Basic diagnostics | Custom dashboards, alerting rules, token budget alerts, anomaly detection |
| **CI/CD** | Manual notebook execution | GitHub Actions / Azure DevOps pipelines with Bicep deployment and container build |
| **Multi-region** | Single region | APIM Premium with multi-region gateway, geo-replicated ACR, regional Container Apps |

---

## References

| Resource | Link |
|---|---|
| Blog: Azure APIM MCP support | [techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/integrationsonazureblog/%F0%9F%9A%80-new-in-azure-api-management-mcp-in-v2-skus--external-mcp-compliant-server-sup/4440294) |
| Expose APIs as MCP servers | [learn.microsoft.com](https://learn.microsoft.com/azure/api-management/expose-mcp-server) |
| Connect external MCP servers | [learn.microsoft.com](https://learn.microsoft.com/azure/api-management/connect-mcp-server) |
| Secure MCP access | [learn.microsoft.com](https://learn.microsoft.com/azure/api-management/secure-mcp-server) |
| Discover tools in API Center | [learn.microsoft.com](https://learn.microsoft.com/azure/api-center/discover-mcp-tools) |
| Model Context Protocol spec | [modelcontextprotocol.io](https://modelcontextprotocol.io/) |
| Microsoft Agent Framework | [github.com/microsoft/agent-framework](https://github.com/microsoft/agent-framework) |
| Azure-Samples/AI-Gateway | [github.com/Azure-Samples/AI-Gateway](https://github.com/Azure-Samples/AI-Gateway) |
