#!/bin/bash
#
# OpenCode Agents Installer Script
# Installs Code Repository Reader agents to your project's .opencode directory
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/beginner1729/repo-reader/main/install.sh | bash
#   or
#   ./install.sh [target_directory]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository URL
REPO_URL="https://github.com/beginner1729/repo-reader"
RAW_URL="https://raw.githubusercontent.com/beginner1729/repo-reader/main"

# Default target directory
TARGET_DIR="${1:-.}"
OPENCODE_DIR="$TARGET_DIR/.opencode"

echo -e "${BLUE}🔧 OpenCode Agents Installer${NC}"
echo "================================"
echo ""

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}❌ Error: Target directory '$TARGET_DIR' does not exist${NC}"
    exit 1
fi

# Check if target is a git repository
if [ ! -d "$TARGET_DIR/.git" ]; then
    echo -e "${YELLOW}⚠️  Warning: Target directory is not a git repository${NC}"
fi

echo -e "${BLUE}📁 Target directory:${NC} $TARGET_DIR"
echo -e "${BLUE}📂 Installing to:${NC} $OPENCODE_DIR"
echo ""

# Create .opencode directory structure
echo -e "${BLUE}📂 Creating directory structure...${NC}"
mkdir -p "$OPENCODE_DIR"/{agents,subagents,workflows}

# Download configuration files
echo -e "${BLUE}📥 Downloading agent configurations...${NC}"

# Function to download file with error handling
download_file() {
    local url="$1"
    local dest="$2"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest" 2>/dev/null || {
            echo -e "${RED}❌ Failed to download: $url${NC}"
            return 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$dest" 2>/dev/null || {
            echo -e "${RED}❌ Failed to download: $url${NC}"
            return 1
        }
    else
        echo -e "${RED}❌ Error: curl or wget is required${NC}"
        exit 1
    fi
    return 0
}

# Download agents
echo -n "  • broad_summary_agent... "
if download_file "$RAW_URL/agents/broad_summary_agent.md" "$OPENCODE_DIR/agents/broad_summary_agent.md"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
fi

echo -n "  • connection_builder_agent... "
if download_file "$RAW_URL/agents/connection_builder_agent.md" "$OPENCODE_DIR/agents/connection_builder_agent.md"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
fi

echo -n "  • snippet_builder_agent... "
if download_file "$RAW_URL/agents/snippet_builder_agent.md" "$OPENCODE_DIR/agents/snippet_builder_agent.md"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
fi

echo -n "  • documentation_website_agent... "
if download_file "$RAW_URL/agents/documentation_website_agent.md" "$OPENCODE_DIR/agents/documentation_website_agent.md"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
fi

# Download subagents
echo -n "  • file_scanner (subagent)... "
if download_file "$RAW_URL/subagents/file_scanner.md" "$OPENCODE_DIR/subagents/file_scanner.md"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
fi

echo -n "  • concept_splitter (subagent)... "
if download_file "$RAW_URL/subagents/concept_splitter.md" "$OPENCODE_DIR/subagents/concept_splitter.md"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
fi

echo -n "  • website_creator (subagent)... "
if download_file "$RAW_URL/subagents/website_creator.md" "$OPENCODE_DIR/subagents/website_creator.md"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
fi

echo -n "  • feedback_provider (subagent)... "
if download_file "$RAW_URL/subagents/feedback_provider.md" "$OPENCODE_DIR/subagents/feedback_provider.md"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
fi

# Download workflow
echo -n "  • repo_reader_workflow... "
if download_file "$RAW_URL/workflows/repo_reader_workflow.md" "$OPENCODE_DIR/workflows/repo_reader_workflow.md"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
fi

echo ""

# Create output directory
echo -e "${BLUE}📂 Creating output directory...${NC}"
mkdir -p "$TARGET_DIR/opencode-output"

# Create a sample execution script
echo -e "${BLUE}📝 Creating helper script...${NC}"
cat > "$OPENCODE_DIR/run.sh" << 'EOF'
#!/bin/bash
# Helper script to run the repo reader workflow

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Running Code Repository Reader Workflow"
echo "==========================================="
echo ""
echo "Repository: $TARGET_DIR"
echo "Output: $TARGET_DIR/opencode-output"
echo "Website: $TARGET_DIR/website"
echo ""

OUTPUT_BASE_DIR="$TARGET_DIR/opencode-output"
WEBSITE_OUTPUT_DIR="$TARGET_DIR/website"

# Check if opencode CLI is available
if ! command -v opencode &> /dev/null; then
    echo "❌ Error: opencode CLI not found"
    echo "Please install opencode first: https://opencode.ai"
    exit 1
fi

# Run the agents from repository root so opencode resolves repo-reader.json
cd "$TARGET_DIR"
echo "Running agents individually (workflows not supported in current opencode CLI):"
opencode agent run broad_summary_agent --input repository_path="$TARGET_DIR" --input output_directory="$OUTPUT_BASE_DIR/summaries" || echo "⚠️  broad_summary_agent failed"
opencode agent run connection_builder_agent --input repository_path="$TARGET_DIR" --input output_directory="$OUTPUT_BASE_DIR/mermaid_graphs" || echo "⚠️  connection_builder_agent failed"
opencode agent run snippet_builder_agent --input repository_path="$TARGET_DIR" --input summary_files_directory="$OUTPUT_BASE_DIR/summaries" --input mermaid_files_directory="$OUTPUT_BASE_DIR/mermaid_graphs" --input output_directory="$OUTPUT_BASE_DIR/deep_dives" || echo "⚠️  snippet_builder_agent failed"
opencode agent run documentation_website_agent --input output_base_directory="$OUTPUT_BASE_DIR" --input website_output_directory="$WEBSITE_OUTPUT_DIR" || echo "⚠️  documentation_website_agent failed"

echo ""
echo "✅ Agents completed!"
echo "Check analysis output in: $OUTPUT_BASE_DIR"
echo "Check website output in: $WEBSITE_OUTPUT_DIR"
EOF

chmod +x "$OPENCODE_DIR/run.sh"

# Create a gitignore entry if not exists
if [ -f "$TARGET_DIR/.gitignore" ]; then
    if ! grep -q "^opencode-output/$" "$TARGET_DIR/.gitignore"; then
        echo -e "${BLUE}📝 Updating .gitignore...${NC}"
        echo "" >> "$TARGET_DIR/.gitignore"
        echo "# OpenCode output" >> "$TARGET_DIR/.gitignore"
        echo "opencode-output/" >> "$TARGET_DIR/.gitignore"
    fi
else
    echo -e "${BLUE}📝 Creating .gitignore...${NC}"
    echo "# OpenCode output" > "$TARGET_DIR/.gitignore"
    echo "opencode-output/" >> "$TARGET_DIR/.gitignore"
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "${BLUE}📋 What's installed:${NC}"
echo "  • 4 Main Agents (Broad Summary, Connection Builder, Snippet Builder, Documentation Website)"
echo "  • 4 Subagents (File Scanner, Concept Splitter, Website Creator, Feedback Provider)"
echo "  • 1 Workflow (Repository Reader)"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo "  1. Ensure you have the opencode CLI installed"
echo "  2. Navigate to your repository: cd $TARGET_DIR"
echo "  3. Run the agents: $OPENCODE_DIR/run.sh"
echo "     (Note: workflows are not supported in current opencode CLI)"
echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "  • See .opencode/AGENTS.md for detailed agent documentation"
echo "  • Output will be saved to: $TARGET_DIR/opencode-output/"
echo ""
echo -e "${YELLOW}💡 Tip:${NC} Agents are auto-discovered from .opencode/agents/ and .opencode/subagents/"
echo ""
