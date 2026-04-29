#!/bin/bash
#
# OpenCode Agents Installer Script
# Installs Code Repository Reader agents to your project's .opencode directory
# Also sets up graphify with a Python virtual environment
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

echo -e "${BLUE}OpenCode Agents Installer${NC}"
echo "================================"
echo ""

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Target directory '$TARGET_DIR' does not exist${NC}"
    exit 1
fi

# Check if target is a git repository
if [ ! -d "$TARGET_DIR/.git" ]; then
    echo -e "${YELLOW}Warning: Target directory is not a git repository${NC}"
fi

echo -e "${BLUE}Target directory:${NC} $TARGET_DIR"
echo -e "${BLUE}Installing to:${NC} $OPENCODE_DIR"
echo ""

###############################################################################
# Step 1: Python Virtual Environment Setup for graphify
###############################################################################
echo -e "${BLUE}--- Python Virtual Environment Setup ---${NC}"

GRAPHIFY_VENV_DIR="$TARGET_DIR/.graphify-venv"

# Detect Python installation using command -v (portable which/where)
PYTHON_BIN=""
for py_cmd in python3 python; do
    PYTHON_PATH=$(command -v "$py_cmd" 2>/dev/null || true)
    if [ -n "$PYTHON_PATH" ]; then
        PY_VER=$("$py_cmd" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null)
        PY_MAJOR=$("$py_cmd" -c "import sys; print(sys.version_info.major)" 2>/dev/null)
        PY_MINOR=$("$py_cmd" -c "import sys; print(sys.version_info.minor)" 2>/dev/null)
        if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 10 ]; then
            PYTHON_BIN="$py_cmd"
            echo -e "${GREEN}Found Python $PY_VER at $PYTHON_PATH${NC}"
            break
        fi
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo -e "${RED}Error: Python 3.10+ is required but not found${NC}"
    echo "Please install Python 3.10 or later: https://www.python.org/downloads/"
    exit 1
fi

# Detect package installer: prefer uv, then pip
USE_UV=false
UV_PATH=$(command -v uv 2>/dev/null || true)
if [ -n "$UV_PATH" ]; then
    echo -e "${GREEN}Found uv at $UV_PATH${NC}"
    USE_UV=true
else
    PIP_CMD=""
    for pip_cmd in pip3 pip; do
        PIP_PATH=$(command -v "$pip_cmd" 2>/dev/null || true)
        if [ -n "$PIP_PATH" ]; then
            PIP_CMD="$pip_cmd"
            echo -e "${GREEN}Found pip at $PIP_PATH${NC}"
            break
        fi
    done
    
    if [ -z "$PIP_CMD" ]; then
        echo -e "${RED}Error: Neither uv nor pip found. Please install uv (https://docs.astral.sh/uv/) or pip.${NC}"
        exit 1
    fi
fi

# Ask user about virtual env preference (non-interactive skip if piped)
if [ -t 0 ] && [ -t 1 ]; then
    echo ""
    echo -e "${YELLOW}A Python virtual environment is recommended for graphify.${NC}"
    read -p "Create virtual environment at $GRAPHIFY_VENV_DIR? [Y/n] " VENV_CHOICE
    VENV_CHOICE="${VENV_CHOICE:-Y}"
else
    VENV_CHOICE="Y"
fi

if [[ "$VENV_CHOICE" =~ ^[Yy]$ ]]; then
    if [ ! -d "$GRAPHIFY_VENV_DIR" ]; then
        echo -e "${BLUE}Creating Python virtual environment...${NC}"
        if [ "$USE_UV" = true ]; then
            uv venv "$GRAPHIFY_VENV_DIR" --python "$PYTHON_BIN"
        else
            "$PYTHON_BIN" -m venv "$GRAPHIFY_VENV_DIR"
        fi
        echo -e "${GREEN}Virtual environment created at $GRAPHIFY_VENV_DIR${NC}"
    else
        echo -e "${GREEN}Virtual environment already exists at $GRAPHIFY_VENV_DIR${NC}"
    fi
    GRAPHIFY_BIN="$GRAPHIFY_VENV_DIR/bin/graphify"
    echo ""
    echo -e "${BLUE}Installing graphify in virtual environment...${NC}"
    if [ "$USE_UV" = true ]; then
        uv pip install --python "$GRAPHIFY_VENV_DIR/bin/python" graphifyy
    else
        "$GRAPHIFY_VENV_DIR/bin/pip" install --upgrade pip -q
        "$GRAPHIFY_VENV_DIR/bin/pip" install graphifyy
    fi
    echo -e "${GREEN}graphify installed in virtual environment${NC}"

    # Install graphify skill for opencode
    echo -e "${BLUE}Installing graphify skill for opencode...${NC}"
    "$GRAPHIFY_VENV_DIR/bin/graphify" install --platform opencode 2>&1 || echo -e "${YELLOW}Warning: graphify opencode skill install may have failed${NC}"

    # Add source helper script
    cat > "$GRAPHIFY_VENV_DIR/activate-graphify.sh" << 'ACTIVATE_EOF'
#!/bin/bash
# Source this file to activate the graphify virtual environment:
#   source .graphify-venv/activate-graphify.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/bin/activate"
ACTIVATE_EOF
    chmod +x "$GRAPHIFY_VENV_DIR/activate-graphify.sh"
else
    # Install graphify globally using detected installer
    echo -e "${BLUE}Installing graphify using $PYTHON_BIN...${NC}"
    if [ "$USE_UV" = true ]; then
        uv pip install --system graphifyy 2>/dev/null || {
            echo -e "${RED}Error: Failed to install graphify with uv${NC}"
            exit 1
        }
    else
        "$PYTHON_BIN" -m pip install graphifyy 2>/dev/null || \
        "$PYTHON_BIN" -m pip install graphifyy --break-system-packages 2>/dev/null || {
            echo -e "${RED}Error: Failed to install graphify${NC}"
            exit 1
        }
    fi
    GRAPHIFY_BIN="graphify"
fi

echo ""

###############################################################################
# Step 2: Download agent configuration files
###############################################################################
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p "$OPENCODE_DIR"/{agents,subagents,workflows}

echo -e "${BLUE}Downloading agent configurations...${NC}"

# Function to download file with error handling
download_file() {
    local url="$1"
    local dest="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest" 2>/dev/null || {
            echo -e "${RED}Failed to download: $url${NC}"
            return 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$dest" 2>/dev/null || {
            echo -e "${RED}Failed to download: $url${NC}"
            return 1
        }
    else
        echo -e "${RED}Error: curl or wget is required${NC}"
        exit 1
    fi
    return 0
}

# Download project config for local agent discovery in .opencode
echo -n "  . repo-reader.json (config)... "
if download_file "$RAW_URL/repo-reader.json" "$OPENCODE_DIR/repo-reader.json"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

# Remove stale .opencode/opencode.json if present (unsupported schema in this project)
rm -f "$OPENCODE_DIR/opencode.json"

# Download agents
echo -n "  . broad_summary_agent... "
if download_file "$RAW_URL/agents/broad_summary_agent.md" "$OPENCODE_DIR/agents/broad_summary_agent.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

echo -n "  . snippet_builder_agent... "
if download_file "$RAW_URL/agents/snippet_builder_agent.md" "$OPENCODE_DIR/agents/snippet_builder_agent.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

echo -n "  . documentation_website_agent... "
if download_file "$RAW_URL/agents/documentation_website_agent.md" "$OPENCODE_DIR/agents/documentation_website_agent.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

echo -n "  . website_creator (task subagent)... "
if download_file "$RAW_URL/agents/website_creator.md" "$OPENCODE_DIR/agents/website_creator.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

echo -n "  . feedback_provider (task subagent)... "
if download_file "$RAW_URL/agents/feedback_provider.md" "$OPENCODE_DIR/agents/feedback_provider.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

# Download subagents
echo -n "  . file_scanner (subagent)... "
if download_file "$RAW_URL/subagents/file_scanner.md" "$OPENCODE_DIR/subagents/file_scanner.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

echo -n "  . concept_splitter (subagent)... "
if download_file "$RAW_URL/subagents/concept_splitter.md" "$OPENCODE_DIR/subagents/concept_splitter.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

echo -n "  . website_creator (subagent)... "
if download_file "$RAW_URL/subagents/website_creator.md" "$OPENCODE_DIR/subagents/website_creator.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

echo -n "  . feedback_provider (subagent)... "
if download_file "$RAW_URL/subagents/feedback_provider.md" "$OPENCODE_DIR/subagents/feedback_provider.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

# Download workflow
echo -n "  . repo_reader_workflow... "
if download_file "$RAW_URL/workflows/repo_reader_workflow.md" "$OPENCODE_DIR/workflows/repo_reader_workflow.md"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}SKIPPED${NC}"
fi

echo ""

###############################################################################
# Step 3: Create output directory structure
###############################################################################
echo -e "${BLUE}Creating output directory...${NC}"
mkdir -p "$TARGET_DIR/opencode-output"

###############################################################################
# Step 4: Create helper run script
###############################################################################
echo -e "${BLUE}Creating helper script...${NC}"

# Determine the graphify bin path for the run.sh
if [ -d "$GRAPHIFY_VENV_DIR" ]; then
    GRAPHIFY_BIN_PATH="$GRAPHIFY_VENV_DIR/bin/graphify"
else
    GRAPHIFY_BIN_PATH="graphify"
fi

cat > "$OPENCODE_DIR/run.sh" << RUNEOF
#!/bin/bash
# Helper script to run the repo reader workflow
# Run via opencode: .opencode/run.sh
# All four agents run SEQUENTIALLY: graphify -> broad_summary -> snippet_builder -> documentation_website

set -e

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="\$(dirname "\$SCRIPT_DIR")"
OUTPUT_BASE_DIR="\$TARGET_DIR/opencode-output"
WEBSITE_OUTPUT_DIR="\$TARGET_DIR/website"
GRAPHIFY_OUT_DIR="\$TARGET_DIR/graphify-out"
MODEL="\${OPENCODE_MODEL:-openai/gpt-5.3-codex}"

while getopts "m:h" opt; do
    case "\$opt" in
        m)
            MODEL="\$OPTARG"
            ;;
        h)
            echo "Usage: \$0 [-m model]"
            echo "  -m model   OpenCode model id (default: \$MODEL)"
            exit 0
            ;;
        *)
            echo "Usage: \$0 [-m model]"
            exit 1
            ;;
    esac
done

echo "Code Repository Reader Workflow"
echo "=========================================="
echo ""
echo "Repository: \$TARGET_DIR"
echo "Output: \$OUTPUT_BASE_DIR"
echo "Graphify: \$GRAPHIFY_OUT_DIR"
echo "Website: \$WEBSITE_OUTPUT_DIR"
echo "Model: \$MODEL"
echo ""

# Check if opencode CLI is available
if ! command -v opencode &> /dev/null; then
    echo "Error: opencode CLI not found"
    echo "Please install opencode first: https://opencode.ai"
    exit 1
fi

# Check if graphify is available (prefer venv path)
GRAPHIFY_CMD="$GRAPHIFY_BIN_PATH"
if [ ! -x "\$GRAPHIFY_CMD" ]; then
    if command -v graphify &> /dev/null; then
        GRAPHIFY_CMD="graphify"
    else
        echo "Error: graphify CLI not found"
        echo "Run install.sh first to set up graphify and dependencies"
        exit 1
    fi
fi

# Run from .opencode so opencode resolves .opencode/repo-reader.json
cd "\$SCRIPT_DIR"

echo "[1/4] graphify - building knowledge graph (via opencode skill)"
# Ensure graphify skill is installed for opencode
if command -v graphify &> /dev/null; then
    graphify install --platform opencode 2>/dev/null || true
fi
# Run graphify via opencode using the /graphify skill
opencode run -m "\$MODEL" "/graphify \$TARGET_DIR --directed" 2>&1 || echo "Warning: graphify failed or partially completed"
echo ""

echo "[2/4] broad_summary_agent"
opencode run -m "\$MODEL" "Use the task tool to invoke subagent broad_summary_agent with repository_path='\$TARGET_DIR', output_directory='\$OUTPUT_BASE_DIR/summaries', and graphify_files_directory='\$GRAPHIFY_OUT_DIR'. Execute now and return a short status with generated file count only." || echo "Warning: broad_summary_agent failed"
echo ""

echo "[3/4] snippet_builder_agent"
opencode run -m "\$MODEL" "Use the task tool to invoke subagent snippet_builder_agent with repository_path='\$TARGET_DIR', summary_files_directory='\$OUTPUT_BASE_DIR/summaries', graphify_files_directory='\$GRAPHIFY_OUT_DIR', and output_directory='\$OUTPUT_BASE_DIR/deep_dives'. Execute now and return a short status with generated file count only." || echo "Warning: snippet_builder_agent failed"
echo ""

echo "[4/4] documentation_website_agent"
opencode run -m "\$MODEL" --agent documentation_website_agent "Create the documentation website using output_base_directory='\$OUTPUT_BASE_DIR' and website_output_directory='\$WEBSITE_OUTPUT_DIR'. Return final_score and website_directory." || echo "Warning: documentation_website_agent failed"
echo ""

echo ""
echo "Agents completed!"
echo "Check graphify output in: \$GRAPHIFY_OUT_DIR"
echo "Check analysis output in: \$OUTPUT_BASE_DIR"
echo "Check website output in: \$WEBSITE_OUTPUT_DIR"
RUNEOF

chmod +x "$OPENCODE_DIR/run.sh"

###############################################################################
# Step 5: Update .gitignore
###############################################################################
if [ -f "$TARGET_DIR/.gitignore" ]; then
    if ! grep -q "^opencode-output/$" "$TARGET_DIR/.gitignore" 2>/dev/null; then
        echo -e "${BLUE}Updating .gitignore...${NC}"
        echo "" >> "$TARGET_DIR/.gitignore"
        echo "# OpenCode output" >> "$TARGET_DIR/.gitignore"
        echo "opencode-output/" >> "$TARGET_DIR/.gitignore"
    fi
    if ! grep -q "^graphify-out/$" "$TARGET_DIR/.gitignore" 2>/dev/null; then
        echo "graphify-out/cache/" >> "$TARGET_DIR/.gitignore"
        echo "graphify-out/manifest.json" >> "$TARGET_DIR/.gitignore"
        echo "graphify-out/cost.json" >> "$TARGET_DIR/.gitignore"
    fi
    if ! grep -q "^.graphify-venv/$" "$TARGET_DIR/.gitignore" 2>/dev/null; then
        echo ".graphify-venv/" >> "$TARGET_DIR/.gitignore"
    fi
else
    echo -e "${BLUE}Creating .gitignore...${NC}"
    cat > "$TARGET_DIR/.gitignore" << 'GITIGNORE_EOF'
# OpenCode output
opencode-output/

# graphify
graphify-out/cache/
graphify-out/manifest.json
graphify-out/cost.json

# Python virtual environment for graphify
.graphify-venv/
GITIGNORE_EOF
fi

###############################################################################
# Step 6: Summary
###############################################################################
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "${BLUE}What's installed:${NC}"
echo "  . 1 Project config (.opencode/repo-reader.json)"
echo "  . 4 Main Agents (graphify, Broad Summary, Snippet Builder, Documentation Website)"
echo "  . 4 Subagents (File Scanner, Concept Splitter, Website Creator, Feedback Provider)"
echo "  . 1 Workflow (Repository Reader)"
echo "  . graphify (knowledge graph builder)"
if [ -d "$GRAPHIFY_VENV_DIR" ]; then
    echo "  . Python virtual env: $GRAPHIFY_VENV_DIR"
fi
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Ensure you have the opencode CLI installed"
echo "  2. Navigate to your repository: cd $TARGET_DIR"
echo "  3. Run the agents: $OPENCODE_DIR/run.sh"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  . See .opencode/AGENTS.md for detailed agent documentation"
echo "  . graphify output: $TARGET_DIR/graphify-out/"
echo "  . Agent output: $TARGET_DIR/opencode-output/"
echo ""
echo -e "${YELLOW}Tip:${NC} Agents are auto-discovered from .opencode/agents/ and .opencode/subagents/"
