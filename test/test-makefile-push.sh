#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Makefile Push Target Verification Test                       ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Test 1: Verify push target exists
echo -e "${YELLOW}[1/4] Verifying 'push' target exists in Makefile...${NC}"
if grep -q "^push:" Makefile; then
    echo -e "${GREEN}✓ Push target found${NC}"
else
    echo -e "${RED}✗ Push target not found in Makefile${NC}"
    exit 1
fi

# Test 2: Verify registry variables are set
echo -e "\n${YELLOW}[2/4] Verifying registry variables...${NC}"
if grep -q "REGISTRY ?= ghcr.io" Makefile; then
    echo -e "${GREEN}✓ REGISTRY variable found${NC}"
else
    echo -e "${RED}✗ REGISTRY variable not found${NC}"
    exit 1
fi

if grep -q "REGISTRY_IMAGE ?=" Makefile; then
    echo -e "${GREEN}✓ REGISTRY_IMAGE variable found${NC}"
else
    echo -e "${RED}✗ REGISTRY_IMAGE variable not found${NC}"
    exit 1
fi

# Test 3: Dry run of push target (without TAG)
echo -e "\n${YELLOW}[3/4] Testing push target dry run (without TAG)...${NC}"
output=$(make -n push 2>&1)
if echo "$output" | grep -q "ghcr.io/tgboyles/ollama-mcp-custom:latest"; then
    echo -e "${GREEN}✓ Push target generates correct registry path${NC}"
else
    echo -e "${RED}✗ Push target does not generate expected output${NC}"
    echo "$output"
    exit 1
fi

# Test 4: Dry run of push target (with TAG)
echo -e "\n${YELLOW}[4/4] Testing push target dry run (with TAG=v1.0.0)...${NC}"
output=$(make -n push TAG=v1.0.0 2>&1)
if echo "$output" | grep -q "ghcr.io/tgboyles/ollama-mcp-custom:v1.0.0"; then
    echo -e "${GREEN}✓ Push target with TAG generates correct versioned tag${NC}"
else
    echo -e "${RED}✗ Push target with TAG does not generate expected output${NC}"
    echo "$output"
    exit 1
fi

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  All Makefile push target tests passed! ✓                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
