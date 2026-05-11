#!/bin/bash
#
# Copy-paste prompt for Step 2: broad_summary_agent
# Prints a prompt you can paste into the opencode TUI.
#
# Usage: .opencode/prompt_broad_summary.sh | pbcopy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_BASE_DIR="$TARGET_DIR/opencode-output"
GRAPHIFY_OUT_DIR="$TARGET_DIR/graphify-out"

cat << PEOF
Run the broad_summary_agent to generate independent concept summaries for this repository.

Parameters:
- repository_path: ${TARGET_DIR}
- output_directory: ${OUTPUT_BASE_DIR}/summaries
- graphify_files_directory: ${GRAPHIFY_OUT_DIR}

Instructions:
1. Read the graphify output first:
   - ${GRAPHIFY_OUT_DIR}/GRAPH_REPORT.md (god nodes, communities, surprising connections)
   - ${GRAPHIFY_OUT_DIR}/graph.json (community memberships, dependency edges, confidence scores)
2. Scan all files in the repository using the file_scanner subagent.
3. For each file, split it into distinct concepts using the concept_splitter subagent.
4. For each concept, use the graph to identify related files (dependencies, dependents, shared contracts) and read those related files to enrich context.
5. Generate one summary file per concept in ${OUTPUT_BASE_DIR}/summaries with naming convention: <sanitized_concept_name>.summary.md
6. Each summary must include: Purpose, Key Components, Dependencies, Knowledge Graph Context (community, god node status, key connections), and a Code Preview.
7. Return a short status with the total number of summary files generated.
PEOF
