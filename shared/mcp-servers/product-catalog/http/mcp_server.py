import random
import uvicorn

# Support either the standalone 'fastmcp' package or the 'mcp' package layout.
try:
    from fastmcp import FastMCP, Context  # pip install fastmcp
except ModuleNotFoundError:  # fall back to the layout you used originally
    from mcp.server.fastmcp import FastMCP, Context  # pip install mcp

from starlette.applications import Starlette
from starlette.routing import Mount


mcp = FastMCP("ProductCatalog")

# --- Sample product data ---
PRODUCTS = [
    {"id": "PROD-001", "name": "Wireless Keyboard", "category": "Electronics", "price": 49.99, "stock": 150, "description": "Ergonomic wireless keyboard with backlit keys and Bluetooth 5.0 connectivity."},
    {"id": "PROD-002", "name": "Running Shoes", "category": "Sports", "price": 89.99, "stock": 75, "description": "Lightweight running shoes with responsive cushioning and breathable mesh upper."},
    {"id": "PROD-003", "name": "Coffee Maker", "category": "Home & Kitchen", "price": 129.99, "stock": 40, "description": "12-cup programmable coffee maker with thermal carafe and auto-shutoff."},
    {"id": "PROD-004", "name": "Yoga Mat", "category": "Sports", "price": 29.99, "stock": 200, "description": "Non-slip yoga mat with alignment markings, 6mm thick, eco-friendly material."},
    {"id": "PROD-005", "name": "USB-C Hub", "category": "Electronics", "price": 39.99, "stock": 300, "description": "7-in-1 USB-C hub with HDMI, SD card reader, USB 3.0 ports and PD charging."},
    {"id": "PROD-006", "name": "Stainless Steel Water Bottle", "category": "Sports", "price": 24.99, "stock": 500, "description": "Vacuum-insulated 750ml water bottle, keeps drinks cold 24h or hot 12h."},
    {"id": "PROD-007", "name": "Noise-Canceling Headphones", "category": "Electronics", "price": 199.99, "stock": 60, "description": "Over-ear headphones with active noise cancellation, 30-hour battery life."},
    {"id": "PROD-008", "name": "Cast Iron Skillet", "category": "Home & Kitchen", "price": 34.99, "stock": 90, "description": "Pre-seasoned 12-inch cast iron skillet, oven-safe to 500°F."},
    {"id": "PROD-009", "name": "Backpack", "category": "Travel", "price": 59.99, "stock": 120, "description": "Water-resistant 30L travel backpack with laptop compartment and USB charging port."},
    {"id": "PROD-010", "name": "Desk Lamp", "category": "Home & Kitchen", "price": 44.99, "stock": 85, "description": "LED desk lamp with adjustable brightness, color temperature and wireless charging base."},
    {"id": "PROD-011", "name": "Portable Charger", "category": "Electronics", "price": 29.99, "stock": 400, "description": "20000mAh portable charger with dual USB-C ports and fast charging support."},
    {"id": "PROD-012", "name": "Travel Pillow", "category": "Travel", "price": 19.99, "stock": 250, "description": "Memory foam travel pillow with adjustable clasp and machine-washable cover."},
]


@mcp.tool()
async def get_categories(ctx: Context) -> str:
    """Get list of all product categories available in the catalog."""
    categories = sorted(set(p["category"] for p in PRODUCTS))
    return str(categories)


@mcp.tool()
async def get_products_by_category(ctx: Context, category: str) -> str:
    """Get all products in a given category. Use get_categories first to see available categories."""
    results = [p for p in PRODUCTS if p["category"].lower() == category.lower()]
    if not results:
        return f"No products found in category '{category}'. Use get_categories to see available categories."
    return str(results)


@mcp.tool()
async def get_product(ctx: Context, product_id: str) -> str:
    """Get detailed information for a specific product by its ID (e.g., PROD-001)."""
    product = next((p for p in PRODUCTS if p["id"].upper() == product_id.upper()), None)
    if not product:
        return f"Product '{product_id}' not found. Use search_products to find valid product IDs."
    return str(product)


@mcp.tool()
async def search_products(ctx: Context, query: str) -> str:
    """Search products by name or description. Returns matching products."""
    query_lower = query.lower()
    results = [p for p in PRODUCTS if query_lower in p["name"].lower() or query_lower in p["description"].lower()]
    if not results:
        return f"No products found matching '{query}'."
    return str(results)


@mcp.tool()
async def check_stock(ctx: Context, product_id: str) -> str:
    """Check the stock availability of a product by its ID."""
    product = next((p for p in PRODUCTS if p["id"].upper() == product_id.upper()), None)
    if not product:
        return f"Product '{product_id}' not found."
    status = "In Stock" if product["stock"] > 0 else "Out of Stock"
    return str({"product_id": product["id"], "name": product["name"], "stock": product["stock"], "status": status})


# Expose an ASGI app that speaks Streamable HTTP at /mcp/
mcp_asgi = mcp.http_app()
app = Starlette(
    routes=[Mount("/product-catalog", app=mcp_asgi)],  # MCP will be at /product-catalog/mcp/
    lifespan=mcp_asgi.lifespan,
)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Run Product Catalog MCP Streamable-HTTP server")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8080, help="Port to listen on")
    args = parser.parse_args()
    uvicorn.run(app, host=args.host, port=args.port)
