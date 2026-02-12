# Getting Started

Follow these steps to clone, set up, and run the workshop.

---

## :material-numeric-1-circle: Clone the Repository

```bash
git clone https://github.com/odaibert/api-modernization-with-mcp.git
cd api-modernization-with-mcp
```

## :material-numeric-2-circle: Open in VS Code

```bash
code .
```

## :material-numeric-3-circle: Create a Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate   # macOS/Linux
# .venv\Scripts\activate    # Windows
```

## :material-numeric-4-circle: Install Dependencies

```bash
pip install -r requirements.txt
```

## :material-numeric-5-circle: Open the Notebook

Navigate to `labs/expose-rest-api-as-mcp/` and open **`expose-rest-api-as-mcp.ipynb`** in VS Code.

## :material-numeric-6-circle: Run the Lab

You have two options:

=== "Run All"

    Click **Run All** at the top of the notebook to execute every step sequentially. The entire deployment takes approximately 15–20 minutes (APIM provisioning is the longest step).

=== "Step by Step"

    Execute each cell individually to understand what each step does. The notebook is organized into clearly labeled sections with markdown explanations.

---

## Repository Structure

```
api-modernization-with-mcp/
+-- labs/
|   +-- expose-rest-api-as-mcp/       # Lab notebook, Bicep templates, and README
|       +-- expose-rest-api-as-mcp.ipynb
|       +-- main.bicep
|       +-- policy.xml
+-- modules/                           # Reusable Bicep modules
|   +-- apim/v2/                       # APIM v2 + Inference API
|   +-- apim-streamable-mcp/           # MCP API module
|   +-- cognitive-services/v3/         # AI Foundry
|   +-- monitor/v1/                    # Application Insights
|   +-- operational-insights/v1/       # Log Analytics
+-- shared/                            # Shared code
|   +-- mcp-servers/product-catalog/   # MCP server source + Dockerfile
|   +-- utils.py                       # Notebook utilities
+-- docs/                              # This documentation site
+-- mkdocs.yml                         # MkDocs configuration
+-- requirements.txt                   # Python dependencies
```

---

## What the Notebook Does

| Step | Duration | Description |
|------|----------|-------------|
| **0️⃣ Initialize** | ~1s | Set variables, generate unique resource suffix |
| **1️⃣ Verify Azure CLI** | ~2s | Confirm login and subscription |
| **🧪 Local test** | ~5s | Start MCP server locally, verify 5 tools |
| **2️⃣ Deploy to Azure** | ~15min | Bicep deployment (APIM takes longest) |
| **3️⃣ Get outputs** | ~5s | Retrieve URLs, keys, resource names |
| **4️⃣ Build & deploy** | ~3min | Build container in ACR, deploy to Container Apps |
| **🧪 Test tools** | ~10s | Discover and call all MCP tools through APIM |
| **🧪 Agent Framework** | ~15s | AI agent uses MCP tools to answer a question |
| **🗑️ Clean up** | ~1min | Delete the resource group |

---

## Troubleshooting

!!! warning "APIM provisioning takes ~10-15 minutes"

    The BasicV2 SKU deployment is the longest step. The notebook will wait for it to complete.

!!! warning "Azure CLI not found"

    If `az` is not found, ensure it's installed and on your PATH. The notebook automatically detects common install locations on macOS.

!!! tip "Each run is isolated"

    The notebook generates a unique random suffix for every execution, creating a new resource group each time. You can run multiple experiments in parallel without conflicts.

---

[:octicons-arrow-right-24: Start the lab](labs/expose-rest-api-as-mcp.md)
