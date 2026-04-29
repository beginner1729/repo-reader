#!/bin/bash
# Helper script to run the repo reader workflow
# Run via opencode: .opencode/run.sh
# All four agents run SEQUENTIALLY: graphify -> broad_summary -> snippet_builder -> documentation_website

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_BASE_DIR="$TARGET_DIR/opencode-output"
WEBSITE_OUTPUT_DIR="$TARGET_DIR/website"
GRAPHIFY_OUT_DIR="$TARGET_DIR/graphify-out"
# Available model variants
MODEL="${OPENCODE_MODEL:-}"

while getopts "m:lh" opt; do
    case "$opt" in
        m)
            MODEL="$OPTARG"
            ;;
        l)
            echo "Available model variants:"
            echo "  openai/gpt-5.3-codex   (default - OpenAI GPT-5.3 Codex)"
            echo "  anthropic/claude-sonnet-4  (Anthropic Claude Sonnet 4)"
            echo "  anthropic/claude-opus-4    (Anthropic Claude Opus 4)"
            echo "  google/gemini-2.5-pro      (Google Gemini 2.5 Pro)"
            echo "  openai/gpt-5.1-codex       (OpenAI GPT-5.1 Codex - faster)"
            echo "  deepseek/deepseek-chat     (DeepSeek Chat)"
            echo ""
            echo "Usage: $0 [-m model]"
            echo "Environment variable: export OPENCODE_MODEL=anthropic/claude-sonnet-4"
            exit 0
            ;;
        h)
            echo "Usage: $0 [-m model] [-l]"
            echo "  -m model   OpenCode model id"
            echo "  -l         List available model variants"
            echo "  -h         Show this help"
            echo ""
            echo "Environment: OPENCODE_MODEL overrides default"
            echo "Examples:"
            echo "  $0 -m anthropic/claude-sonnet-4"
            echo "  OPENCODE_MODEL=google/gemini-2.5-pro $0"
            exit 0
            ;;
        *)
            echo "Usage: $0 [-m model] [-l] [-h]"
            exit 1
            ;;
    esac
done

# If no model specified via flag or env, show interactive prompt (only in TTY)
if [ -z "$MODEL" ]; then
    if [ -t 0 ] && [ -t 1 ]; then
        echo "Select model variant:"
        echo "  [1] openai/gpt-5.3-codex (default - balanced)"
        echo "  [2] anthropic/claude-sonnet-4 (reasoning)"
        echo "  [3] anthropic/claude-opus-4 (most capable)"
        echo "  [4] google/gemini-2.5-pro (long context)"
        echo "  [5] openai/gpt-5.1-codex (faster)"
        echo "  [6] deepseek/deepseek-chat (cost-effective)"
        read -p "Enter choice [1-6] or press Enter for default: " CHOICE
        case "$CHOICE" in
            2) MODEL="anthropic/claude-sonnet-4" ;;
            3) MODEL="anthropic/claude-opus-4" ;;
            4) MODEL="google/gemini-2.5-pro" ;;
            5) MODEL="openai/gpt-5.1-codex" ;;
            6) MODEL="deepseek/deepseek-chat" ;;
            *) MODEL="openai/gpt-5.3-codex" ;;
        esac
    else
        MODEL="openai/gpt-5.3-codex"
    fi
fi

echo "Code Repository Reader Workflow"
echo "=========================================="
echo ""
echo "Repository: $TARGET_DIR"
echo "Output: $OUTPUT_BASE_DIR"
echo "Graphify: $GRAPHIFY_OUT_DIR"
echo "Website: $WEBSITE_OUTPUT_DIR"
echo "Model: $MODEL"
echo ""

# Check if opencode CLI is available
if ! command -v opencode &> /dev/null; then
    echo "Error: opencode CLI not found"
    echo "Please install opencode first: https://opencode.ai"
    exit 1
fi

# Check if graphify is available (prefer venv path)
GRAPHIFY_CMD="$TARGET_DIR/.graphify-venv/bin/graphify"
if [ ! -x "$GRAPHIFY_CMD" ]; then
    if command -v graphify &> /dev/null; then
        GRAPHIFY_CMD="graphify"
    else
        echo "Error: graphify CLI not found"
        echo "Run install.sh first to set up graphify and dependencies"
        exit 1
    fi
fi

# Run from .opencode so opencode resolves .opencode/repo-reader.json
cd "$SCRIPT_DIR"

echo "[1/4] graphify - building knowledge graph (via opencode skill)"
# Ensure graphify skill is installed for opencode
if command -v graphify &> /dev/null; then
    graphify install --platform opencode 2>/dev/null || true
fi
# Run graphify via opencode using the /graphify skill
opencode run -m "$MODEL" "/graphify $TARGET_DIR --directed" 2>&1 || echo "Warning: graphify failed or partially completed"
echo ""

echo "[2/4] broad_summary_agent"
opencode run -m "$MODEL" "Use the task tool to invoke subagent broad_summary_agent with repository_path='$TARGET_DIR', output_directory='$OUTPUT_BASE_DIR/summaries', and graphify_files_directory='$GRAPHIFY_OUT_DIR'. Execute now and return a short status with generated file count only." || echo "Warning: broad_summary_agent failed"
echo ""

echo "[3/4] snippet_builder_agent"
opencode run -m "$MODEL" "Use the task tool to invoke subagent snippet_builder_agent with repository_path='$TARGET_DIR', summary_files_directory='$OUTPUT_BASE_DIR/summaries', graphify_files_directory='$GRAPHIFY_OUT_DIR', and output_directory='$OUTPUT_BASE_DIR/deep_dives'. Execute now and return a short status with generated file count only." || echo "Warning: snippet_builder_agent failed"
echo ""

echo "[4/4] documentation_website_agent"
opencode run -m "$MODEL" --agent documentation_website_agent "Create the documentation website using output_base_directory='$OUTPUT_BASE_DIR' and website_output_directory='$WEBSITE_OUTPUT_DIR'. Return final_score and website_directory." || echo "Warning: documentation_website_agent failed"

echo ""
echo "Agents completed!"
echo "Check graphify output in: $GRAPHIFY_OUT_DIR"
echo "Check analysis output in: $OUTPUT_BASE_DIR"
echo "Check website output in: $WEBSITE_OUTPUT_DIR"
