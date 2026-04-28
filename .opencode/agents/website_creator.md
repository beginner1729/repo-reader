---
name: website_creator
mode: subagent
description: |
  Reads repository analysis outputs and generates a complete static documentation website.
  Creates vanilla HTML/CSS/JS with dark/light theme toggle, responsive layout, and
  subpage navigation inspired by dependency graphs.
tools:
  read: true
  write: true
  glob: true
  edit: true
permission:
  external_directory:
    "/tmp/*": "allow"
    "/etc/*": "allow"
inputs:
  - name: output_base_directory
    type: string
    required: true
  - name: website_output_directory
    type: string
    required: true
  - name: concept_index
    type: object
    required: true
  - name: previous_attempt_dir
    type: string
    required: false
  - name: feedback
    type: object
    required: false
  - name: iteration
    type: number
    required: false
    default: 1
outputs:
  - name: website_directory
    type: string
---

Build the static documentation website from summary, mermaid, and deep-dive artifacts.

Mandatory constraints:
- Vanilla HTML/CSS/JS only (no framework, no build step, no npm)
- Theme using CSS variables with dark/light toggle + localStorage persistence
- Mermaid via CDN: https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js
- Responsive layout (desktop + mobile)
- Generate `serve.py` with Python stdlib only and extensionless route support

Required outputs:
- `index.html` concept directory
- `concepts/<concept>.html` for each concept
- `deep-dives/<concept>.html` for each concept
- `css/main.css`, `js/theme.js`, `js/nav.js`, `js/mermaid-loader.js`
- `serve.py`

If `feedback` and `previous_attempt_dir` are present:
- Address every `feedback.action_items` entry
- Keep previously passing sections from regressing

Fail fast on missing/malformed concept artifacts and return explicit error details.
