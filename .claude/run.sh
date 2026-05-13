#!/bin/bash
# Helper script to run the repo reader workflow via the Claude Code CLI.
# Run via: .claude/run.sh
# All four steps run SEQUENTIALLY: graphify -> broad_summary -> snippet_builder -> documentation_website

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_BASE_DIR="$TARGET_DIR/opencode-output"
WEBSITE_OUTPUT_DIR="$TARGET_DIR/website"
GRAPHIFY_OUT_DIR="$TARGET_DIR/graphify-out"

# Available model variants for Claude Code (aliases or full IDs)
MODEL="${CLAUDE_MODEL:-}"

while getopts "m:lh" opt; do
    case "$opt" in
        m)
            MODEL="$OPTARG"
            ;;
        l)
            echo "Available Claude Code model variants:"
            echo "  claude-opus-4-7      (Opus 4.7 - most capable, default)"
            echo "  claude-sonnet-4-6    (Sonnet 4.6 - balanced)"
            echo "  claude-haiku-4-5     (Haiku 4.5 - fastest)"
            echo "  opus                 (alias for latest opus)"
            echo "  sonnet               (alias for latest sonnet)"
            echo "  haiku                (alias for latest haiku)"
            echo ""
            echo "Usage: $0 [-m model]"
            echo "Environment variable: export CLAUDE_MODEL=claude-sonnet-4-6"
            exit 0
            ;;
        h)
            echo "Usage: $0 [-m model] [-l]"
            echo "  -m model   Claude Code model id or alias"
            echo "  -l         List available model variants"
            echo "  -h         Show this help"
            echo ""
            echo "Environment: CLAUDE_MODEL overrides default"
            echo "Examples:"
            echo "  $0 -m claude-sonnet-4-6"
            echo "  CLAUDE_MODEL=opus $0"
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
        echo "Select Claude Code model variant:"
        echo "  [1] claude-opus-4-7   (default - most capable)"
        echo "  [2] claude-sonnet-4-6 (balanced)"
        echo "  [3] claude-haiku-4-5  (fastest)"
        echo "  [4] opus              (latest opus alias)"
        echo "  [5] sonnet            (latest sonnet alias)"
        echo "  [6] haiku             (latest haiku alias)"
        read -p "Enter choice [1-6] or press Enter for default: " CHOICE
        case "$CHOICE" in
            2) MODEL="claude-sonnet-4-6" ;;
            3) MODEL="claude-haiku-4-5" ;;
            4) MODEL="opus" ;;
            5) MODEL="sonnet" ;;
            6) MODEL="haiku" ;;
            *) MODEL="claude-opus-4-7" ;;
        esac
    else
        MODEL="claude-opus-4-7"
    fi
fi

echo "Code Repository Reader Workflow (Claude Code)"
echo "=========================================="
echo ""
echo "Repository: $TARGET_DIR"
echo "Output: $OUTPUT_BASE_DIR"
echo "Graphify: $GRAPHIFY_OUT_DIR"
echo "Website: $WEBSITE_OUTPUT_DIR"
echo "Model: $MODEL"
echo ""

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "Error: claude CLI not found"
    echo "Please install Claude Code: https://docs.claude.com/claude-code"
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

# Ensure the graphify skill is installed for Claude Code
"$GRAPHIFY_CMD" install --platform claude 2>/dev/null || true

# Run from project root so claude resolves the project-local .claude/ directory
cd "$TARGET_DIR"

# Common claude flags: non-interactive print mode, allow project-local subagents.
CLAUDE_FLAGS=(-p --model "$MODEL" --permission-mode acceptEdits)

echo "[1/4] graphify - building knowledge graph (via Claude Code skill)"
claude "${CLAUDE_FLAGS[@]}" "/graphify $TARGET_DIR --directed" 2>&1 || echo "Warning: graphify failed or partially completed"
echo ""

echo "[2/4] broad_summary_agent"
claude "${CLAUDE_FLAGS[@]}" "Use the Task tool to invoke subagent broad_summary_agent with repository_path='$TARGET_DIR', output_directory='$OUTPUT_BASE_DIR/summaries', and graphify_files_directory='$GRAPHIFY_OUT_DIR'. Execute now and return a short status with generated file count only." || echo "Warning: broad_summary_agent failed"
echo ""

echo "[3/4] snippet_builder_agent"
claude "${CLAUDE_FLAGS[@]}" "Use the Task tool to invoke subagent snippet_builder_agent with repository_path='$TARGET_DIR', summary_files_directory='$OUTPUT_BASE_DIR/summaries', graphify_files_directory='$GRAPHIFY_OUT_DIR', and output_directory='$OUTPUT_BASE_DIR/deep_dives'. Execute now and return a short status with generated file count only." || echo "Warning: snippet_builder_agent failed"
echo ""

echo "[4/4] documentation_website_agent"
claude "${CLAUDE_FLAGS[@]}" "Use the Task tool to invoke subagent documentation_website_agent with output_base_directory='$OUTPUT_BASE_DIR' and website_output_directory='$WEBSITE_OUTPUT_DIR'. Return final_score and website_directory." || echo "Warning: documentation_website_agent failed"

echo ""
echo "Agents completed!"
echo "Check graphify output in: $GRAPHIFY_OUT_DIR"
echo "Check analysis output in: $OUTPUT_BASE_DIR"
echo "Check website output in: $WEBSITE_OUTPUT_DIR"
