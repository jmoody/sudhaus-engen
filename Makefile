# Makefile for sudhaus-engen.
#
# This covers the web service build/run/test targets, the Azure/Terraform
# workflow, and a credential-free review gate. `make review` is the pre-flight
# check: it runs every verification step that works without live Azure
# credentials.

export GOPROXY := https://proxy.golang.org,direct
export GOSUMDB := sum.golang.org

bootstrap:
	script/bootstrap

run:
	go run ./cmd/sudhaus-engen

start: build
	@set -a; [ -f .env ] && . ./.env; set +a; ./bin/sudhaus-engen

stop:
	@set -a; [ -f .env ] && . ./.env; set +a; lsof -a -t -i :$${PORT:-8000} -c sudhaus-engen | xargs -r kill

clean:
	-[ -x bin/golangci-lint ] && bin/golangci-lint cache clean
	rm -rf bin
	rm -rf _tools
	go clean -cache -testcache

build: tidy imports
	go build -o bin/sudhaus-engen ./cmd/sudhaus-engen

imports:
	bin/goimports -local github.com/jmoody/sudhaus-engen -w cmd internal

test:
	go test -race ./...

docker-build:
	docker build $(ARGS) -t sudhaus-engen .

docker-run: docker-build
	docker run --rm -p 8000:8000 sudhaus-engen

tidy:
	go mod download
	go mod tidy

update:
	go get -u ./...
	go mod tidy

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
	@find script .github/skills .github/workflows/scripts -type f -exec sh -c 'for f in "$$@"; do if head -1 "$$f" | grep -qE "^#!.*bash"; then echo "shellcheck $$f"; shellcheck "$$f" || exit 1; fi; done' sh {} +

lint: build
	bin/golangci-lint run --max-issues-per-linter=0 --max-same-issues=0 ./...
	$(MAKE) shellcheck
	script/terraform-lint

lint-fix: build
	bin/golangci-lint run --fix --max-issues-per-linter=0 --max-same-issues=0 ./...

review: build imports lint test

.PHONY: bootstrap run start stop clean build imports test docker-build docker-run tidy update az-login tfstate-bootstrap register-providers tf-init plan apply terraform-lint shellcheck lint lint-fix review
