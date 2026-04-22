#!/bin/bash
#
# Quick Test Runner
# Runs all tests with a single command
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OPENCODE_DIR="${1:-$PROJECT_ROOT/.opencode}"

TOTAL_ERRORS=0

echo -e "${BLUE}🧪 OpenCode Test Suite${NC}"
echo "======================"
echo ""
echo -e "${BLUE}📂 Target directory:${NC} $OPENCODE_DIR"
echo ""

# Test 1: YAML Syntax
echo -e "${BLUE}Test 1/3: YAML Syntax Validation${NC}"
echo "---------------------------------"
if "$SCRIPT_DIR/test-yaml.sh" "$OPENCODE_DIR"; then
    echo -e "${GREEN}✅ YAML Syntax: PASSED${NC}"
else
    echo -e "${RED}❌ YAML Syntax: FAILED${NC}"
    ((TOTAL_ERRORS++))
fi
echo ""

# Test 2: Configuration Structure
echo -e "${BLUE}Test 2/3: Configuration Structure${NC}"
echo "----------------------------------"
if "$SCRIPT_DIR/validate-config.sh" "$OPENCODE_DIR"; then
    echo -e "${GREEN}✅ Configuration Structure: PASSED${NC}"
else
    echo -e "${RED}❌ Configuration Structure: FAILED${NC}"
    ((TOTAL_ERRORS++))
fi
echo ""

# Test 3: OpenCode CLI Integration (only if opencode is installed)
echo -e "${BLUE}Test 3/3: OpenCode CLI Integration${NC}"
echo "-----------------------------------"
if command -v opencode &> /dev/null; then
    if "$SCRIPT_DIR/test-opencode-cli.sh" "$OPENCODE_DIR"; then
        echo -e "${GREEN}✅ OpenCode CLI Integration: PASSED${NC}"
    else
        echo -e "${RED}❌ OpenCode CLI Integration: FAILED${NC}"
        ((TOTAL_ERRORS++))
    fi
else
    echo -e "${YELLOW}⚠️  OpenCode CLI Integration: SKIPPED (CLI not installed)${NC}"
    echo -e "${YELLOW}   Install OpenCode CLI to run this test${NC}"
fi
echo ""

# Final Summary
echo "======================"
echo -e "${BLUE}📊 Final Results${NC}"
echo "======================"

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    echo ""
    echo -e "${GREEN}✅ Your OpenCode configuration is valid and ready to use!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Run the workflow: opencode workflow run repo_reader_workflow"
    echo "  2. Or use the helper script: .opencode/run.sh"
    exit 0
else
    echo -e "${RED}❌ $TOTAL_ERRORS test suite(s) failed${NC}"
    echo ""
    echo -e "${YELLOW}💡 Check the error messages above for details${NC}"
    exit 1
fi
