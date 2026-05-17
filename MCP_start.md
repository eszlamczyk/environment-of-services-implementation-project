# ArgoCD MCP Server — Quick Start (After Reboot)

Run these steps every time you restart your PC. Assumes the cluster was previously deployed via `MCP_deploy.md`.

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

## Step 2 — Verify deployments are running

```bash
kubectl get pods -n argocd
kubectl get pods -l app=mcp-argocd
```

All pods should reach `Running` within ~60 seconds. If a pod is stuck, check logs:

```bash
kubectl logs -n argocd deployment/argocd-server
kubectl logs -l app=mcp-argocd
```

---

## Step 3 — Port-forward ArgoCD (optional)

Only needed if you want to use the ArgoCD UI or CLI directly.

In a dedicated terminal:

```bash
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

ArgoCD UI is then at `https://localhost:8443` (accept the self-signed cert warning).

---

## Step 4 — Port-forward the MCP server

In a dedicated terminal (keep it running while using the agent):

```bash
kubectl port-forward svc/mcp-argocd 3000:3000
```

---

## Step 5 — Run the agent

```bash
cd llm
pdm run llm-agent "List all clusters registered in ArgoCD"
```

---

## Notes

- Steps 3 and 4 must remain running in their terminals while you use the agent.
- The ArgoCD API token stored in `k8s/secrets.yaml` does not expire by default. If you regenerated the token, update `k8s/secrets.yaml` and `llm/.env`, then re-apply: `kubectl apply -f k8s/secrets.yaml`.
- To reset everything completely: `minikube delete` — then follow `MCP_deploy.md` from scratch.
