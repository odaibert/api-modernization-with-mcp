import json, os, subprocess, httpx

DEPLOYMENT_NAME = os.environ.get("DEPLOYMENT_NAME", "expose-rest-api-as-mcp")
RESOURCE_GROUP = os.environ.get("RESOURCE_GROUP", f"lab-{DEPLOYMENT_NAME}")

result = subprocess.run(
    ['az', 'deployment', 'group', 'show',
     '--name', DEPLOYMENT_NAME, '-g', RESOURCE_GROUP,
     '--query', 'properties.outputs', '-o', 'json'],
    capture_output=True, text=True
)
assert result.returncode == 0, f"az deployment failed: {result.stderr or result.stdout}"

outputs = json.loads(result.stdout)
gateway_url = outputs['apimResourceGatewayURL']['value']
key = outputs['apimSubscriptions']['value'][0]['key']
print(f'Gateway: {gateway_url}')
print(f'Key: {key[:8]}...')

# Test MCP initialize via direct POST
resp = httpx.post(
    f'{gateway_url}/product-catalog',
    headers={'api-key': key, 'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream'},
    json={
        'jsonrpc': '2.0',
        'method': 'initialize',
        'id': 1,
        'params': {
            'protocolVersion': '2025-03-26',
            'capabilities': {},
            'clientInfo': {'name': 'test', 'version': '1.0'}
        }
    },
    timeout=30
)
print(f'Status: {resp.status_code}')
print(f'Response: {resp.text[:500]}')

assert resp.status_code == 200, f"Expected 200, got {resp.status_code}: {resp.text[:200]}"
data = resp.json()
assert data.get('jsonrpc') == '2.0', f"Unexpected jsonrpc version: {data.get('jsonrpc')}"
assert 'result' in data, f"Missing 'result' in response: {list(data.keys())}"
print('✅ MCP initialize succeeded')
