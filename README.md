# APIM ❤️ MCP — Modernize Your APIs for the AI Agent Era

> *"Your APIs are becoming tools. Your users are becoming agents. Your platform needs to adapt."*

This repository demonstrates how to use [Azure API Management](https://learn.microsoft.com/azure/api-management/) as a **secure, enterprise-grade control plane** for the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) — enabling AI agents to discover and invoke your APIs without rewriting business logic.

Built in the style of the [Azure-Samples/AI-Gateway](https://github.com/Azure-Samples/AI-Gateway) repository, with hands-on Jupyter notebooks that deploy real Azure infrastructure via Bicep.

## 🚀 Labs

| Lab | Description | Status |
|-----|-------------|--------|
| [Expose REST API as MCP Server](labs/expose-rest-api-as-mcp/) | Take an existing REST API (Product Catalog) and expose it as an MCP server through APIM — making it discoverable and invocable by AI agents | ✅ Ready |

## Why MCP + Azure API Management?

The **Model Context Protocol** is an open standard that turns APIs into **tools** that AI agents can discover, understand, and invoke. Azure API Management brings enterprise governance to this new paradigm:

- 🔐 **Security** — OAuth 2.0, Microsoft Entra ID, API keys, JWT validation
- 📊 **Monitoring** — Azure Monitor, Application Insights, real-time analytics
- 🔍 **Discovery** — Publish MCP tools to Azure API Center for organization-wide visibility
- ⚙️ **Policies** — Rate limiting, caching, transformation on MCP traffic
- 🌐 **Unified management** — Govern MCP alongside REST, GraphQL, and WebSocket APIs

## Repository Structure

```
apim-mcp/
├── labs/
│   └── expose-rest-api-as-mcp/      # Lab notebook, Bicep templates, and README
│       ├── expose-rest-api-as-mcp.ipynb
│       ├── main.bicep
│       └── README.md
├── modules/                          # Reusable Bicep modules
│   ├── apim/
│   ├── apim-streamable-mcp/
│   └── cognitive-services/
├── shared/                           # Shared code (MCP servers, utilities)
│   ├── mcp-servers/
│   │   └── product-catalog/
│   └── utils.py
└── requirements.txt
```

## Prerequisites

- [Python 3.12+](https://www.python.org/)
- [VS Code](https://code.visualstudio.com/) with the [Jupyter extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter)
- [Azure Subscription](https://azure.microsoft.com/free/) with Contributor + RBAC Administrator roles
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and signed in

## Getting Started

```bash
# Clone the repository
git clone <repo-url>
cd apim-mcp

# Open in VS Code
code .

# Navigate to a lab and open the notebook
# labs/expose-rest-api-as-mcp/expose-rest-api-as-mcp.ipynb
```

Each lab notebook is self-contained — click **Run All** to provision infrastructure, deploy services, and test end-to-end.

## References

- 📝 [Blog: Azure API Management now supports MCP](https://techcommunity.microsoft.com/blog/integrationsonazureblog/%F0%9F%9A%80-new-in-azure-api-management-mcp-in-v2-skus--external-mcp-compliant-server-sup/4440294)
- 📖 [Expose APIs as MCP servers](https://learn.microsoft.com/azure/api-management/expose-mcp-server)
- 📖 [Connect to external MCP-compliant servers](https://learn.microsoft.com/azure/api-management/connect-mcp-server)
- 🔐 [Secure access to MCP servers](https://learn.microsoft.com/azure/api-management/secure-mcp-server)
- 🔍 [Discover MCP tools in API Center](https://learn.microsoft.com/azure/api-center/discover-mcp-tools)
- 🤖 [Microsoft Agent Framework](https://github.com/microsoft/agent-framework)
- 🌐 [Model Context Protocol](https://modelcontextprotocol.io/)

## Contributing

This project welcomes contributions and suggestions.

## License

This project is licensed under the MIT License.
