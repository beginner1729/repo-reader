#!/bin/bash
#
# OpenCode Configuration Validator
# Tests that all agent, subagent, and workflow files are properly formatted
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

ERRORS=0
WARNINGS=0

echo -e "${BLUE}🔍 OpenCode Configuration Validator${NC}"
echo "====================================="
echo ""
echo -e "${BLUE}📂 Testing directory:${NC} $OPENCODE_DIR"
echo ""

# Function to check if a file has valid YAML frontmatter
validate_yaml_frontmatter() {
    local file="$1"
    local basename=$(basename "$file")
    
    # Check if file starts with ---
    if ! head -1 "$file" | grep -q "^---$"; then
        echo -e "${RED}❌ $basename: Missing YAML frontmatter start (---)${NC}"
        return 1
    fi
    
    # Check if file has at least name field
    if ! grep -q "^name:" "$file"; then
        echo -e "${RED}❌ $basename: Missing 'name' field${NC}"
        return 1
    fi
    
    # Check if file has mode or type field
    if ! grep -qE "^(mode|type):" "$file"; then
        echo -e "${RED}❌ $basename: Missing 'mode' or 'type' field${NC}"
        return 1
    fi
    
    # Check if file has description field
    if ! grep -q "^description:" "$file"; then
        echo -e "${YELLOW}⚠️  $basename: Missing 'description' field${NC}"
        ((WARNINGS++))
    fi
    
    # Check if file has tools field (for agents and subagents)
    local file_mode=$(grep -E "^(mode|type):" "$file" | head -1 | cut -d':' -f2 | tr -d ' ')
    if [[ "$file_mode" == "agent" || "$file_mode" == "subagent" ]]; then
        if ! grep -q "^tools:" "$file"; then
            echo -e "${RED}❌ $basename: Missing 'tools' field (required for agents/subagents)${NC}"
            return 1
        fi
    fi
    
    # Check if file has inputs field (optional but recommended)
    if ! grep -q "^inputs:" "$file"; then
        echo -e "${YELLOW}⚠️  $basename: Missing 'inputs' field${NC}"
        ((WARNINGS++))
    fi
    
    echo -e "${GREEN}✅ $basename: Valid YAML frontmatter${NC}"
    return 0
}

# Function to validate agent file
validate_agent() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -e "${BLUE}Testing agent:${NC} $basename"
    
    if validate_yaml_frontmatter "$file"; then
        # Additional agent-specific checks
        local agent_mode=$(grep -E "^(mode|type):" "$file" | head -1 | cut -d':' -f2 | tr -d ' ')
        
        if [[ "$agent_mode" != "agent" && "$agent_mode" != "subagent" ]]; then
            echo -e "${RED}❌ $basename: Mode should be 'agent' or 'subagent', found '$agent_mode'${NC}"
            ((ERRORS++))
        fi
        
        # Check for instructions
        if ! grep -q "^instructions:" "$file"; then
            echo -e "${YELLOW}⚠️  $basename: Missing 'instructions' field${NC}"
            ((WARNINGS++))
        fi
    else
        ((ERRORS++))
    fi
    echo ""
}

# Function to validate subagent file
validate_subagent() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -e "${BLUE}Testing subagent:${NC} $basename"
    
    if validate_yaml_frontmatter "$file"; then
        # Additional subagent-specific checks
        local agent_mode=$(grep -E "^(mode|type):" "$file" | head -1 | cut -d':' -f2 | tr -d ' ')
        
        if [[ "$agent_mode" != "subagent" && "$agent_mode" != "agent" ]]; then
            echo -e "${RED}❌ $basename: Mode should be 'subagent' or 'agent', found '$agent_mode'${NC}"
            ((ERRORS++))
        fi
        
        # Check for instructions
        if ! grep -q "^instructions:" "$file"; then
            echo -e "${YELLOW}⚠️  $basename: Missing 'instructions' field${NC}"
            ((WARNINGS++))
        fi
    else
        ((ERRORS++))
    fi
    echo ""
}

# Function to validate workflow file
validate_workflow() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -e "${BLUE}Testing workflow:${NC} $basename"
    
    if validate_yaml_frontmatter "$file"; then
        # Additional workflow-specific checks
        local agent_type=$(grep "^type:" "$file" | head -1 | cut -d':' -f2 | tr -d ' ')
        
        if [[ "$agent_type" != "workflow" ]]; then
            echo -e "${YELLOW}⚠️  $basename: Type should be 'workflow', found '$agent_type' (note: workflows may not be supported in latest opencode)${NC}"
            ((WARNINGS++))
        fi
        
        # Check for steps
        if ! grep -q "^steps:" "$file"; then
            echo -e "${RED}❌ $basename: Missing 'steps' field (required for workflows)${NC}"
            ((ERRORS++))
        fi
        
        # Check for outputs
        if ! grep -q "^outputs:" "$file"; then
            echo -e "${YELLOW}⚠️  $basename: Missing 'outputs' field${NC}"
            ((WARNINGS++))
        fi
    else
        ((ERRORS++))
    fi
    echo ""
}

echo -e "${BLUE}📋 Validating Agents...${NC}"
echo "------------------------"

# Validate agents
if [ -d "$OPENCODE_DIR/agents" ]; then
    for agent_file in "$OPENCODE_DIR"/agents/*.md; do
        if [ -f "$agent_file" ]; then
            validate_agent "$agent_file"
        fi
    done
else
    echo -e "${RED}❌ Agents directory not found: $OPENCODE_DIR/agents${NC}"
    ((ERRORS++))
fi

echo -e "${BLUE}📋 Validating Subagents...${NC}"
echo "---------------------------"

# Validate subagents
if [ -d "$OPENCODE_DIR/subagents" ]; then
    for subagent_file in "$OPENCODE_DIR"/subagents/*.md; do
        if [ -f "$subagent_file" ]; then
            validate_subagent "$subagent_file"
        fi
    done
else
    echo -e "${RED}❌ Subagents directory not found: $OPENCODE_DIR/subagents${NC}"
    ((ERRORS++))
fi

echo -e "${BLUE}📋 Validating Workflows...${NC}"
echo "---------------------------"

# Validate workflows
if [ -d "$OPENCODE_DIR/workflows" ]; then
    for workflow_file in "$OPENCODE_DIR"/workflows/*.md; do
        if [ -f "$workflow_file" ]; then
            validate_workflow "$workflow_file"
        fi
    done
else
    echo -e "${RED}❌ Workflows directory not found: $OPENCODE_DIR/workflows${NC}"
    ((ERRORS++))
fi

echo ""
echo "====================================="
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "====================================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo -e "   Errors: $ERRORS"
    echo -e "   Warnings: $WARNINGS"
    
    if [ $WARNINGS -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}💡 Note: Warnings are non-critical but recommended to fix${NC}"
    fi
    
    exit 0
else
    echo -e "${RED}❌ Validation failed with $ERRORS error(s)${NC}"
    echo -e "   Errors: $ERRORS"
    echo -e "   Warnings: $WARNINGS"
    exit 1
fi
