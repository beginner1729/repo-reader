# OpenCode Test Suite

Comprehensive testing scripts to validate your OpenCode configuration files.

## Quick Start

Run all tests with a single command:

```bash
./tests/run-all-tests.sh
```

Or run individual test suites:

```bash
# Test YAML syntax
./tests/test-yaml.sh

# Test configuration structure
./tests/validate-config.sh

# Test OpenCode CLI integration
./tests/test-opencode-cli.sh
```

## Test Scripts

### 1. `run-all-tests.sh`
**Purpose**: Runs all test suites in sequence

**Usage**:
```bash
./tests/run-all-tests.sh [path_to_opencode_dir]
```

**Example**:
```bash
# Test current project
./tests/run-all-tests.sh

# Test specific directory
./tests/run-all-tests.sh /path/to/your/project/.opencode
```

**What it tests**:
- YAML syntax validation
- Configuration structure validation
- OpenCode CLI integration (if CLI is installed)

---

### 2. `test-yaml.sh`
**Purpose**: Validates YAML syntax of all configuration files

**Usage**:
```bash
./tests/test-yaml.sh [path_to_opencode_dir]
```

**Requirements**:
- `yq` (YAML processor) OR
- `python3` or `python`

**What it tests**:
- YAML frontmatter syntax
- Proper YAML structure
- No syntax errors in agent/subagent/workflow files

**Example output**:
```
🔍 YAML Syntax Tester
=====================
📂 Testing directory: /Users/koushik.dey/Work/repo-reader/.opencode

✅ Found python3

📂 Testing agents files...
-------------------------
Testing frontmatter in broad_summary_agent.md... ✅ Valid frontmatter
Testing frontmatter in snippet_builder_agent.md... ✅ Valid frontmatter

📂 Testing subagents files...
-------------------------
Testing frontmatter in concept_splitter.md... ✅ Valid frontmatter
Testing frontmatter in file_scanner.md... ✅ Valid frontmatter

📂 Testing workflows files...
-------------------------
Testing frontmatter in repo_reader_workflow.md... ✅ Valid frontmatter

=====================
📊 Summary
=====================
✅ All YAML syntax tests passed!
```

---

### 3. `validate-config.sh`
**Purpose**: Validates configuration structure and required fields

**Usage**:
```bash
./tests/validate-config.sh [path_to_opencode_dir]
```

**What it tests**:
- Presence of YAML frontmatter (---)
- Required fields: `name`, `type`, `description`
- Agent/subagent specific fields: `tools`, `instructions`
- Workflow specific fields: `steps`, `outputs`
- Tools format (simple list, not objects)
- Proper file types (agent, subagent, workflow)

**Validation Rules**:

| Field | Required For | Format |
|-------|-------------|--------|
| `name` | All files | string |
| `type` | All files | agent, subagent, or workflow |
| `description` | All files | string (multiline ok) |
| `tools` | Agents, Subagents | Simple list: `- tool_name` |
| `inputs` | Recommended | Array of objects |
| `outputs` | Workflows required | Array of objects |
| `instructions` | Agents, Subagents | string (multiline) |
| `steps` | Workflows required | Array |

**Example output**:
```
🔍 OpenCode Configuration Validator
=====================================
📂 Testing directory: /Users/koushik.dey/Work/repo-reader/.opencode

📋 Validating Agents...
------------------------
Testing agent: broad_summary_agent.md
✅ broad_summary_agent.md: Valid YAML frontmatter

📋 Validating Subagents...
---------------------------
Testing subagent: file_scanner.md
✅ file_scanner.md: Valid YAML frontmatter

📋 Validating Workflows...
---------------------------
Testing workflow: repo_reader_workflow.md
✅ repo_reader_workflow.md: Valid YAML frontmatter

=====================================
📊 Validation Summary
=====================================
✅ All tests passed!
   Errors: 0
   Warnings: 0
```

---

### 4. `test-opencode-cli.sh`
**Purpose**: Tests if OpenCode CLI can properly load the configuration

**Usage**:
```bash
./tests/test-opencode-cli.sh [path_to_opencode_dir]
```

**Requirements**:
- OpenCode CLI installed and in PATH

**What it tests**:
- CLI can validate configuration
- CLI can list agents
- CLI can list workflows
- CLI can load specific agents
- CLI can load specific workflows

**Example output**:
```
🧪 OpenCode CLI Integration Test
==================================
📂 Testing directory: /Users/koushik.dey/Work/repo-reader/.opencode

🔍 Checking OpenCode CLI...
✅ OpenCode CLI found

📦 OpenCode version:
0.5.2

✓ Found .opencode directory

🔧 Testing configuration validation...
✅ Configuration is valid

📋 Testing agent listing...
✅ Can list agents
Available agents:
  - broad_summary_agent
  - snippet_builder_agent

📋 Testing workflow listing...
✅ Can list workflows
Available workflows:
  - repo_reader_workflow

📋 Testing specific agents...
🔍 Testing agent: broad_summary_agent
✅ Agent 'broad_summary_agent' loaded successfully

🔍 Testing agent: snippet_builder_agent
✅ Agent 'snippet_builder_agent' loaded successfully

📋 Testing specific workflows...
🔍 Testing workflow: repo_reader_workflow
✅ Workflow 'repo_reader_workflow' loaded successfully

==================================
📊 Test Summary
==================================
🎉 All integration tests passed!
```

## Common Issues and Solutions

### Issue: "No YAML parser found"
**Solution**: Install yq or Python
```bash
# Install yq (macOS)
brew install yq

# Install yq (Linux)
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq

# Or ensure Python is installed
python3 --version
```

### Issue: "OpenCode CLI not found"
**Solution**: Install OpenCode CLI
```bash
# Via npm
npm install -g @opencode/cli

# Or via pip
pip install opencode-cli
```

### Issue: "Missing YAML frontmatter"
**Solution**: Ensure all .md files start with `---`
```yaml
---
name: my_agent
type: agent
# ... rest of config
```

### Issue: "Tools should be a simple list"
**Solution**: Change from object format to simple list
```yaml
# ❌ Incorrect
tools:
  - type: tool
    name: glob

# ✅ Correct
tools:
  - glob
```

## CI/CD Integration

You can integrate these tests into your CI/CD pipeline:

### GitHub Actions Example
```yaml
name: Test OpenCode Config

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install yq
        run: |
          wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
          chmod +x /usr/local/bin/yq
      
      - name: Run tests
        run: ./tests/run-all-tests.sh
```

### GitLab CI Example
```yaml
test-opencode:
  script:
    - apt-get update && apt-get install -y yq
    - ./tests/run-all-tests.sh
```

## Exit Codes

| Exit Code | Meaning |
|-----------|---------|
| 0 | All tests passed |
| 1 | One or more tests failed |

## Troubleshooting

1. **Permission denied**: Make scripts executable
   ```bash
   chmod +x tests/*.sh
   ```

2. **Path issues**: Use absolute paths
   ```bash
   ./tests/run-all-tests.sh $(pwd)/.opencode
   ```

3. **Parser errors**: Check YAML syntax with online validator
   - https://www.yamllint.com/
   - https://jsonformatter.org/yaml-validator

## Contributing

When adding new test scripts:
1. Make them executable: `chmod +x tests/your-script.sh`
2. Follow the existing output format (colors, emojis)
3. Add documentation to this README
4. Update `run-all-tests.sh` to include new tests
