#!/bin/bash
#
# Copy-paste prompt for Step 4: documentation_website_agent
# Prints a prompt you can paste into the Claude Code TUI.
#
# Usage: .claude/prompt_documentation_website.sh | pbcopy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_BASE_DIR="$TARGET_DIR/opencode-output"
WEBSITE_OUTPUT_DIR="$TARGET_DIR/website"

cat << PEOF
Use the Task tool to invoke the documentation_website_agent subagent to build the final static documentation website.

Parameters:
- output_base_directory: ${OUTPUT_BASE_DIR}
- website_output_directory: ${WEBSITE_OUTPUT_DIR}

Instructions:
1. Read all deep-dive files from ${OUTPUT_BASE_DIR}/deep_dives.
2. Read the graphify outputs (${TARGET_DIR}/graphify-out/graph.json and GRAPH_REPORT.md).
3. Build a complete static documentation website (HTML/CSS/JS) with:
   - Dark/light theme toggle
   - Responsive layout
   - Subpage navigation inspired by the dependency graph
   - Cross-linked concept pages
4. Save the final website to ${WEBSITE_OUTPUT_DIR}.
5. Return the final_score and the full website_directory path.
PEOF
