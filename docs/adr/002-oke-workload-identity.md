# ADR-002: OKE Workload Identity for Pod-Level Access to OCI Services

## Status
Superseded — OCI replaced by Azure AKS as primary cloud (OCI free tier account activation unreliable). See ADR-008 for current AKS identity approach.

## Context

This ADR was written when OCI OKE was the primary cluster. The project has since migrated to Azure AKS + GCP GKE.

The OCI Workload Identity approach described here is architecturally sound but no longer applicable to this project.

## Original Decision

Use **OCI Workload Identity** bound to Kubernetes ServiceAccounts for pod-level OCI IAM.
