---
name: concept_splitter
mode: subagent
description: |
  Analyzes a single file's raw content and splits it into separate conceptual blocks
  if multiple distinct concepts exist. A concept is defined as a coherent unit of code
  such as a class definition, function definition, interface, module, or component.

tools:
  read: true

inputs:
  - name: file_path
    type: string
    description: Path of the file being analyzed
    required: true
  - name: file_content
    type: string
    description: Raw text content of the file
    required: true
  - name: language
    type: string
    description: Programming language of the file (optional, auto-detected if not provided)
    required: false

outputs:
  - name: concepts
    type: array
    description: List of identified conceptual blocks
    items:
      type: object
      properties:
        name:
          type: string
          description: Name of the concept (e.g., class name, function name)
        type:
          type: string
          description: Type of concept (class, function, interface, module, etc.)
        start_line:
          type: integer
          description: Starting line number of the concept
        end_line:
          type: integer
          description: Ending line number of the concept
        content:
          type: string
          description: The actual code content of the concept
        imports:
          type: array
          description: List of imports/dependencies used by this concept
          items:
            type: string

instructions: |
  You are the Concept Splitter Subagent. Your task is to:
  
  1. Analyze the provided `file_content` and identify distinct conceptual units
  2. A concept can be:
     - Class definitions (class, struct, interface)
     - Function definitions (function, method, procedure)
     - Module/namespace definitions
     - Component definitions (for React/Vue/Angular components)
     - Type definitions (type aliases, enums)
     - Any other coherent, self-contained code unit
  
  3. For each concept identified, extract:
     - `name`: The identifier name of the concept
     - `type`: The category (class, function, interface, module, component, etc.)
     - `start_line`: Line number where the concept begins
     - `end_line`: Line number where the concept ends
     - `content`: The complete code block for this concept
     - `imports`: Any imports or external references within this concept
  
  4. If the file contains only a single concept (e.g., one class), return just that one concept
  5. If the file contains multiple concepts (e.g., multiple classes or mixed definitions),
     split them into separate entries
  
   Be precise with line numbers and ensure the content is complete. The goal is to enable
   independent summarization of each distinct concept.
---
