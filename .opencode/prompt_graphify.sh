#!/bin/bash
#
# Copy-paste prompt for Step 1: graphify
# Prints a prompt you can paste into the opencode TUI.
#
# Usage: .opencode/prompt_graphify.sh | pbcopy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
GRAPHIFY_OUT_DIR="$TARGET_DIR/graphify-out"

cat << PEOF
Run the graphify knowledge-graph builder on this repository.

Repository path: ${TARGET_DIR}
Output directory: ${GRAPHIFY_OUT_DIR}

Instructions:
1. Execute the /graphify skill with the --directed flag on ${TARGET_DIR}.
2. Ensure outputs are written to ${GRAPHIFY_OUT_DIR}:
   - graph.json
   - GRAPH_REPORT.md
   - graph.html
3. After completion, report the following metrics:
   - Total nodes
   - Total edges
   - Number of communities detected
   - Top 3 god nodes (highest-degree concepts)
PEOF
