# ADR-008: AKS System-Assigned Managed Identity over Service Principal

## Status
Accepted (reactivated — previously superseded when project used OCI)

## Context

The project migrated from OCI OKE to Azure AKS as the primary cluster.
OCI's free tier account activation was unreliable, blocking project progress.
Azure AKS provides a free control plane with spot node support.

## Decision
Use `identity { type = "SystemAssigned" }` for all AKS clusters.

> "We recommend using managed identities for AKS."
> — [Microsoft Docs](https://learn.microsoft.com/en-us/azure/aks/use-managed-identity)

### Why
- No client secret to rotate (90-day expiry eliminated)
- Identity destroyed with cluster (zero orphaned creds)
- Follows Azure Well-Architected Framework, Security Pillar
- Terraform: native azurerm, no azuread provider needed for cluster identity
- Consistent with project's zero-stored-secrets principle (ADR-004)

### Role Assignments Required
- **Network Contributor** on VNet (LB/NSG management)
- **AcrPull** on ACR (image pulls via kubelet identity) — if using ACR in the future

## Pod-Level Identity

For pod-level identity (equivalent to EKS IRSA / OKE Workload Identity):
- AKS has `workload_identity_enabled = true` + OIDC issuer
- Pods annotate their ServiceAccount with `azure.workload.identity/client-id`
- Azure AD Workload Identity injects tokens automatically
