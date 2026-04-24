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

# Run from .opencode so opencode resolves .opencode/repo-reader.json
cd "$SCRIPT_DIR"
echo "Running pipeline using opencode run + subagent task invocations:"
opencode run "Use the task tool to invoke subagent broad_summary_agent with repository_path='$TARGET_DIR' and output_directory='$OUTPUT_BASE_DIR/summaries'. Execute now and return a short status with generated file count only." || echo "⚠️  broad_summary_agent failed"
opencode run "Use the task tool to invoke subagent connection_builder_agent with repository_path='$TARGET_DIR' and output_directory='$OUTPUT_BASE_DIR/mermaid_graphs'. Execute now and return a short status with generated file count only." || echo "⚠️  connection_builder_agent failed"
opencode run "Use the task tool to invoke subagent snippet_builder_agent with repository_path='$TARGET_DIR', summary_files_directory='$OUTPUT_BASE_DIR/summaries', mermaid_files_directory='$OUTPUT_BASE_DIR/mermaid_graphs', and output_directory='$OUTPUT_BASE_DIR/deep_dives'. Execute now and return a short status with generated file count only." || echo "⚠️  snippet_builder_agent failed"
opencode run --agent documentation_website_agent "Create the documentation website using output_base_directory='$OUTPUT_BASE_DIR' and website_output_directory='$WEBSITE_OUTPUT_DIR'. Return final_score and website_directory." || echo "⚠️  documentation_website_agent failed"

echo ""
echo "✅ Agents completed!"
echo "Check analysis output in: $OUTPUT_BASE_DIR"
echo "Check website output in: $WEBSITE_OUTPUT_DIR"
