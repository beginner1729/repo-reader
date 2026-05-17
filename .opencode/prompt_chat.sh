#!/bin/bash
#
# Copy-paste prompt for Step 5: chat_creator_agent
# Prints a prompt you can paste into the opencode TUI.
#
# Usage: .opencode/prompt_chat.sh | pbcopy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_BASE_DIR="$TARGET_DIR/opencode-output"
WEBSITE_OUTPUT_DIR="$TARGET_DIR/website"
GRAPHIFY_OUT_DIR="$TARGET_DIR/graphify-out"

cat << PEOF
Run the chat_creator_agent to add a repository-focused chat widget to the documentation website.

Parameters:
- website_output_directory: ${WEBSITE_OUTPUT_DIR}
- output_base_directory: ${OUTPUT_BASE_DIR}
- graphify_files_directory: ${GRAPHIFY_OUT_DIR}
- repository_path: ${TARGET_DIR}

Instructions:
1. Verify the documentation website exists at ${WEBSITE_OUTPUT_DIR}.
2. Read the graphify outputs (${GRAPHIFY_OUT_DIR}/graph.json and GRAPH_REPORT.md).
3. Read available summaries from ${OUTPUT_BASE_DIR}/summaries.
4. Read available deep dives from ${OUTPUT_BASE_DIR}/deep_dives.
5. Create a FastAPI backend at ${WEBSITE_OUTPUT_DIR}/api/backend.py that:
   - Serves agent outputs and raw repository files via REST API endpoints
   - Stores user API keys securely in server-side session memory (never in cookies or localStorage)
   - Proxies chat requests to OpenAI, Anthropic Claude, or local Ollama with streaming (SSE)
   - Assembles context using summaries and deep dives, prioritized by the knowledge graph's community structure
   - Serves raw repository files on demand with directory traversal protection
6. Create a vanilla JS chat widget at ${WEBSITE_OUTPUT_DIR}/chat-widget.js embedded into all HTML pages.
7. Inject the widget script tag into every .html file in ${WEBSITE_OUTPUT_DIR}.
8. Create ${WEBSITE_OUTPUT_DIR}/start.sh to launch both the static site and the FastAPI backend.
9. Update ${WEBSITE_OUTPUT_DIR}/serve.py to accept an optional port argument.
10. Run the 7-item validation checklist and report pass/fail for each item.
11. Return: website_directory, validation_checklist_passed, files_created, and startup_command.
PEOF
