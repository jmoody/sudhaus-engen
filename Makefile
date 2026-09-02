# Makefile for engen-brews.
#
# This currently covers the Azure/Terraform workflow and a credential-free
# review gate. Build/test targets for the web service are added when its source
# lands. `make review` is the pre-flight check: it runs every verification step
# that works without live Azure credentials.

az-login:
	script/az-login

tfstate-bootstrap:
	script/tfstate-bootstrap

register-providers:
	script/register-providers

tf-init:
	script/terraform init $(ARGS)

plan:
	script/terraform plan $(ARGS)

apply:
	script/terraform apply $(ARGS)

terraform-lint:
	script/terraform-lint

shellcheck:
	@find script .github/skills -type f -exec sh -c 'for f in "$$@"; do if head -1 "$$f" | grep -qE "^#!.*bash"; then echo "shellcheck $$f"; shellcheck "$$f" || exit 1; fi; done' sh {} +

lint: shellcheck terraform-lint

review: lint

.PHONY: az-login tfstate-bootstrap register-providers tf-init plan apply terraform-lint shellcheck lint review
