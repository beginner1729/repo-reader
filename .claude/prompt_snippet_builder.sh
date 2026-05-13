#!/bin/bash
#
# Copy-paste prompt for Step 3: snippet_builder_agent
# Prints a prompt you can paste into the Claude Code TUI.
#
# Usage: .claude/prompt_snippet_builder.sh | pbcopy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_BASE_DIR="$TARGET_DIR/opencode-output"
GRAPHIFY_OUT_DIR="$TARGET_DIR/graphify-out"

cat << PEOF
Use the Task tool to invoke the snippet_builder_agent subagent to produce comprehensive deep-dive documentation.

Parameters:
- repository_path: ${TARGET_DIR}
- summary_files_directory: ${OUTPUT_BASE_DIR}/summaries
- graphify_files_directory: ${GRAPHIFY_OUT_DIR}
- output_directory: ${OUTPUT_BASE_DIR}/deep_dives

Instructions:
1. Read all summary files from ${OUTPUT_BASE_DIR}/summaries.
2. Read the graphify knowledge graph (${GRAPHIFY_OUT_DIR}/graph.json and GRAPH_REPORT.md).
3. For each concept:
   a. Read the original source file.
   b. Read any related files identified in the graph (dependencies, dependents, shared types).
   c. Produce a comprehensive deep-dive document with highlighted essential code snippets.
4. Save each deep-dive to ${OUTPUT_BASE_DIR}/deep_dives using naming convention: <concept_name>.deepdive.md
5. Return a short status with the total number of deep-dive files generated.
PEOF
