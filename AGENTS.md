# Code Repository Reader - Agent Configuration

This document describes the multi-agent system for analyzing and documenting code repositories.

## System Overview

The Code Repository Reader is a multi-agent system designed to:
1. Scan and analyze entire code repositories
2. Identify distinct conceptual units (classes, functions, modules)
3. Generate independent summaries for each concept
4. Build dependency graphs showing connections between files
5. Create comprehensive deep-dive documentation with code snippets

## Agent Architecture

### Main Agents

#### 1. Broad Summary Agent (BSA)
**File**: `agents/broad_summary_agent.md`
**Type**: Agent
**Purpose**: Reads the entire repository and generates independent summaries for each distinct concept
**Subagents**: File Scanner, Concept Splitter
**Tools**: file_scanner (subagent), concept_splitter (subagent), write

#### 2. Connection Builder Agent (CBA)
**File**: `agents/connection_builder_agent.md`
**Type**: Agent
**Purpose**: Analyzes dependencies and creates visual import maps using Mermaid.js
**Tools**: glob, read, grep, write

#### 3. Snippet Builder Agent (SB)
**File**: `agents/snippet_builder_agent.md`
**Type**: Agent
**Purpose**: Generates final deep-dive documentation by aggregating BSA and CBA outputs
**Tools**: read, write, glob

### Subagents

#### 1. File Scanner Subagent
**File**: `subagents/file_scanner.md`
**Type**: Subagent
**Purpose**: Fetches all files and extracts raw text from the target repository
**Tools**: glob, read

#### 2. Concept Splitter Subagent
**File**: `subagents/concept_splitter.md`
**Type**: Subagent
**Purpose**: Analyzes file content and splits into separate conceptual blocks
**Tools**: read

## Workflow

**File**: `workflows/repo_reader_workflow.md`
**Type**: Workflow

### Execution Flow
1. **Step 1 (Parallel)**:
   - Run Broad Summary Agent (BSA)
   - Run Connection Builder Agent (CBA) simultaneously
2. **Step 2 (Sequential)**:
   - Run Snippet Builder Agent (SB) after Step 1 completes
   - Takes outputs from both BSA and CBA as inputs

## Directory Structure

```
/
├── opencode.yaml              # Main OpenCode configuration
├── AGENTS.md                  # This file - system overview
├── agents/
│   ├── broad_summary_agent.md
│   ├── connection_builder_agent.md
│   └── snippet_builder_agent.md
├── subagents/
│   ├── file_scanner.md
│   └── concept_splitter.md
└── workflows/
    └── repo_reader_workflow.md
```

## Configuration Files

All agent and workflow files follow the OpenCode markdown configuration format with YAML frontmatter:
- `name`: Unique identifier
- `type`: agent | subagent | workflow
- `description`: Human-readable purpose
- `tools`: List of available tools/subagents
- `inputs`: Required and optional input parameters
- `outputs`: Expected output structure
- `instructions`: Detailed operational guidelines

## Usage

To use this system with OpenCode:
1. Ensure the `opencode.yaml` configuration is loaded
2. Execute the workflow: `repo_reader_workflow`
3. Provide required inputs:
   - `repository_path`: Path to target repository
   - `output_base_directory`: Where to save outputs (default: ./output)

## Output Structure

```
output/
├── summaries/          # BSA output - concept summaries
├── mermaid_graphs/     # CBA output - dependency graphs
└── deep_dives/         # SB output - comprehensive documentation
```