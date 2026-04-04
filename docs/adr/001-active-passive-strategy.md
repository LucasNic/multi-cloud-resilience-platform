# ADR-001: Active-Passive Multi-Cloud Strategy (Azure + GCP)

## Status
Accepted (updated: OCI replaced by Azure — OCI free tier account activation unreliable)

## Context

This project requires a multi-cloud resilience architecture that:
- Survives a full primary cloud outage without human intervention
- Stays within a ~R$65/month budget
- Demonstrates production-grade patterns in a portfolio context

Cloud cost evaluation:
- **AWS EKS**: control plane ~R$55/month — no free tier. Discarded.
- **OCI OKE**: free tier (ARM A1 Flex), but account activation for paid resources is unreliable. Discarded after multiple failed activation attempts.
- **Azure AKS**: free control plane + spot B2s node ~R$45/month. Selected as primary.
- **GCP GKE**: free control plane (zonal) + spot e2-small ~R$15/month. Selected as failover.

## Decision

**Active-Passive failover** between:
- **Primary**: Azure — AKS + Standard_B2s spot node (eastus)
- **Failover**: GCP — GKE + spot e2-small (us-central1)

Failover is triggered and managed by **Cloudflare Workers** at the DNS layer.

| Criteria | Active-Active | Active-Passive | Feature Distribution |
|---|---|---|---|
| Data consistency | Hard (multi-primary) | Simple (single DB) | Varies |
| Operational complexity | Very High | Medium | Low |
| Cost | 2× full capacity | 1.3× (passive is minimal) | 1× |
| Demonstrates resilience | Yes, hard to prove | Yes, clear failover flow | No |

Active-Passive was chosen because:
- Solves a **real problem** (cloud provider outage) with a **provable mechanism**
- Failover can be **demonstrated live** in an interview
- Data consistency is handled by CockroachDB (multi-region, not multi-primary writes)

## Why Azure as Primary

- AKS control plane: free
- Standard_B2s spot: 2 vCPU + 4GB RAM, ~R$45/month (~70% cheaper than on-demand)
- Workload Identity Federation: zero stored secrets for CI/CD (consistent with ADR-004)
- System-Assigned Managed Identity: no service principal secrets to rotate (ADR-008)
- Tier-1 cloud provider with strong market recognition

## Why GCP as Failover

- GKE Standard zonal: one free control plane per billing account
- Spot e2-small: ~R$15/month
- Workload Identity Federation: same OIDC pattern as Azure
- Tier-1 cloud provider, relevant for portfolio narrative

## Failover Timeline

| Phase | Duration | Cumulative |
|---|---|---|
| Cloudflare Worker detects failure (3 checks × 1min) | ~180s | 180s |
| DNS propagation (TTL=60s) | ~60s | 240s |
| **Total RTO** | | **~4 minutes** |

## Trade-offs

- (+) Clear architectural narrative with demonstrable failover
- (+) ~4 min RTO, testable on demand
- (+) CockroachDB handles data layer resilience independently
- (+) Total cost ~R$65/month
- (-) Spot nodes can be evicted (Azure: 30s notice, GCP: similar). Mitigated: both clouds auto-replace evicted nodes
- (-) Not true HA — there IS a ~4 min outage window during failover
- (-) Using spot for primary means occasional brief disruptions during eviction/replacement

## Cost Breakdown

| Resource | Monthly Cost |
|---|---|
| Azure AKS control plane | R$0 |
| Azure B2s spot node | ~R$45 |
| GCP GKE control plane | R$0 |
| GCP e2-small spot | ~R$15 |
| CockroachDB Serverless | R$0 |
| Cloudflare Workers | R$0 |
| **Total** | **~R$60/month** |
