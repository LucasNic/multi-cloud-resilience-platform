# Runbook: AKS Primary Cluster Failure → GKE Failover

## Scenario
The AKS primary cluster becomes unreachable. This document describes what breaks, how it's detected, and how traffic recovers — automatically.

## Architecture Context

```
Normal operation:
  Users → Cloudflare → AKS (PRIMARY) → CockroachDB

During failover:
  Users → Cloudflare → GKE (FAILOVER) → CockroachDB (same endpoint, no change)
```

## Timeline of Events

### T+0s — AKS Becomes Unhealthy

**What breaks:**
- AKS API server is unreachable, OR
- Application pods crash-loop, OR
- LoadBalancer health checks fail, OR
- The `/healthz` endpoint returns non-200

**What does NOT break:**
- CockroachDB (independent SaaS, multi-region)
- GKE cluster (independent infrastructure in GCP)
- ArgoCD (deployed in both clusters, self-healing)
- DNS resolution (Cloudflare is globally distributed)

### T+60s — First Health Check Fails

Cloudflare Worker (cron: every 1 minute) sends an HTTPS request to the AKS ingress `/healthz` endpoint. The first check fails.

**Detection mechanism:**
```
Cloudflare Worker Configuration:
  Target:     https://<aks-ingress>/healthz
  Interval:   60 seconds (cron trigger)
  Threshold:  3 consecutive failures
  State:      Cloudflare KV (persistent)
```

### T+180s — AKS Marked UNHEALTHY

After 3 consecutive failures (60s × 3 = 180s), the Worker triggers failover.

**Automated actions triggered:**
1. Worker checks GKE health (must be healthy before failover)
2. Worker updates DNS A record → GKE ingress IP
3. Failover state persisted in KV: `{ current_target: "gke", failure_count: 3 }`
4. `[failover] FAILOVER TRIGGERED: AKS → GKE` logged in Worker

### T+240s (~4 min) — Traffic Flowing to GKE

DNS propagation completes (TTL=60s). All new DNS lookups resolve to the GKE failover cluster.

**Expected degradation during failover:**
- No database latency increase (both clusters use same CockroachDB endpoint)
- Some clients may cache the old DNS for up to 60s beyond TTL
- No data loss (CockroachDB handles replication internally)

**What works immediately on GKE:**
- Same application version (ArgoCD keeps both clusters in sync)
- Same database (CockroachDB endpoint is the same for both clusters)
- Same secrets (ExternalSecret operator pulls from cloud-native secret stores)

### T+??? — AKS Recovers

When AKS becomes healthy again:
1. Worker health checks pass (immediate on next cron run)
2. Worker automatically fails BACK to AKS (primary)
3. `[failover] AKS recovered. Failing back to AKS.` logged

**Manual verification before failback (recommended):**
```bash
# Verify AKS cluster health
kubectl --context aks get nodes
kubectl --context aks get pods -n app

# Verify application health
curl -v https://<aks-ingress>/healthz

# Check ArgoCD sync status
argocd app get api-aks-primary
```

## Key Metrics to Monitor

| Metric | Source | Alert Threshold |
|---|---|---|
| Cloudflare Worker execution | Cloudflare Dashboard | Errors > 0 |
| API response latency (p99) | Prometheus | > 500ms |
| Error rate (5xx) | Prometheus | > 1% |
| ArgoCD sync status | ArgoCD metrics | OutOfSync > 5 min |
| CockroachDB connections | CockroachDB Console | > 80% of limit |
| DNS resolution time | External monitoring | > 100ms |

## What Can Go Wrong During Failover

| Risk | Mitigation |
|---|---|
| GKE also down | Worker checks GKE health before failover; if both fail, no DNS change |
| CockroachDB unreachable | Both clusters use TLS with cert verification; CockroachDB has 99.99% SLA |
| ArgoCD out of sync | Automated sync with self-heal; alert on OutOfSync > 5 min |
| DNS cache stale | TTL=60s minimizes window |
| Spot node evicted during failover | Cloud auto-replaces spot nodes; HPA scales if needed |

## Manual Intervention Procedures

### Force Failover (Testing or Planned Maintenance)

```bash
# Option 1: Scale AKS deployment to 0 (app-level failover)
kubectl --context aks scale deployment/api -n app --replicas=0

# Option 2: Use Cloudflare API to update DNS directly
curl -X PUT "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records/RECORD_ID" \
  -H "Authorization: Bearer CF_API_TOKEN" \
  -d '{"type":"A","name":"api","content":"GKE_IP","proxied":true,"ttl":1}'

# Verify traffic is hitting GKE
curl -v https://api.lucasnicoloso.com/api/cluster
# Should return: {"cluster":"gke","cloud":"gcp"}
```

### Force Failback

```bash
# Scale AKS deployment back up
kubectl --context aks scale deployment/api -n app --replicas=2

# Worker will detect AKS recovery and failback automatically
# Or force via Cloudflare API (same curl as above, with AKS_IP)

# Verify AKS is healthy and receiving traffic
watch -n5 'curl -s https://api.lucasnicoloso.com/api/cluster | jq .cluster'
```

## Post-Incident Review Checklist

- [ ] Root cause identified and documented
- [ ] Failover timeline matches expected RTO (~4 min)
- [ ] No data loss confirmed (CockroachDB consistency check)
- [ ] ArgoCD sync status verified on both clusters
- [ ] Health check thresholds reviewed (too sensitive? too slow?)
- [ ] Runbook updated with lessons learned
