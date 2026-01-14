.PHONY: build run stop clean help test push

# Variables
IMAGE_NAME = ollama-mcp-custom
CONTAINER_NAME = ollama-mcp-bridge
MODEL_NAME ?= gemma3
REGISTRY ?= ghcr.io
REGISTRY_IMAGE ?= $(REGISTRY)/tgboyles/ollama-mcp-custom

help:
	@echo "Available commands:"
	@echo "  make build              - Build the Docker image (default model: gemma3)"
	@echo "  make build MODEL_NAME=llama3 - Build with a specific model"
	@echo "  make run                - Run the container using docker-compose"
	@echo "  make stop               - Stop the running container"
	@echo "  make clean              - Remove container and image"
	@echo "  make logs               - Show container logs"
	@echo "  make shell              - Open a shell in the running container"
	@echo "  make test               - Run integration tests (default model: gemma3)"
	@echo "  make test MODEL_NAME=llama3 - Run tests with a specific model"
	@echo "  make push               - Tag and push image to container registry"

build:
	docker build --build-arg MODEL_NAME=$(MODEL_NAME) -t $(IMAGE_NAME) .

run:
	docker-compose up -d

stop:
	docker-compose down

clean:
	docker-compose down -v
	docker rmi $(IMAGE_NAME) 2>/dev/null || true

logs:
	docker-compose logs -f

shell:
	docker exec -it $(CONTAINER_NAME) /bin/bash

test:
	@echo "Running integration tests..."
	@cd test && MODEL_NAME=$(MODEL_NAME) ./integration-test.sh

push:
	@echo "Tagging image for registry..."
	docker tag $(IMAGE_NAME) $(REGISTRY_IMAGE):latest
	@if [ -n "$(TAG)" ]; then \
		echo "Tagging image with version $(TAG)..."; \
		docker tag $(IMAGE_NAME) $(REGISTRY_IMAGE):$(TAG); \
	fi
	@echo "Pushing image to registry..."
	docker push $(REGISTRY_IMAGE):latest
	@if [ -n "$(TAG)" ]; then \
		echo "Pushing tagged version $(TAG)..."; \
		docker push $(REGISTRY_IMAGE):$(TAG); \
	fi
	@echo "Image pushed successfully!"
