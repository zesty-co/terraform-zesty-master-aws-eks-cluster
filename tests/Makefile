SHELL := /bin/bash

SIMPLE_TF       := ../examples/simple-terraform
MC_ACCOUNT_TF   := ../examples/multi-clusters-terraform/account
MC_PROD_TF      := ../examples/multi-clusters-terraform/kompass-eks-prod
MC_STAGING_TF   := ../examples/multi-clusters-terraform/kompass-eks-staging
MC_DATA_TF      := ../examples/multi-clusters-terraform/kompass-eks-data

SIMPLE_TG_ZESTY := ../examples/simple-terragrunt/live/prod/aws/us-east-1/my-account/zesty
MC_TG_ZESTY     := ../examples/multi-clusters-terragrunt/live/prod/aws/us-east-1/my-account/zesty

.PHONY: validate validate-simple validate-mc-account validate-mc-prod validate-mc-staging validate-mc-data

validate: validate-simple validate-mc-account validate-mc-prod validate-mc-staging validate-mc-data
	@echo "All examples validated successfully."

validate-simple:
	@echo "-- validate: simple-terraform --"
	cd $(SIMPLE_TF) && terraform init -backend=false && terraform validate

validate-mc-account:
	@echo "-- validate: multi-clusters-terraform/account --"
	cd $(MC_ACCOUNT_TF) && terraform init -backend=false && terraform validate

validate-mc-prod:
	@echo "-- validate: multi-clusters-terraform/kompass-eks-prod --"
	cd $(MC_PROD_TF) && terraform init -backend=false && terraform validate

validate-mc-staging:
	@echo "-- validate: multi-clusters-terraform/kompass-eks-staging --"
	cd $(MC_STAGING_TF) && terraform init -backend=false && terraform validate

validate-mc-data:
	@echo "-- validate: multi-clusters-terraform/kompass-eks-data --"
	cd $(MC_DATA_TF) && terraform init -backend=false && terraform validate

.PHONY: test-tf test-tf-mc-prod test-tf-mc-staging test-tf-mc-data

test-tf: test-tf-mc-prod test-tf-mc-staging test-tf-mc-data
	@echo "All terraform tests passed."

test-tf-mc-prod:
	@echo "-- terraform test: multi-clusters-terraform/kompass-eks-prod --"
	cd $(MC_PROD_TF) && terraform init -backend=false && terraform test

test-tf-mc-staging:
	@echo "-- terraform test: multi-clusters-terraform/kompass-eks-staging --"
	cd $(MC_STAGING_TF) && terraform init -backend=false && terraform test

test-tf-mc-data:
	@echo "-- terraform test: multi-clusters-terraform/kompass-eks-data --"
	cd $(MC_DATA_TF) && terraform init -backend=false && terraform test

.PHONY: validate-tg validate-tg-simple validate-tg-mc

validate-tg: validate-tg-simple validate-tg-mc
	@echo "All Terragrunt examples validated successfully."

validate-tg-simple:
	@echo "-- terragrunt validate: simple-terragrunt --"
	terragrunt hcl validate --working-dir $(SIMPLE_TG_ZESTY)

validate-tg-mc:
	@echo "-- terragrunt validate: multi-clusters-terragrunt --"
	terragrunt hcl validate --working-dir $(MC_TG_ZESTY)

# --- Terratest E2E --- Terraform ---

.PHONY: test-e2e-tf test-e2e-tf-simple test-e2e-tf-mc

test-e2e-tf: test-e2e-tf-simple test-e2e-tf-mc
	@echo "All Terraform E2E tests passed."

test-e2e-tf-simple:
	@echo "-- Terratest E2E: simple-terraform --"
	cd terratest && CLUSTER_NAME=$(CLUSTER_NAME) go test -v -run TestSimpleExample -timeout 30m

test-e2e-tf-mc:
	@echo "-- Terratest E2E: multi-clusters-terraform --"
	cd terratest && CLUSTER_NAME=$(CLUSTER_NAME) go test -v -run TestMultiClusterFullE2E -timeout 45m

# --- Terratest E2E --- Terragrunt ---

.PHONY: test-e2e-tg test-e2e-tg-simple test-e2e-tg-mc

test-e2e-tg: test-e2e-tg-simple test-e2e-tg-mc
	@echo "All Terragrunt E2E tests passed."

test-e2e-tg-simple:
	@echo "-- Terratest E2E: simple-terragrunt --"
	cd terratest && CLUSTER_NAME=$(CLUSTER_NAME) go test -v -run TestSimpleTerragruntFullE2E -timeout 45m

test-e2e-tg-mc:
	@echo "-- Terratest E2E: multi-clusters-terragrunt (run-all) --"
	cd terratest && go test -v -run TestMultiClusterTerragruntRunAll -timeout 45m

# --- Run everything ---

.PHONY: test-e2e-all

test-e2e-all: test-e2e-tf test-e2e-tg
	@echo "All E2E tests passed."

# --- Cleanup ---

.PHONY: clean

clean:
	find ../examples -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find ../examples -name ".terragrunt-cache" -type d -exec rm -rf {} + 2>/dev/null || true
	find ../examples -name "*.tfstate*" -type f -delete 2>/dev/null || true
	find ../examples -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true
	@echo "Cleaned up."
