# Bootstrap Guide

This guide covers everything needed before the CI/CD pipeline can run.

Bootstrap is a one-time process. After it's done, all future changes go through GitHub Actions automatically.

---

## Overview

The pipeline authenticates against Azure and GCP via OIDC (no stored keys).
But to *create* the OIDC resources, you need to authenticate locally first — this is the bootstrap chicken-and-egg problem.

**Order:**
1. Collect credentials from each platform
2. Configure GitHub Secrets
3. Run bootstrap apply locally (Azure + GCP OIDC modules)
4. From this point on, CI/CD handles everything

---

## Step 1 — Azure credentials

### 1.1 — Install Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
```

### 1.2 — Collect the values

| Value | Where to find |
|---|---|
| `AZURE_SUBSCRIPTION_ID` | `az account show --query id -o tsv` |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_CLIENT_ID` | Output of `live/azure/eastus/dev/oidc-github` after bootstrap apply |

---

## Step 2 — GCP credentials

### 2.1 — Install gcloud CLI

```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
gcloud auth application-default login
```

### 2.2 — Create a GCP project (if you don't have one)

```bash
gcloud projects create multi-cloud-portfolio --name="Multi Cloud Portfolio"
gcloud config set project multi-cloud-portfolio
```

Enable required APIs:

```bash
gcloud services enable \
  container.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  sts.googleapis.com
```

### 2.3 — Collect the values

| Secret | Where to find |
|---|---|
| `GCP_PROJECT_ID` | `gcloud config get-value project` |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Output of `live/gcp/us-central1/dev/oidc-github` after bootstrap apply |
| `GCP_SERVICE_ACCOUNT_EMAIL` | Output of `live/gcp/us-central1/dev/oidc-github` after bootstrap apply |

---

## Step 3 — Cloudflare credentials

1. Create a free account at cloudflare.com
2. Add your domain `lucasnicoloso.com` (change nameservers at your registrar to Cloudflare's)
3. Collect:

| Secret | Where to find |
|---|---|
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare Dashboard → right sidebar → Account ID |
| `CLOUDFLARE_API_TOKEN` | Cloudflare → Profile → API Tokens → Create Token → use "Edit zone DNS" template + add "Workers Scripts: Edit" permission |

---

## Step 4 — CockroachDB credentials

1. Create a free account at cockroachlabs.com
2. No values to collect yet — the cluster is created by Terraform
3. Just define a strong password:

| Secret | Value |
|---|---|
| `COCKROACHDB_PASSWORD` | define a strong password (min 12 chars) |

---

## Step 5 — Configure GitHub Secrets

Go to: `github.com/LucasNic/multi-cloud-resilience-platform → Settings → Secrets and variables → Actions`

Add all secrets from the table below:

| Secret | Source |
|---|---|
| `AZURE_SUBSCRIPTION_ID` | Step 1.2 |
| `AZURE_TENANT_ID` | Step 1.2 |
| `AZURE_CLIENT_ID` | Step 7 (after bootstrap apply) |
| `GCP_PROJECT_ID` | Step 2.3 |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Step 7 (after bootstrap apply) |
| `GCP_SERVICE_ACCOUNT_EMAIL` | Step 7 (after bootstrap apply) |
| `CLOUDFLARE_ACCOUNT_ID` | Step 3 |
| `CLOUDFLARE_API_TOKEN` | Step 3 |
| `COCKROACHDB_PASSWORD` | Step 4 |

---

## Step 6 — Bootstrap apply (local, one-time)

Install required tools:

```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# Terragrunt
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.55.0/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64 && sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
```

Run bootstrap apply:

```bash
# Azure OIDC (enables GitHub Actions to authenticate against Azure)
cd live/azure/eastus/dev/oidc-github
terragrunt apply

# Azure networking (required before AKS)
cd live/azure/eastus/dev/networking
terragrunt apply

# GCP networking (required before GKE)
cd live/gcp/us-central1/dev/networking
terragrunt apply

# GCP OIDC (enables GitHub Actions to authenticate against GCP)
cd live/gcp/us-central1/dev/oidc-github
terragrunt apply
```

---

## Step 7 — Collect OIDC outputs

After the bootstrap applies complete:

```bash
# Azure
cd live/azure/eastus/dev/oidc-github
terragrunt output client_id        # → AZURE_CLIENT_ID
terragrunt output tenant_id        # → AZURE_TENANT_ID
terragrunt output subscription_id  # → AZURE_SUBSCRIPTION_ID

# GCP
cd live/gcp/us-central1/dev/oidc-github
terragrunt output workload_identity_provider  # → GCP_WORKLOAD_IDENTITY_PROVIDER
terragrunt output service_account_email       # → GCP_SERVICE_ACCOUNT_EMAIL
```

Copy these values and add them as GitHub Secrets.

---

## Step 8 — Done

From this point on, the CI/CD pipeline handles everything:

- **Pull Request** → lint + security scan + plan
- **Merge to main** → apply (Azure → GCP → shared)

No more local applies needed.
