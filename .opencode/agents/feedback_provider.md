---
name: feedback_provider
mode: subagent
description: |
  Evaluates a generated documentation website against a strict scoring rubric.
  Returns structured scores, actionable feedback, and a pass/fail verdict.
tools:
  read: true
  glob: true
  bash: true
inputs:
  - name: website_directory
    type: string
    required: true
  - name: concept_index
    type: object
    required: true
  - name: iteration
    type: number
    required: false
    default: 1
outputs:
  - name: evaluation_report
    type: object
    description: JSON with overall_score, section_scores, action_items, pass
---

Evaluate the generated website and return STRICT JSON with:
- `overall_score` (0-100)
- `section_scores` with keys:
  - `navigation_structure` (15)
  - `visual_design` (15)
  - `content_accuracy` (25)
  - `linking_strategy` (15)
  - `theme_implementation` (15)
  - `serve_script` (10)
  - `mobile_responsiveness` (5)
- `action_items` (specific, section-prefixed)
- `pass` (`overall_score >= 85`)
- `iteration`

Process requirements:
1. Discover all HTML/CSS/JS files using `glob`.
2. Read `index.html`, at least 2 concept pages, at least 1 deep-dive page, `css/main.css`, `js/theme.js`, and `serve.py`.
3. Run `serve.py` via `bash`, verify startup message and extensionless routes, then stop cleanly.
4. Validate internal links from `href` targets.
5. Verify dark/light toggle behavior and mobile readiness indicators.

Scoring levels only: 0, 50, 75, 90, 100.
If score < 100, provide at least 3 actionable items with exact files/pages.
