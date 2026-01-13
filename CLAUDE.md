# Docker Build Best Practices for Ollama MCP Bridge

This document provides instructions and best practices for building Docker containers for this project, based on [Docker's official best practices](https://docs.docker.com/build/building/best-practices/).

## Table of Contents

- [General Principles](#general-principles)
- [Multi-Stage Builds](#multi-stage-builds)
- [Base Image Selection](#base-image-selection)
- [Keeping Images Updated](#keeping-images-updated)
- [Image Efficiency](#image-efficiency)
- [Dockerfile Instructions Best Practices](#dockerfile-instructions-best-practices)
- [Project-Specific Guidelines](#project-specific-guidelines)

## General Principles

### Use Multi-Stage Builds

Multi-stage builds help reduce the size of your final image by creating a cleaner separation between building and the final output. Split your Dockerfile into distinct stages to ensure the resulting image only contains files needed to run the application.

Benefits:
- Smaller final image size
- Better separation of build-time and runtime dependencies
- More efficient builds through parallel execution

### Create Reusable Stages

If you have multiple images with common components, create a reusable stage for shared components. Docker only needs to build the common stage once, making derivative images more memory-efficient and faster to load.

### Use .dockerignore Files

Exclude files not relevant to the build using a `.dockerignore` file. This prevents unnecessary files from being sent to the build context.

**Current .dockerignore configuration:**
```
.git
.gitignore
*.md
.github
Makefile
mcp-config.json
mcp-config.json.example
```

## Base Image Selection

### Choose Trusted Base Images

Always choose base images from trusted sources:
- **Docker Official Images** - Curated, documented, and regularly updated
- **Verified Publisher** - High-quality images from Docker partners
- **Docker-Sponsored Open Source** - Maintained by Docker-sponsored projects

**Current project:** Uses `ollama/ollama:latest` (official Ollama image)

### Keep Base Images Minimal

Choose minimal base images that match your requirements:
- Smaller images offer better portability and faster downloads
- Reduced attack surface with fewer dependencies
- Consider using Alpine-based images where appropriate

### Use Specific Tags, Not Latest

Avoid using `:latest` tag in production. Instead:
- Use specific version tags (e.g., `ollama:0.1.0`)
- Pin to specific digests for supply chain security
- Balance between stability and security updates

**Current Dockerfile uses:** `ollama/ollama:latest` - consider pinning to specific version

## Keeping Images Updated

### Rebuild Images Regularly

Rebuild images regularly to get updated dependencies and security patches.

### Use --pull Flag

Use `docker build --pull` to ensure you get the latest base image:
```bash
docker build --pull -t ollama-mcp-custom .
```

### Use --no-cache for Clean Builds

For clean builds with latest package versions:
```bash
docker build --no-cache -t ollama-mcp-custom .
```

For completely fresh builds:
```bash
docker build --pull --no-cache -t ollama-mcp-custom .
```

## Image Efficiency

### Create Ephemeral Containers

Containers should be:
- Stoppable and destroyable at any time
- Rebuildable with minimal setup
- Stateless when possible (use volumes for persistent data)

**Current project:** Uses volumes for persistent model storage (`ollama-data:/root/.ollama`)

### Avoid Unnecessary Packages

Don't install packages "just in case" - only include what's needed:
- Reduces complexity
- Reduces dependencies
- Smaller file sizes
- Faster build times

### One Concern Per Container

Each container should have one primary concern. This project follows this principle:
- Ollama server (AI model serving)
- MCP bridge (protocol bridge)
- Both are tightly coupled and run in the same container appropriately

### Sort Multi-Line Arguments

Sort multi-line arguments alphanumerically to:
- Avoid package duplication
- Make updates easier
- Improve PR readability

Example:
```dockerfile
RUN apt-get update && apt-get install -y \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

## Dockerfile Instructions Best Practices

### FROM

- Use current official images as base
- Alpine images are recommended for size (under 6 MB)
- **Current:** `ollama/ollama:latest` is appropriate for this project

### LABEL

Add labels to organize images and record metadata:
```dockerfile
LABEL org.opencontainers.image.authors="Your Name"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.description="Ollama with MCP Bridge"
```

### RUN

**Best practices for RUN:**

1. **Split long commands** across multiple lines with backslashes:
```dockerfile
RUN apt-get update && \
    apt-get install -y package1 package2 && \
    apt-get clean
```

2. **Chain related commands** with `&&`:
```dockerfile
RUN apt-get update && apt-get install -y python3 && apt-get clean
```

3. **For apt-get:**
   - Always combine `apt-get update` with `apt-get install` in the same RUN
   - Use `--no-install-recommends` to avoid extra packages
   - Clean up with `apt-get clean` and `rm -rf /var/lib/apt/lists/*`
   - Pin package versions when needed for reproducibility

**Example (from current Dockerfile):**
```dockerfile
RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

4. **For pipes, use `set -o pipefail`:**
```dockerfile
RUN set -o pipefail && \
    wget -O - https://example.com/file | wc -l > /number
```

### CMD

- Use to run the main software in the image
- Prefer exec form: `CMD ["executable", "param1", "param2"]`
- For service images: `CMD ["apache2", "-DFOREGROUND"]`
- Can be overridden by `docker run` arguments

### EXPOSE

- Document which ports the container listens on
- Use standard ports (80 for HTTP, 27017 for MongoDB, etc.)
- **Current:** `EXPOSE 11434` (standard Ollama port)

### ENV

- Use ENV to update PATH for installed software
- Set commonly used version numbers as ENV variables
- Be aware each ENV creates a new layer

**Good use:**
```dockerfile
ENV PATH=/usr/local/nginx/bin:$PATH
ENV PYTHON_VERSION=3.10
```

**Current Dockerfile:**
```dockerfile
ENV PATH="/opt/venv/bin:$PATH"
```

### ADD or COPY

- **COPY** for basic file copying (preferred for most use cases)
- **ADD** for remote URLs and automatic tar extraction
- Consider bind mounts for temporary build files
- Use COPY for multi-stage builds

**Current Dockerfile:**
```dockerfile
COPY entrypoint.sh /app/entrypoint.sh
```

### ENTRYPOINT

- Set the image's main command
- Use with CMD for default flags
- Can use helper scripts for complex startup logic

**Current Dockerfile:**
```dockerfile
ENTRYPOINT ["/app/entrypoint.sh"]
```

### VOLUME

- Expose database storage, configuration, or mutable data
- **Current:** Project uses volumes via docker-compose for persistence

### USER

- Run services as non-root when possible
- Create user/group explicitly:
```dockerfile
RUN groupadd -r myapp && useradd -r -g myapp myapp
USER myapp
```

**Note:** Current Dockerfile runs as root (required for Ollama)

### WORKDIR

- Always use absolute paths
- Prefer WORKDIR over `RUN cd ... && ...`
- Improves readability and reliability

## Project-Specific Guidelines

### Building the Image

**Standard build:**
```bash
make build
```

**Fresh build with latest base image:**
```bash
docker build --pull -t ollama-mcp-custom .
```

**Clean build (no cache):**
```bash
docker build --no-cache -t ollama-mcp-custom .
```

**Complete fresh build:**
```bash
docker build --pull --no-cache -t ollama-mcp-custom .
```

### Model Preloading

The Dockerfile preloads the `gemma3` model at build time:
- Reduces startup time
- Ensures model availability
- Makes deployment predictable
- Model is baked into the image layers

### Virtual Environment

Python packages are installed in a virtual environment at `/opt/venv`:
- Provides package isolation
- Prevents conflicts with system Python
- Added to PATH via ENV instruction

### Cache Busting Strategy

The current Dockerfile implements cache busting for:
- Package installations (combined `apt-get update && install`)
- Python package installations via pip
- Model pulling during build

### Multi-Process Container

This container runs multiple processes:
1. Ollama server (background)
2. MCP bridge (background, conditional)

This is acceptable as they are tightly coupled and form a single logical service.

### Health Checks

The entrypoint script includes health checking:
- Waits for Ollama to be ready (30 retries × 2s)
- Verifies API accessibility
- Exits with error if startup fails

### Testing Changes

Always test Docker changes:

1. **Build the image:**
```bash
make build
```

2. **Run tests:**
```bash
make test
```

3. **Manual verification:**
```bash
make run
make logs
curl http://localhost:11434/api/version
```

### Continuous Integration

- Tests run automatically via GitHub Actions
- Validates complete stack on clean environment
- Defined in `.github/workflows/test.yml`

## Common Build Commands

```bash
# Standard build
make build

# Run container
make run

# View logs
make logs

# Stop container
make stop

# Run tests
make test

# Clean rebuild
make clean && make build

# Access container shell
make shell
```

## Best Practices Checklist

When modifying the Dockerfile, ensure:

- [ ] Base image is from a trusted source
- [ ] .dockerignore excludes unnecessary files
- [ ] RUN instructions combine related commands with &&
- [ ] apt-get update and install are in the same RUN statement
- [ ] Package cache is cleaned up (apt-get clean, rm -rf /var/lib/apt/lists/*)
- [ ] Multi-line commands are sorted alphabetically
- [ ] Long commands use line continuations (\)
- [ ] EXPOSE uses standard ports
- [ ] Critical paths use absolute paths
- [ ] Secrets are not committed to the image
- [ ] Image builds successfully
- [ ] Tests pass
- [ ] Documentation is updated

## Security Considerations

1. **Don't commit secrets** to the image
2. **Keep base images updated** - rebuild regularly
3. **Use specific versions** rather than :latest in production
4. **Minimize attack surface** - only install necessary packages
5. **Scan images** for vulnerabilities regularly
6. **Run as non-root** when possible (Ollama requires root)
7. **Use read-only mounts** for configuration files

## References

- [Docker Build Best Practices](https://docs.docker.com/build/building/best-practices/)
- [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/)
- [Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Docker Build Cache](https://docs.docker.com/build/cache/)
- [Ollama Documentation](https://github.com/ollama/ollama)
- [Model Context Protocol](https://github.com/modelcontextprotocol)

## Updates and Maintenance

This document should be reviewed and updated:
- When Docker best practices change
- When significant Dockerfile changes are made
- When new security considerations emerge
- At least quarterly to ensure relevance

**Last Updated:** 2026-01-13
