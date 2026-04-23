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
