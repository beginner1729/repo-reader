#!/bin/bash
#
# Install Test Dependencies
# Installs required tools for testing OpenCode configurations
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Installing Test Dependencies${NC}"
echo "================================="
echo ""

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    PACKAGE_MANAGER="apt-get"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    PACKAGE_MANAGER="brew"
else
    echo -e "${YELLOW}⚠️  Unknown OS: $OSTYPE${NC}"
    OS="unknown"
fi

echo -e "${BLUE}Detected OS:${NC} $OS"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install yq
echo -e "${BLUE}📦 Checking for yq (YAML processor)...${NC}"
if command_exists yq; then
    echo -e "${GREEN}✅ yq already installed${NC}"
    yq --version
else
    echo -e "${YELLOW}⚠️  yq not found. Installing...${NC}"
    
    if [ "$OS" = "macos" ]; then
        if command_exists brew; then
            brew install yq
        else
            echo -e "${RED}❌ Homebrew not found. Please install Homebrew first.${NC}"
            echo "   Visit: https://brew.sh"
        fi
    elif [ "$OS" = "linux" ]; then
        echo -e "${BLUE}Downloading yq...${NC}"
        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod +x /usr/local/bin/yq
        echo -e "${GREEN}✅ yq installed to /usr/local/bin/yq${NC}"
    else
        echo -e "${YELLOW}⚠️  Please install yq manually:${NC}"
        echo "   Visit: https://github.com/mikefarah/yq/releases"
    fi
fi
echo ""

# Check for Python
echo -e "${BLUE}📦 Checking for Python...${NC}"
if command_exists python3; then
    echo -e "${GREEN}✅ python3 found${NC}"
    python3 --version
elif command_exists python; then
    echo -e "${GREEN}✅ python found${NC}"
    python --version
else
    echo -e "${YELLOW}⚠️  Python not found. Installing...${NC}"
    
    if [ "$OS" = "macos" ]; then
        if command_exists brew; then
            brew install python
        else
            echo -e "${RED}❌ Please install Python manually${NC}"
        fi
    elif [ "$OS" = "linux" ]; then
        sudo apt-get update
        sudo apt-get install -y python3
    else
        echo -e "${YELLOW}⚠️  Please install Python manually${NC}"
        echo "   Visit: https://www.python.org/downloads/"
    fi
fi
echo ""

# Check for OpenCode CLI
echo -e "${BLUE}📦 Checking for OpenCode CLI...${NC}"
if command_exists opencode; then
    echo -e "${GREEN}✅ OpenCode CLI already installed${NC}"
    opencode --version
else
    echo -e "${YELLOW}⚠️  OpenCode CLI not found.${NC}"
    echo ""
    echo -e "${BLUE}To install OpenCode CLI, run one of:${NC}"
    echo "  npm install -g @opencode/cli"
    echo "  or"
    echo "  pip install opencode-cli"
    echo ""
    echo -e "${YELLOW}⚠️  Note: CLI is optional for basic tests, required for full integration tests${NC}"
fi
echo ""

# Summary
echo "================================="
echo -e "${GREEN}✅ Dependency installation complete!${NC}"
echo ""
echo -e "${BLUE}You can now run tests:${NC}"
echo "  ./tests/run-all-tests.sh"
