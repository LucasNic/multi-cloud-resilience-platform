.PHONY: help plan apply destroy fmt lint security cost clean

CLOUD ?= azure
ENV ?= dev

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

plan: ## Terragrunt plan (CLOUD=azure|gcp|shared)
	cd live/$(CLOUD) && terragrunt run-all plan --terragrunt-non-interactive

apply: ## Terragrunt apply
	cd live/$(CLOUD) && terragrunt run-all apply --terragrunt-non-interactive

destroy: ## Terragrunt destroy
	cd live/$(CLOUD) && terragrunt run-all destroy --terragrunt-non-interactive

plan-all: ## Plan all clouds
	cd live && terragrunt run-all plan --terragrunt-non-interactive

fmt: ## Format Terraform
	terraform fmt -recursive modules/

lint: ## TFLint all modules
	@find modules -name "*.tf" -exec dirname {} \; | sort -u | while read d; do tflint --chdir="$$d" || true; done

security: ## Checkov scan
	checkov -d modules/ --framework terraform --soft-fail

cost: ## Infracost estimate
	infracost breakdown --path=live/ --terraform-binary=terragrunt

ci-local: fmt lint security ## Full local CI

plan-aks: ## Plan AKS only
	$(MAKE) plan CLOUD=azure

plan-gke: ## Plan GKE only
	$(MAKE) plan CLOUD=gcp

failover-test: ## Simulate failover (scale AKS to 0)
	@echo "Scaling AKS deployment to 0 to trigger Cloudflare Worker failover..."
	@echo "kubectl --context aks scale deployment/api -n app --replicas=0"

clean: ## Remove caches
	find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
