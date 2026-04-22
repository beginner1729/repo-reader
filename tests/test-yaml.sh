#!/bin/bash
#
# YAML Syntax Tester
# Validates YAML syntax of all configuration files
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

echo -e "${BLUE}🔍 YAML Syntax Tester${NC}"
echo "====================="
echo ""
echo -e "${BLUE}📂 Testing directory:${NC} $OPENCODE_DIR"
echo ""

# Check if yq or python is available for YAML parsing
check_yaml_parser() {
    if command -v yq &> /dev/null; then
        echo -e "${GREEN}✅ Found yq (YAML processor)${NC}"
        YAML_PARSER="yq"
    elif command -v python3 &> /dev/null; then
        # Check if PyYAML is installed
        if python3 -c "import yaml" 2>/dev/null; then
            echo -e "${GREEN}✅ Found python3 with PyYAML${NC}"
            YAML_PARSER="python3"
        else
            echo -e "${YELLOW}⚠️  Found python3 but PyYAML is not installed${NC}"
            echo -e "${YELLOW}   Install with: pip3 install pyyaml${NC}"
            echo ""
            YAML_PARSER="basic"
        fi
    elif command -v python &> /dev/null; then
        # Check if PyYAML is installed
        if python -c "import yaml" 2>/dev/null; then
            echo -e "${GREEN}✅ Found python with PyYAML${NC}"
            YAML_PARSER="python"
        else
            echo -e "${YELLOW}⚠️  Found python but PyYAML is not installed${NC}"
            echo -e "${YELLOW}   Install with: pip install pyyaml${NC}"
            echo ""
            YAML_PARSER="basic"
        fi
    else
        echo -e "${YELLOW}⚠️  No YAML parser found, using basic validation${NC}"
        YAML_PARSER="basic"
    fi
    echo ""
}

# Basic YAML validation without external dependencies
validate_yaml_basic() {
    local file="$1"
    local basename=$(basename "$file")
    
    # Check for common YAML syntax issues
    local errors=0
    
    # Check for tabs (YAML should use spaces)
    if grep -q $'\t' "$file"; then
        echo -e "${RED}❌ $basename: Contains tabs (YAML must use spaces)${NC}"
        ((errors++))
    fi
    
    # Check for consistent indentation
    local indents=$(grep -E "^[ ]+\S" "$file" | sed -E 's/^([ ]+).*/\1/' | awk '{ print length }' | sort -u)
    local indent_list=$(echo "$indents" | tr '\n' ' ')
    
    # Check if indentation is consistent (usually 2 or 4 spaces)
    local valid_indent=true
    for indent in $indent_list; do
        if [ $((indent % 2)) -ne 0 ] && [ $((indent % 4)) -ne 0 ]; then
            valid_indent=false
        fi
    done
    
    if [ "$valid_indent" = false ]; then
        echo -e "${YELLOW}⚠️  $basename: Unusual indentation detected${NC}"
    fi
    
    # Check for unclosed quotes
    local single_quotes=$(grep -c "'" "$file" 2>/dev/null || echo 0)
    local double_quotes=$(grep -c '"' "$file" 2>/dev/null || echo 0)
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ $basename: Basic YAML validation passed${NC}"
    fi
    
    return $errors
}

# Validate YAML syntax using available parser
validate_yaml_syntax() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -n "Testing $basename... "
    
    if [ "$YAML_PARSER" = "basic" ]; then
        if validate_yaml_basic "$file"; then
            :
        else
            ((ERRORS++))
        fi
    elif [ "$YAML_PARSER" = "yq" ]; then
        if yq eval '.' "$file" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Valid YAML${NC}"
        else
            echo -e "${RED}❌ Invalid YAML${NC}"
            yq eval '.' "$file" 2>&1 | head -5
            ((ERRORS++))
        fi
    else
        # Use Python to validate YAML
        if $YAML_PARSER -c "import yaml; yaml.safe_load(open('$file'))" 2>&1; then
            echo -e "${GREEN}✅ Valid YAML${NC}"
        else
            echo -e "${RED}❌ Invalid YAML${NC}"
            ((ERRORS++))
        fi
    fi
}

# Extract and validate frontmatter only
validate_frontmatter() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -n "Testing frontmatter in $basename... "
    
    # Extract frontmatter (between --- markers)
    local frontmatter=$(sed -n '/^---$/,/^---$/p' "$file" | head -n -1)
    
    if [ -z "$frontmatter" ]; then
        echo -e "${RED}❌ No frontmatter found${NC}"
        ((ERRORS++))
        return
    fi
    
    # Create temporary file with frontmatter
    local temp_file=$(mktemp)
    echo "$frontmatter" > "$temp_file"
    
    if [ "$YAML_PARSER" = "basic" ]; then
        if validate_yaml_basic "$temp_file"; then
            :
        else
            ((ERRORS++))
        fi
    elif [ "$YAML_PARSER" = "yq" ]; then
        if yq eval '.' "$temp_file" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Valid frontmatter${NC}"
        else
            echo -e "${RED}❌ Invalid frontmatter${NC}"
            yq eval '.' "$temp_file" 2>&1 | head -5
            ((ERRORS++))
        fi
    else
        if $YAML_PARSER -c "import yaml; yaml.safe_load(open('$temp_file'))" 2>&1; then
            echo -e "${GREEN}✅ Valid frontmatter${NC}"
        else
            echo -e "${RED}❌ Invalid frontmatter${NC}"
            ((ERRORS++))
        fi
    fi
    
    rm -f "$temp_file"
}

# Main test function
run_tests() {
    local dir="$1"
    local type="$2"
    
    echo -e "${BLUE}📂 Testing $type files...${NC}"
    echo "-------------------------"
    
    if [ ! -d "$dir" ]; then
        echo -e "${YELLOW}⚠️  Directory not found: $dir${NC}"
        return
    fi
    
    for file in "$dir"/*.md; do
        if [ -f "$file" ]; then
            validate_frontmatter "$file"
        fi
    done
    echo ""
}

# Check for YAML parser
check_yaml_parser

# Run tests for all directories
run_tests "$OPENCODE_DIR/agents" "agents"
run_tests "$OPENCODE_DIR/subagents" "subagents"
run_tests "$OPENCODE_DIR/workflows" "workflows"

# Also test opencode.yaml if it exists
if [ -f "$OPENCODE_DIR/opencode.yaml" ]; then
    echo -e "${BLUE}📂 Testing opencode.yaml...${NC}"
    echo "-------------------------"
    validate_yaml_syntax "$OPENCODE_DIR/opencode.yaml"
    echo ""
fi

# Summary
echo "====================="
echo -e "${BLUE}📊 Summary${NC}"
echo "====================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All YAML syntax tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ YAML syntax tests failed with $ERRORS error(s)${NC}"
    exit 1
fi
