# Platform Architecture — Multi-Cloud Resilient Infrastructure

## Purpose

This document defines the **infrastructure architecture and operational model** of the multi-cloud platform.

Focus areas:

- resilience
- failover
- infrastructure as code
- security
- cost-awareness

---

## Architecture Strategy

- Pattern: Active-Passive failover
- Primary cloud: Azure (AKS)
- Secondary cloud: GCP (GKE)
- Failover mechanism: Cloudflare Workers (DNS, outside both clouds)
- RTO: ~4 minutes

---

## Core Components

### Azure (Primary)

- AKS (Kubernetes) — free control plane, Standard_B2s spot node
- System-Assigned Managed Identity (ADR-008)
- Workload Identity for pods (OIDC issuer)
- NGINX Ingress (exposed via LoadBalancer)

---

### GCP (Failover)

- GKE (Kubernetes) — free control plane (zonal), spot e2-small node
- Workload Identity Federation
- GCE Ingress (native GCP load balancer)

---

### Cloudflare (DNS + Failover Layer)

- DNS zone management (lucasnicoloso.com)
- Worker (cron: 1min) checks AKS `/healthz`
- KV Store persists failover state
- On 3 consecutive failures → updates DNS A record to GKE IP

---

## Data Strategy

- CockroachDB Serverless (multi-region: us-east1 + us-central1)
- Both AKS and GKE connect to the same CockroachDB endpoint via TLS
- No split-brain risk — single logical database

Trade-off:
- no data replication to manage
- added latency (~10-20ms cross-cloud)

---

## Failover Flow

1. AKS becomes unhealthy
2. Cloudflare Worker health checks fail (3 × 60s)
3. Worker verifies GKE is healthy
4. Worker updates DNS A record → GKE IP
5. Traffic flows to GCP (~4 min total RTO)
6. When AKS recovers, Worker automatically fails back

---

## GitOps Model

- Source of truth: GitHub
- Deployment: ArgoCD ApplicationSet
- Strategy:
  - multi-cluster sync (AKS + GKE)
  - Kustomize overlays per cloud

---

## CI/CD Strategy

- GitHub Actions
- OIDC authentication — zero stored secrets (Azure + GCP)
- Pipeline stages:
  - lint (TFLint)
  - security scan (Checkov)
  - plan (Terraform/Terragrunt) — parallel per cloud
  - apply (manual approval, sequential: Azure → GCP → shared)

---

## Infrastructure as Code

- Tooling:
  - Terraform (modules)
  - Terragrunt (orchestration)

Structure:

- `/modules` → reusable infrastructure (azure/, gcp/, shared/)
- `/live` → environment orchestration (azure/eastus/dev, gcp/us-central1/dev, shared/global/dev)

Principles:

- DRY
- decoupled modules
- explicit dependencies

---

## Networking

- Cross-cloud via public endpoints
- TLS enforced end-to-end
- Cloudflare proxy hides origin IPs

Trade-off:
- zero cost
- higher latency vs private networking

---

## Security Model

- OIDC federation (GitHub → Azure/GCP) — ADR-004
- No stored credentials in CI/CD
- AKS Managed Identity — ADR-008
- GKE Workload Identity
- K8s Network Policies
- Checkov scanning on every PR

---

## Observability

- Prometheus (metrics)
- Fluent Bit (logs → OCI Logging / Cloud Logging)
- Grafana or cloud dashboards
- Health endpoints:
  - /healthz (external — Cloudflare Worker target)
  - /readyz (internal — K8s readiness)
  - /livez (internal — K8s liveness)

---

## Cost Strategy

| Resource | Monthly Cost |
|---|---|
| Azure AKS control plane | R$0 |
| Azure B2s spot node | ~R$45 |
| GCP GKE control plane | R$0 |
| GCP e2-small spot | ~R$15 |
| CockroachDB Serverless | R$0 |
| Cloudflare Workers | R$0 |
| **Total** | **~R$60/month** |

---

## Key Trade-offs

| Area       | Decision              | Trade-off                      |
| ---------- | --------------------- | ------------------------------ |
| Failover   | Active-Passive        | ~4 min downtime during switch  |
| Data       | CockroachDB multi-region | slight cross-cloud latency  |
| Networking | Public endpoints      | higher latency vs private      |
| CI/CD      | OIDC federation       | initial bootstrap complexity   |
| Compute    | Spot instances        | possible eviction (auto-replace) |

---

## Operational Philosophy

- Prefer simplicity over theoretical perfection
- Design for failure, not for ideal conditions
- Automate recovery wherever possible

---

## Anti-Patterns

- No multi-cloud without clear purpose
- No active-active without data strategy
- No hardcoded secrets
- No tight coupling between modules

---

## End Goal

This platform must demonstrate:

- real-world resilience patterns
- production-ready infrastructure design
- strong DevOps/SRE practices

It should answer: "Can this system survive failure without human intervention?"
