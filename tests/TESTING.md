# Code Repository Reader - Test Suite Summary

## Overview

The test suite provides comprehensive validation for your OpenCode configuration files, ensuring they are properly formatted and can be loaded by the OpenCode CLI.

## Test Scripts Created

### 1. **run-all-tests.sh** - Master Test Runner
Runs all test suites in sequence.

```bash
./tests/run-all-tests.sh [path_to_opencode_dir]
```

**Example Output**:
```
🧪 OpenCode Test Suite
======================
📂 Target directory: /Users/koushik.dey/Work/repo-reader/.opencode

Test 1/3: YAML Syntax Validation
---------------------------------
✅ All YAML syntax tests passed!
✅ YAML Syntax: PASSED

Test 2/3: Configuration Structure
----------------------------------
✅ All tests passed!
✅ Configuration Structure: PASSED

Test 3/3: OpenCode CLI Integration
-----------------------------------
⚠️  OpenCode CLI Integration: SKIPPED (CLI not installed)
   Install OpenCode CLI to run this test

======================
📊 Final Results
======================
🎉 All tests passed!

✅ Your OpenCode configuration is valid and ready to use!
```

---

### 2. **validate-config.sh** - Configuration Structure Validator
Validates the structure of all configuration files.

**What it validates**:
- ✓ YAML frontmatter present (starts with `---`)
- ✓ Required fields: `name`, `type`, `description`
- ✓ Agents/Subagents have: `tools`, `instructions`
- ✓ Workflows have: `steps`, `outputs`
- ✓ Tools format is correct (simple list, not objects)
- ✓ File types match their declarations

```bash
./tests/validate-config.sh [path_to_opencode_dir]
```

---

### 3. **test-yaml.sh** - YAML Syntax Validator
Validates YAML syntax using available tools.

**Supports**:
- **yq** (preferred) - Install with `brew install yq` (macOS) or download from GitHub releases
- **python3 + PyYAML** - Install with `pip3 install pyyaml`
- **Basic validation** (fallback) - No dependencies required

```bash
./tests/test-yaml.sh [path_to_opencode_dir]
```

**To install PyYAML**:
```bash
pip3 install pyyaml
```

---

### 4. **test-opencode-cli.sh** - CLI Integration Test
Tests if OpenCode CLI can load the configuration.

**Requirements**:
- OpenCode CLI installed

**What it tests**:
- Configuration validation
- Agent listing
- Workflow listing
- Loading specific agents
- Loading specific workflows

```bash
./tests/test-opencode-cli.sh [path_to_opencode_dir]
```

---

### 5. **install-deps.sh** - Dependency Installer
Installs required tools for testing.

```bash
./tests/install-deps.sh
```

---

## Directory Structure

```
tests/
├── README.md              # This file - comprehensive documentation
├── install-deps.sh        # Install test dependencies
├── run-all-tests.sh       # Run all tests (recommended)
├── test-yaml.sh          # YAML syntax validation
├── validate-config.sh    # Configuration structure validation
└── test-opencode-cli.sh  # OpenCode CLI integration tests
```

## Usage Examples

### Basic Usage - Test Current Directory

```bash
# Make scripts executable
chmod +x tests/*.sh

# Run all tests
./tests/run-all-tests.sh
```

### Test Specific Directory

```bash
# Test a specific project
./tests/run-all-tests.sh /path/to/your/project/.opencode
```

### Run Individual Tests

```bash
# Test YAML syntax only
./tests/test-yaml.sh

# Test configuration structure only
./tests/validate-config.sh

# Test OpenCode CLI integration
./tests/test-opencode-cli.sh
```

### Install Dependencies

```bash
# Install all required dependencies
./tests/install-deps.sh

# Or manually install PyYAML
pip3 install pyyaml
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Test OpenCode Config

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: |
          pip install pyyaml
      
      - name: Run configuration tests
        run: |
          chmod +x tests/*.sh
          ./tests/run-all-tests.sh
```

### GitLab CI

```yaml
test-opencode:
  image: python:3.9-slim
  script:
    - pip install pyyaml
    - chmod +x tests/*.sh
    - ./tests/run-all-tests.sh
```

## Test Results Interpretation

### Pass Criteria

| Test | Status | Meaning |
|------|--------|---------|
| YAML Syntax | ✅ | All files have valid YAML syntax |
| Configuration Structure | ✅ | All required fields are present and correctly formatted |
| CLI Integration | ✅ | OpenCode CLI can load all agents and workflows |

### Common Warnings (Non-Critical)

- "Missing 'description' field" - Recommended but not required
- "Missing 'inputs' field" - Recommended but not required
- "Missing 'outputs' field" - Required only for workflows
- "Unusual indentation" - YAML uses 2 or 4 spaces typically

### Common Errors (Critical)

- "Missing YAML frontmatter" - File must start with `---`
- "Missing 'name' field" - Every file needs a name
- "Missing 'type' field" - Must specify agent/subagent/workflow
- "Tools should be a simple list" - Change from objects to list format
- "Missing 'steps' field" - Required for workflows
- "Invalid YAML" - Syntax error in YAML structure

## Troubleshooting

### Issue: Permission Denied
```bash
chmod +x tests/*.sh
```

### Issue: No YAML Parser Found
```bash
# Option 1: Install yq (macOS)
brew install yq

# Option 2: Install PyYAML
pip3 install pyyaml

# Option 3: Tests will use basic validation (no installation required)
```

### Issue: OpenCode CLI Not Found
```bash
# Install OpenCode CLI
npm install -g @opencode/cli
# or
pip install opencode-cli
```

### Issue: Tests Pass But Agents Don't Work
1. Check that all files have proper YAML frontmatter
2. Verify tool names are correct
3. Ensure `type` field matches directory (agent/subagent/workflow)
4. Check OpenCode CLI version compatibility

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | One or more tests failed |

## Quick Reference

```bash
# Full test suite
./tests/run-all-tests.sh

# Individual tests
./tests/validate-config.sh
./tests/test-yaml.sh
./tests/test-opencode-cli.sh

# Install dependencies
./tests/install-deps.sh
pip3 install pyyaml
```

## Next Steps

After tests pass:

1. **Install to your project**:
   ```bash
   curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/repo-reader/main/install.sh | bash
   ```

2. **Run the workflow**:
   ```bash
   cd your-project
   .opencode/run.sh
   # or
   opencode workflow run repo_reader_workflow
   ```

3. **View documentation**:
   - Check `opencode-output/` directory for generated docs
   - View summaries, dependency graphs, and deep-dive analyses

## Support

If tests are failing:
1. Check the error messages carefully
2. Verify your YAML syntax at https://www.yamllint.com/
3. Compare your files with the examples in `.opencode/` directory
4. Review the OpenCode documentation

---

**Last Updated**: 2024
**Test Suite Version**: 1.0.0
