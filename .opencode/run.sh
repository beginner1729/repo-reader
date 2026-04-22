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
echo ""

# Check if opencode CLI is available
if ! command -v opencode &> /dev/null; then
    echo "❌ Error: opencode CLI not found"
    echo "Please install opencode first: https://opencode.ai"
    exit 1
fi

# Run the workflow
cd "$SCRIPT_DIR"
opencode workflow run repo_reader_workflow \
    --input repository_path="$TARGET_DIR" \
    --input output_base_directory="$TARGET_DIR/opencode-output"

echo ""
echo "✅ Workflow completed!"
echo "Check the output in: $TARGET_DIR/opencode-output"
