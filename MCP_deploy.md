# ArgoCD MCP Server — Deployment Guide

This guide walks through deploying the ArgoCD MCP server to a local minikube cluster and wiring it up to the LLM agent.

---

## Prerequisites

- `minikube`
- `kubectl`
- `argocd` CLI
- `docker`
- `pdm`

---

## Step 1 — Start minikube

```bash
minikube start
```

Wait until the node is ready:

```bash
kubectl get nodes
```

---

## Step 2 — Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
  --server-side --force-conflicts
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s
```

> `--server-side --force-conflicts` is required because ArgoCD's CRDs exceed the annotation size limit of standard `kubectl apply`.

---

## Step 3 — Get the ArgoCD admin password

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d > secret.txt
```

Save the output.

---

## Step 4 — Enable API key capability for the admin account

By default the admin account cannot generate API tokens. Patch the config to enable it:

```bash
kubectl patch configmap argocd-cm -n argocd --type merge \
  -p '{"data":{"accounts.admin":"apiKey,login"}}'
```

---

## Step 5 — Generate an ArgoCD API token

In **terminal 1**, port-forward ArgoCD (keep it running):

```bash
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

In **terminal 2**, log in and generate a token:

```bash
argocd login localhost:8443 --insecure --username admin --password $(cat secret.txt)
argocd account generate-token > secret.txt
```

You will get a raw JWT string. Save it — you need it in two places:

- **As-is** in `llm/.env` (Step 9)
- **Base64-encoded** in `k8s/secrets.yaml` (Step 6)

Base64-encode without line wrapping:

```bash
echo -n $(cat secret.txt) | base64 -w 0 > secret64.txt
```

---

## Step 6 — Add the token to `k8s/secrets.yaml`

Open `k8s/secrets.yaml` and set the `ARGOCD_AUTH_TOKEN` value to the base64-encoded token from Step 5:

```yaml
  ARGOCD_AUTH_TOKEN: "<base64-encoded-token>"
```

---

## Step 7 — Build the MCP server image

Clone the source:

```bash
wget -O /tmp/argocd-mcp.tar.gz https://github.com/argoproj-labs/mcp-for-argocd/archive/refs/tags/v0.7.0.tar.gz
cd /tmp
tar -xzvf argocd-mcp.tar.gz
```

For convienience, remove the version suffix from the unpacked directory.
Replace `/tmp/mcp-for-argocd/Dockerfile` with the following (fixes Node version, CI mode, and enables stateless HTTP transport):

```dockerfile
FROM node:24-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV CI=true
RUN corepack enable
COPY . /app
WORKDIR /app

FROM base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base AS build
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile --config.dangerously-allow-all-builds=true
RUN pnpm run build

FROM base
COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app/dist /app/dist
EXPOSE 3000
CMD [ "node", "dist/index.js", "http", "--stateless" ]
```

Changes vs the upstream Dockerfile:
| Change | Reason |
|--------|--------|
| `node:24-slim` | The upstream `node:22-slim` tag resolved to Node 20 inside minikube's VM, which is incompatible with pnpm 11 |
| `ENV CI=true` | Prevents pnpm from aborting when it can't find a TTY to confirm module removal |
| `--stateless` in CMD | Skips the MCP session handshake, allowing simple stateless JSON-RPC requests |

Point Docker at minikube's internal daemon and build:

```bash
eval $(minikube docker-env)
docker build -t mcp-for-argocd:local /tmp/mcp-for-argocd
```

---

## Step 8 — Deploy to minikube

```bash
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/mcp.yaml
```

Wait for the pod to be running:

```bash
kubectl get pods -l app=mcp-argocd -w
```

Hit `Ctrl+C` once it shows `Running`. Confirm stateless mode is active:

```bash
kubectl logs -l app=mcp-argocd | grep transport
```

Expected output:
```
Connecting to Http Stream transport on port: 3000 (stateless mode)
```

---

## Step 9 — Configure the LLM agent

```bash
cp llm/.env.example llm/.env
```

Edit `llm/.env` — all five values must be filled in (no empty values):

```
MCP_URL = http://localhost:3000/mcp
LLM_MODEL = gpt-4o-mini
OPENAI_API_KEY = sk-...
ARGOCD_BASE_URL = https://argocd-server.argocd.svc.cluster.local
ARGOCD_API_TOKEN = eyJhbGc...
```

> `ARGOCD_BASE_URL` is the in-cluster ArgoCD address used by the MCP server pod to reach ArgoCD. `ARGOCD_API_TOKEN` is the raw JWT from Step 5 (not base64-encoded).

Install the agent package:

```bash
cd llm && pdm install
```

---

## Step 10 — Port-forward the MCP server

In a terminal (keep it running while using the agent):

```bash
kubectl port-forward svc/mcp-argocd 3000:3000
```

---

## Step 11 (Optional) — Verify the MCP server

```bash
curl -s -X POST http://localhost:3000/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'x-argocd-base-url: https://argocd-server.argocd.svc.cluster.local' \
  -H "x-argocd-api-token: <raw-jwt-from-step-5>" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | python3 -m json.tool
```

You should see a JSON list of available ArgoCD tools (`list_applications`, `sync_application`, etc.).

---

## Step 12 — Run the agent

```bash
cd llm
pdm run llm-agent "List all clusters registered in ArgoCD"
```

Expected output:

```
[MCP] Calling tool: list_clusters with args: {}
[MCP] Tool result: {'metadata': {}, 'items': [{'server': 'https://kubernetes.default.svc', 'name': 'in-cluster', 'config': {'tlsClientConfig': {'insecure': False}}, 'connectionState': {'status': 'Unknown', 'message': 'Cluster has no applications and is not being monitored.', 'attemptedAt': '2026-05-16T22:23:32Z'}, 'serverVersion': '1.35.1', 'info': {'connectionState': {'status': 'Unknown', 'message': 'Cluster has no applications and is not being monitored.', 'attemptedAt': '2026-05-16T22:23:32Z'}, 'serverVersion': '1.35.1', 'cacheInfo': {}, 'applicationsCount': 0}}]}

🤖: The following cluster is registered in ArgoCD:

1. **Name:** in-cluster
   - **Server:** [https://kubernetes.default.svc](https://kubernetes.default.svc)
   - **Server Version:** 1.35.1
   - **Connection Status:** Unknown
   - **Message:** Cluster has no applications and is not being monitored.
   - **Applications Count:** 0

If you need more details or assistance, feel free to ask!
```

---

## Notes

- `NODE_TLS_REJECT_UNAUTHORIZED=0` is set in `k8s/mcp.yaml` because ArgoCD uses a self-signed certificate in this demo setup and the MCP server's `fetch`-based HTTP client has no native TLS bypass option.
- The `imagePullPolicy: Never` in `k8s/mcp.yaml` tells Kubernetes to use only locally built images and never attempt to pull from a registry.
- To reset everything: `minikube delete` wipes the entire cluster state.
