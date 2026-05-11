#!/bin/bash
#
# Prompt Generator for OpenCode TUI
# Produces a single prompt that can be pasted into the opencode interactive TUI
# to run the full repo-reader workflow (same result as .opencode/run.sh).
#
# Usage:
#   .opencode/prompt.sh              # prints prompt to stdout
#   .opencode/prompt.sh | pbcopy     # copy to clipboard (macOS)
#   .opencode/prompt.sh | xclip -selection clipboard  # copy to clipboard (Linux)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_BASE_DIR="$TARGET_DIR/opencode-output"
WEBSITE_OUTPUT_DIR="$TARGET_DIR/website"
GRAPHIFY_OUT_DIR="$TARGET_DIR/graphify-out"

MODEL="${OPENCODE_MODEL:-openai/gpt-5.3-codex}"

# Allow model override
while getopts "m:h" opt; do
    case "$opt" in
        m)
            MODEL="$OPTARG"
            ;;
        h)
            cat << 'HELP'
Usage: prompt.sh [-m model]

Generates a single prompt for the opencode TUI that runs the full
repo-reader workflow: graphify -> broad_summary -> snippet_builder -> documentation_website.

Options:
  -m model   Specify model id (default: openai/gpt-5.3-codex)
  -h         Show this help

Examples:
  ./prompt.sh
  ./prompt.sh -m anthropic/claude-sonnet-4
  ./prompt.sh | pbcopy
HELP
            exit 0
            ;;
        *)
            echo "Usage: prompt.sh [-m model] [-h]"
            exit 1
            ;;
    esac
done

cat << PEOF
Run the full Code Repository Reader workflow on this repository sequentially.
Use model ${MODEL}.

Repository path: ${TARGET_DIR}
Output base directory: ${OUTPUT_BASE_DIR}
Graphify output directory: ${GRAPHIFY_OUT_DIR}
Website output directory: ${WEBSITE_OUTPUT_DIR}

Execute the following 4 steps in order, one after another. Do not skip any step.

---

Step 1: graphify (knowledge graph builder)
- Run the /graphify skill on the repository at ${TARGET_DIR} with --directed flag.
- Ensure the graphify output is saved to ${GRAPHIFY_OUT_DIR}.
- After completion, report: node count, edge count, and number of communities detected.

---

Step 2: broad_summary_agent
- Invoke the broad_summary_agent subagent using the task tool.
- Pass these exact parameters:
  - repository_path: ${TARGET_DIR}
  - output_directory: ${OUTPUT_BASE_DIR}/summaries
  - graphify_files_directory: ${GRAPHIFY_OUT_DIR}
- The agent must:
  1. Read the graphify output first (GRAPH_REPORT.md and graph.json).
  2. Scan all files in the repository via the file_scanner subagent.
  3. Split each file into concepts via the concept_splitter subagent.
  4. For each file, use the graph to identify related files (dependencies, dependents, shared contracts) and read them for better context.
  5. Generate an independent summary file per concept in ${OUTPUT_BASE_DIR}/summaries using naming convention: <sanitized_concept_name>.summary.md.
- Return a short status with the generated file count only.

---

Step 3: snippet_builder_agent
- Invoke the snippet_builder_agent subagent using the task tool.
- Pass these exact parameters:
  - repository_path: ${TARGET_DIR}
  - summary_files_directory: ${OUTPUT_BASE_DIR}/summaries
  - graphify_files_directory: ${GRAPHIFY_OUT_DIR}
  - output_directory: ${OUTPUT_BASE_DIR}/deep_dives
- The agent must:
  1. Read all summary files and the graphify knowledge graph.
  2. For each concept, read the original source and related files.
  3. Produce comprehensive deep-dive documentation with essential code snippets.
  4. Save each deep-dive to ${OUTPUT_BASE_DIR}/deep_dives using naming convention: <concept_name>.deep_dive.md.
- Return a short status with the generated file count only.

---

Step 4: documentation_website_agent
- Activate the documentation_website_agent.
- Pass these exact parameters:
  - output_base_directory: ${OUTPUT_BASE_DIR}
  - website_output_directory: ${WEBSITE_OUTPUT_DIR}
- The agent must:
  1. Read all deep_dive files and graphify outputs.
  2. Build a complete static documentation website (HTML/CSS/JS) with dark/light theme toggle, responsive layout, and subpage navigation.
  3. Save the final website to ${WEBSITE_OUTPUT_DIR}.
- Return the final_score and the website_directory.

---

After all 4 steps are complete, print a concise summary:
- graphify: node count, edge count, communities
- broad_summary_agent: number of summary files generated
- snippet_builder_agent: number of deep-dive files generated
- documentation_website_agent: final score and website path
- Final output locations: summaries, deep_dives, website
PEOF
