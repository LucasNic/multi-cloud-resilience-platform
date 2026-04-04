# ADR-004: OIDC Federation for CI/CD Authentication

## Status
Accepted (updated: OCI replaced by Azure)

## Context

GitHub Actions needs to authenticate against Azure and GCP to run Terraform and
deploy workloads. Options:
1. **Stored credentials**: Access keys/service account keys stored as GitHub Secrets
2. **OIDC federation**: GitHub Actions presents a short-lived JWT, cloud validates it

## Decision

Use **OIDC federation** for all cloud authentication in GitHub Actions. Zero stored keys.

### Implementation per Cloud

**Azure**
- Create an Azure AD Application with federated identity credentials
- Configure the OIDC issuer (`token.actions.githubusercontent.com`) as trusted
- Bind a Service Principal with Contributor role
- Restrict to specific repo + branch via subject claim
- Terraform authenticates via `ARM_USE_OIDC=true` environment variable

**GCP**
- Create a Workload Identity Pool in GCP IAM
- Create a provider within the pool for GitHub Actions OIDC
- Bind a GCP Service Account to the pool with attribute conditions
- Restrict to specific repo + branch

### Subject Restriction

All OIDC configurations restrict to:
- `repo:LucasNic/multi-cloud-resilience-platform:ref:refs/heads/main` (apply)
- `repo:LucasNic/multi-cloud-resilience-platform:pull_request` (plan only)

### Bootstrap Problem

OIDC setup itself requires one-time local authentication (chicken-and-egg).
Documented in `bootstrap/README.md`.

## Trade-offs

- (+) Zero stored secrets — nothing to leak or rotate
- (+) Credentials scoped per-job, expire in 1 hour automatically
- (+) Auditable: cloud logs show exactly which workflow run authenticated
- (+) Consistent pattern across both Azure and GCP
- (-) Bootstrap requires one-time local auth with elevated permissions
