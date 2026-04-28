# Code Repository Reader for OpenCode

A powerful multi-agent system for analyzing and documenting code repositories using the OpenCode CLI. Automatically generates comprehensive documentation including concept summaries, knowledge graphs (via graphify), and deep-dive analyses with highlighted code snippets.

## 🚀 Quick Start

### One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/beginner1729/repo-reader/main/install.sh | bash
```

Or with a specific target directory:

```bash
curl -sSL https://raw.githubusercontent.com/beginner1729/repo-reader/main/install.sh | bash -s /path/to/your/project
```

### Manual Installation

1. Clone this repository:
```bash
git clone https://github.com/beginner1729/repo-reader.git
cd repo-reader
```

2. Copy the OpenCode configuration to your target project:
```bash
cp -r .opencode /path/to/your/project/
```

3. Run the agents:
```bash
cd /path/to/your/project
# Run the full workflow via helper script
.opencode/run.sh
```

## 📋 Prerequisites

- [OpenCode CLI](https://opencode.ai) installed and configured
- Python 3.10+ (for graphify knowledge graph builder)
- Git repository (optional but recommended)
- curl or wget (for installation script)

## 🏗️ Architecture Overview

The Code Repository Reader uses a **three-stage multi-agent pipeline**:

```
┌─────────────────────────────────────────────────────────────┐
│                     STAGE 1 (Sequential)                     │
│              ┌───────────────────────────────┐              │
│              │  graphify (Knowledge Graph)   │              │
│              │       Builder                 │              │
│              └───────────────┬───────────────┘              │
└──────────────────────────────┼──────────────────────────────┘
                               ▼
                    ┌──────────────────────┐
                    │   Knowledge Graph    │
                    │   (graph.json, etc.) │
                    └──────────┬───────────┘
                               │
┌──────────────────────────────┼──────────────────────────────┐
│                     STAGE 2 (Sequential)                     │
│              ┌───────────────────────────────┐              │
│              │   Broad Summary Agent (BSA)   │              │
│              └───────────────┬───────────────┘              │
└──────────────────────────────┼──────────────────────────────┘
                               ▼
                    ┌──────────────────────┐
                    │   Concept Summaries  │
                    └──────────┬───────────┘
                               │
┌──────────────────────────────┼──────────────────────────────┐
│                     STAGE 3 (Sequential)                     │
│              ┌───────────────────────────────┐              │
│              │   Snippet Builder Agent (SB)  │              │
│              └───────────────┬───────────────┘              │
└──────────────────────────────┼──────────────────────────────┘
                               ▼
                    ┌──────────────────────┐
                    │   Deep-Dive          │
                    │   Documentation      │
                    └──────────────────────┘
```

## 🤖 Agents & Subagents

### Main Agents

#### 1. Broad Summary Agent (BSA)
**Purpose**: Reads the entire repository and generates independent summaries for each distinct concept.

**Subagents Used**:
- `file_scanner` - Traverses repository and extracts raw file contents
- `concept_splitter` - Analyzes files and splits into conceptual blocks

**Logic**:
1. Uses File Scanner to read all repository files
2. Uses Concept Splitter to identify distinct concepts (classes, functions, modules)
3. For each concept, generates an independent summary file

**Output**: Summary files in `output/summaries/<concept_name>.summary.md`

**Example Output Structure**:
```markdown
# Summary: UserService

## Location
- File: src/services/user.py
- Lines: 15-89
- Type: class

## Purpose
Manages user authentication and profile operations.

## Key Components
- `authenticate(email, password)` - Validates user credentials
- `create_profile(data)` - Creates new user profile
- `update_profile(user_id, data)` - Updates existing profile

## Dependencies
- DatabaseConnection
- PasswordHasher
- EmailValidator

## Code Preview
```python
class UserService:
    def authenticate(self, email: str, password: str) -> User:
        ...
```
```

---

#### 2. graphify (Knowledge Graph Builder)
**Package**: `graphifyy` (PyPI)
**Purpose**: Builds knowledge graphs with community detection and confidence scoring. Analyzes dependencies and creates visual import maps.

**Logic**:
1. Scans all code files in the repository
2. Parses import statements (supports Python, JavaScript, TypeScript, Java, Go, Rust, etc.)
3. Identifies both internal and external dependencies
4. Builds knowledge graphs with nodes, edges, and communities
5. Generates interactive visualizations and graph reports

**Output**: Knowledge graph files in `output/graphify-out/`
- `graph.json` - Full knowledge graph with nodes, edges, communities
- `GRAPH_REPORT.md` - God nodes, surprising connections, suggested questions
- `graph.html` - Interactive visualization

**Example Output Structure**:
```markdown
# Graph Report

## God Nodes
- UserService (centrality: 0.85)
- DatabaseConnection (centrality: 0.72)

## Surprising Connections
- UserService → EmailValidator (unexpected direct dependency)

## Suggested Questions
- Why does UserService depend on EmailValidator directly?
- Should PasswordHasher be extracted into a shared utility?
```

---

#### 3. Snippet Builder Agent (SB)
**Purpose**: Generates the final deep-dive documentation by aggregating all previous outputs.

**Inputs**:
1. Summary outputs from BSA
2. Knowledge graph from graphify
3. Raw source code from repository

**Logic**:
1. Matches summaries with their dependency graphs
2. Extracts and highlights essential code snippets
3. Creates comprehensive cross-referenced documentation
4. Includes API references and testing considerations

**Output**: Deep-dive documentation in `output/deep_dives/<concept_name>.deepdive.md`

**Example Output Structure**:
```markdown
# Deep Dive: UserService

## Overview
UserService is the core authentication service handling user login, registration, and profile management. It implements JWT-based authentication with refresh tokens.

## Location
- Source File: `src/services/user.py`
- Lines: `15-89`

## Architecture & Dependencies
[Knowledge graph from graphify]

### Direct Dependencies
- **DatabaseConnection**: Provides PostgreSQL connectivity
- **PasswordHasher**: bcrypt-based password hashing
- **EmailValidator**: RFC-compliant email validation

### Used By
- AuthController (login/logout endpoints)
- ProfileController (profile CRUD operations)
- UserAdmin (administration panel)

## Core Implementation

### Key Code Snippets

#### 1. Authentication Flow
```python
def authenticate(self, email: str, password: str) -> User:
    """Authenticates user with email and password."""
    user = self.db.query(User).filter_by(email=email).first()
    if not user or not self.hasher.verify(password, user.password_hash):
        raise AuthenticationError("Invalid credentials")
    return user
```
**Explanation**: This is the core authentication method. It queries the database for the user by email, then verifies the password using bcrypt. Returns the User object on success or raises AuthenticationError.

#### 2. Password Hashing
```python
def _hash_password(self, password: str) -> str:
    """Hashes password using bcrypt."""
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt())
```
**Explanation**: Uses bcrypt with auto-generated salt for secure password storage. Never stores plaintext passwords.

### Design Patterns & Decisions
- **Repository Pattern**: UserService abstracts database operations
- **Dependency Injection**: External services injected via constructor
- **Fail-Safe Defaults**: Returns generic errors to prevent user enumeration attacks

## API Reference

### Public Methods
- `authenticate(email, password)` → User | AuthenticationError
- `create_profile(data)` → User
- `update_profile(user_id, data)` → User
- `delete_user(user_id)` → bool

## Related Concepts
- [AuthController](../summaries/auth_controller.summary.md)
- [User Model](../summaries/user_model.summary.md)
- [DatabaseConnection](../summaries/database_connection.summary.md)

## Testing Considerations
- **Unit Tests**: Mock DatabaseConnection and PasswordHasher
- **Integration Tests**: Use test database with known fixtures
- **Security Tests**: Test for SQL injection, timing attacks, brute force protection
- **Edge Cases**: Empty passwords, Unicode emails, concurrent requests
```

### Subagents

#### 1. File Scanner Subagent
**Purpose**: Fetches all files and extracts raw text from the target repository.

**Tools**: glob, read

**Inputs**:
- `repository_path` (string, required): Absolute path to target repository

**Outputs**:
- `file_list` (array): List of files with paths and content
  - `path`: Relative file path
  - `content`: Raw text content

**Behavior**:
- Scans common code file patterns (*.py, *.js, *.ts, *.tsx, *.java, *.go, *.rs, etc.)
- Excludes: node_modules/, .git/, venv/, .venv/, __pycache__/, dist/, build/
- Returns structured list for downstream processing

---

#### 2. Concept Splitter Subagent
**Purpose**: Analyzes a single file's content and splits into separate conceptual blocks.

**Tools**: read

**Inputs**:
- `file_path` (string, required): Path of file being analyzed
- `file_content` (string, required): Raw content of the file
- `language` (string, optional): Programming language

**Outputs**:
- `concepts` (array): List of conceptual blocks
  - `name`: Concept identifier (class/function name)
  - `type`: Concept category (class, function, interface, module, component)
  - `start_line`: Starting line number
  - `end_line`: Ending line number
  - `content`: Complete code block
  - `imports`: List of dependencies used by this concept

**Behavior**:
- Identifies class definitions, function definitions, interfaces, modules, components
- Supports multiple languages
- Provides precise line numbers for accurate referencing
- Extracts imports/references within each concept

## 📊 Workflow

### repo_reader_workflow

**Type**: Workflow
**Version**: 1.0.0

**Inputs**:
- `repository_path` (string, required): Path to target repository
- `output_base_directory` (string, optional): Where to save outputs (default: ./opencode-output)

**Execution Flow**:

#### Step 1: Sequential Analysis
Runs three agents sequentially:

1. **graphify (Knowledge Graph Builder)**
   - Input: `repository_path`, `output_directory=graphify-out/`
   - Output: `graph_files` (array of paths)

2. **Broad Summary Agent (BSA)**
   - Input: `repository_path`, `output_directory=summaries/`
   - Output: `summary_files` (array of paths)

3. **Snippet Builder Agent (SB)**
   - Input: 
     - `repository_path`
     - `summary_files_directory=summaries/`
     - `graph_files_directory=graphify-out/`
     - `output_directory=deep_dives/`
   - Output: `documentation_files` (array of paths)

**Outputs**:
- `graph_files`: Paths to all knowledge graph files generated by graphify
- `summary_files`: Paths to all summary files generated by BSA
- `documentation_files`: Paths to all deep-dive documentation files generated by SB
- `output_directories`: Map of output locations

## 📁 Output Structure

After running the workflow, you'll find:

```
your-project/
├── .opencode/                    # OpenCode configuration
│   ├── agents/
│   ├── subagents/
│   ├── workflows/
│   └── run.sh                    # Helper script
├── opencode-output/              # Generated documentation
│   ├── summaries/                # BSA output
│   │   ├── user_service.summary.md
│   │   ├── auth_controller.summary.md
│   │   └── ...
│   ├── graphify-out/             # graphify output
│   │   ├── graph.json            # Full knowledge graph
│   │   ├── GRAPH_REPORT.md       # Graph analysis report
│   │   └── graph.html            # Interactive visualization
│   └── deep_dives/               # SB output
│       ├── user_service.deepdive.md
│       ├── auth_controller.deepdive.md
│       └── ...
└── .gitignore                    # Updated to ignore opencode-output/
```

## 🎯 Usage Examples

### Basic Usage

```bash
# Navigate to your project
cd /path/to/your/project

# Run the installation
curl -sSL https://raw.githubusercontent.com/beginner1729/repo-reader/main/install.sh | bash

# Run the workflow
.opencode/run.sh
```

### Advanced Usage with Custom Options

```bash
# Run with custom output directory
opencode agent run graphify
# Run the full workflow
.opencode/run.sh

# Or run graphify skill directly via opencode
opencode run "/graphify . --directed"
```

### Using the Helper Script

After installation, use the provided helper script:

```bash
# Run full workflow
.opencode/run.sh

# Output will be in: ./opencode-output/
```

## 🔧 Supported Languages

The Code Repository Reader supports:

- **Python** (.py)
- **JavaScript** (.js, .jsx)
- **TypeScript** (.ts, .tsx)
- **Java** (.java)
- **Go** (.go)
- **Rust** (.rs)
- **Ruby** (.rb)
- **C/C++** (.c, .cpp, .h, .hpp)
- **C#** (.cs)
- **PHP** (.php)
- **Swift** (.swift)
- **Kotlin** (.kt)

*Note: Import parsing accuracy varies by language. Best support for Python, JavaScript/TypeScript, and Java.*

## 📈 Expected Output

### Small Project (~10 files, ~1000 lines)
- **Execution Time**: 1-2 minutes
- **Summaries**: 10-15 files
- **Graphs**: 10-15 files
- **Deep Dives**: 10-15 files
- **Total Output Size**: ~500 KB

### Medium Project (~50 files, ~5000 lines)
- **Execution Time**: 5-10 minutes
- **Summaries**: 40-60 files
- **Graphs**: 40-60 files
- **Deep Dives**: 40-60 files
- **Total Output Size**: ~2-3 MB

### Large Project (~200 files, ~20000 lines)
- **Execution Time**: 20-30 minutes
- **Summaries**: 150-250 files
- **Graphs**: 150-250 files
- **Deep Dives**: 150-250 files
- **Total Output Size**: ~10-15 MB

*Note: Actual times depend on code complexity and available compute resources.*

## 🐛 Troubleshooting

### Common Issues

**Issue**: Installation script fails to download files
```bash
# Solution: Check internet connectivity or use manual installation
git clone https://github.com/beginner1729/repo-reader.git
cp -r repo-reader/.opencode /path/to/your/project/
```

**Issue**: OpenCode CLI not found
```bash
# Solution: Install OpenCode CLI
npm install -g @opencode/cli
# or
pip install opencode-cli
```

**Issue**: Agent fails with "Agent not found"
```bash
# Solution: Verify configuration
cd /path/to/your/project
opencode agent list
```

**Issue**: Large repositories causing timeouts
```bash
# Solution: Run agents separately or increase timeout
opencode agent run broad_summary_agent \
    --timeout 3600 \
    --input repository_path="$(pwd)"
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for the [OpenCode](https://opencode.ai) platform
- Inspired by the need for automated code documentation
- Thanks to all contributors and users

## 📞 Support

- 📧 Email: your.email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/beginner1729/repo-reader/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/beginner1729/repo-reader/discussions)

---

Made with ❤️ for the OpenCode community
