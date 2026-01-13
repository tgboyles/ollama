.PHONY: build run stop clean help test push

# Variables
IMAGE_NAME = ollama-mcp-custom
CONTAINER_NAME = ollama-mcp-bridge
DOCKER_REPO = frugalfox/ollama-mcp-custom
TAG ?= latest

help:
	@echo "Available commands:"
	@echo "  make build     - Build the Docker image"
	@echo "  make run       - Run the container using docker-compose"
	@echo "  make stop      - Stop the running container"
	@echo "  make clean     - Remove container and image"
	@echo "  make logs      - Show container logs"
	@echo "  make shell     - Open a shell in the running container"
	@echo "  make test      - Run integration tests"
	@echo "  make push      - Push the Docker image to Docker Hub (TAG=tagname)"

build:
	docker build -t $(IMAGE_NAME) .

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
	@cd test && ./integration-test.sh

push:
	@echo "Tagging image as $(DOCKER_REPO):$(TAG)..."
	docker tag $(IMAGE_NAME) $(DOCKER_REPO):$(TAG)
	@echo "Pushing $(DOCKER_REPO):$(TAG) to Docker Hub..."
	docker push $(DOCKER_REPO):$(TAG)
