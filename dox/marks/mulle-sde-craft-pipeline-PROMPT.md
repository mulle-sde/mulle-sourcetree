# Prompt for Regenerating mulle-sde Craft Pipeline Documentation

This document contains the prompt to regenerate or modify the mulle-sde craft pipeline documentation suite.

## Context

The mulle-sde build system uses a pipeline of tools that process sourcetree nodes (with marks) to generate code artifacts and build dependencies. This is more complex than a simple flowchart because multiple tools operate in parallel and feed into the build system.

## Documentation Suite Overview

Create four interconnected documents for AI consumption:

1. **Pipeline Architecture Diagram** - Shows how tools connect
2. **Mark Usage Matrix** - Comprehensive table of which tool uses which mark
3. **Dependency Walkthrough** - Narrative trace of one dependency through the system
4. **Prompt Document** - This file (for regeneration)

## Component 1: Pipeline Architecture Diagram

### File: `mulle-sde-craft-pipeline.dot` (Graphviz)

**Purpose:** Visual overview showing data flow between tools

**Structure:**
- **Layout:** Left-to-right (`rankdir=LR`)
- **Clusters for grouping:**
  - "Code Generators" (to-c, to-cmake)
  - "Dependency Orderers" (craftorder, linkorder)
  - "Build System" (craft, make, dispense)
- **Legend** showing node types

**Node Types:**
- **Source data**: Folder shape (sourcetree config)
- **Tools**: Component shape (each tool in pipeline)
- **Outputs**: Note shape (generated files)
- **Mark annotations**: Plaintext nodes showing marks used by each tool

**Key Elements:**
1. Source: `mulle-sourcetree config (nodes with marks)`
2. Tools:
   - `mulle-sourcetree-to-c` → generates headers
   - `mulle-sourcetree-to-cmake` → generates cmake files
   - `mulle-sde craftorder` → build order list
   - `mulle-sde linkorder` → link order list
   - `mulle-craft` → orchestrates build
   - `mulle-make` → actual build tool
   - `mulle-dispense` → install to dependency/
3. Outputs:
   - Generated headers (_include.h)
   - CMake files (Dependencies.cmake)
   - Build order list
   - Link order list
   - Built dependencies (dependency/ directory)

**Edges:**
- Solid arrows: Data flow
- Dashed arrows: Referenced during build
- Each tool has annotation showing primary marks it uses

**Colors:**
- Code Generators cluster: Blue
- Dependency Orderers cluster: Green
- Build System cluster: Orange
- Outputs: Light green

**Generate:**
```bash
dot -Tsvg mulle-sde-craft-pipeline.dot -o mulle-sde-craft-pipeline.svg
dot -Tpng mulle-sde-craft-pipeline.dot -o mulle-sde-craft-pipeline.png
```

## Component 2: Mark Usage Matrix

### File: `mulle-sde-craft-marks-matrix.md` (Markdown)

**Purpose:** Comprehensive reference showing which tool uses which mark

**Structure:**

### Header
- Title and description
- **Prominently embed pipeline SVG**
- Brief explanation

### Main Matrix Table
Columns: `Mark | to-c | to-cmake | craftorder | linkorder | craft | Description`

Symbols:
- ✓ = Mark is checked/used
- ⚠️ = Mark influences indirectly
- — = Not used

**Mark Categories to Include:**

1. **Build Control**
   - no-build, no-dependency, no-mainproject, no-memo, no-singlephase

2. **Platform Filtering**
   - no-platform-*, no-craft-platform-*, no-sdk-*, no-craft-sdk-*, no-craft-os-*, only-craft-release

3. **Requirements**
   - require, require-link, no-require, no-require-os-*, no-require-platform-*, no-require-sdk-*, no-require-configuration-*

4. **Header Generation**
   - no-header, no-import, no-public

5. **CMake Generation**
   - no-cmake-add, no-cmake-inherit, no-cmake-loader, no-cmake-searchpath, no-cmake-all-load, no-cmake-intermediate-link, no-cmake-suppress-system-path

6. **Linking**
   - no-link, no-actual-link, no-intermediate-link, no-all-load, no-dynamic-link, no-static-link, only-framework, only-standalone

7. **Dispense/Install**
   - no-inplace, no-rootheader, only-liftheaders

### Tool-Specific Sections
For each tool, provide:
- Brief description
- Primary marks it checks
- Output artifacts
- Example generated code/files

### Cross-Tool Mark Flow
Explain marks that affect multiple tools:
- `no-all-load` → affects to-cmake, linkorder, craft
- `no-require-*` → affects craftorder, craft
- Platform marks → different variants for different tools

### Typical Mark Combinations
Real-world examples:
- Header-only library
- Platform-specific dependency
- Objective-C framework
- Static-only library
- Development/debug dependency

### References
- Source files for each tool
- Mark definition JSON files
- Related documentation

## Component 3: Dependency Walkthrough

### File: `mulle-sde-craft-walkthrough.md` (Markdown)

**Purpose:** Trace a single dependency through the entire pipeline

**Structure:**

### Example Dependency
Choose a realistic example (e.g., zlib):
```
Address:   external/zlib
Marks:     share,update,no-header,no-all-load
Nodetype:  tar
```

### Step-by-Step Journey

For each tool in sequence:

**Step Template:**
```markdown
### Step N: [Tool Name] ([Purpose])

**Input:** What the tool receives

**Decision Logic:**
Check: Does node have [mark]?
→ YES/NO: Action taken

**Action:** What happens

**Output:** Generated artifacts (show actual code/file content)

**Why:** Explanation of reasoning
```

**Tools to Cover:**
1. Source configuration (sourcetree config)
2. mulle-sourcetree-to-c (header generation)
3. mulle-sourcetree-to-cmake (cmake generation)
4. mulle-sde craftorder (build order)
5. mulle-sde linkorder (link order)
6. mulle-craft (build execution)
7. Main project build (final consumption)

### Mark Influence Summary
Table showing how each mark affected each tool for this specific dependency

### Alternative Scenarios
Show how different marks would change the flow:
- Platform-specific dependency
- Header-only library
- Objective-C framework

### Timeline Visualization
ASCII art showing parallel/sequential execution:
```
mulle-sde craft
    │
    ├─> [Parallel] Generate code
    │   ├─> to-c
    │   └─> to-cmake
    ├─> craftorder
    ├─> For each dependency:
    │   └─> craft → make → dispense
    └─> Build main project
```

### Debugging Tips
Common issues and how to diagnose them:
- Dependency not building
- Not linking
- Headers not generated
- CMake not finding library

## Component 4: Prompt Document

### File: `mulle-sde-craft-pipeline-PROMPT.md` (Markdown)

This file (contains instructions for regenerating all components).

## Source Code References

To understand implementation, examine these repositories:

**mulle-sourcetree:**
- `mulle-sourcetree-to-c` - src/mulle-sourcetree-to-c.sh
- `mulle-sourcetree-to-cmake` - src/mulle-sourcetree-to-cmake.sh

**mulle-sde:**
- `mulle-sde craftorder` - libexec/mulle-sde-craftorder
- `mulle-sde linkorder` - libexec/mulle-sde-linkorder

**mulle-craft:**
- src/mulle-craft-qualifier.sh - Mark filtering logic
- src/mulle-craft-build.sh - Build orchestration
- src/mulle-craft-dependency.sh - Dependency handling

**Mark Definition Files:**
- mulle-sourcetree-marks.json
- mulle-sourcetree-to-c-marks.json
- mulle-sourcetree-to-cmake-marks.json
- mulle-craft-marks.json

## Style Guidelines

### Pipeline Diagram
- Clear visual hierarchy
- Group related components in clusters
- Use consistent colors for component types
- Include mark annotations near each tool
- Keep layout readable even with many components

### Matrix Table
- Use symbols (✓, ⚠️, —) for quick scanning
- Group related marks together
- Include description column
- Cross-reference between sections

### Walkthrough
- Use concrete examples with real output
- Show actual generated code/files
- Explain the "why" for each decision
- Include alternative scenarios
- Provide debugging guidance

## Target Audience

Primary audience: **AI systems** that need to understand the build pipeline

Secondary audience: Developers debugging build issues

Requirements:
- Machine-readable structure (tables, clear sections)
- Concrete examples with actual output
- Cross-references between documents
- Complete mark coverage
- Practical debugging guidance

## Validation Checklist

- [ ] Pipeline diagram shows all major tools
- [ ] Pipeline diagram includes mark annotations
- [ ] Matrix covers all marks from JSON files
- [ ] Matrix shows tool-specific groupings
- [ ] Walkthrough uses realistic example
- [ ] Walkthrough shows actual generated output
- [ ] Walkthrough includes alternative scenarios
- [ ] All tools cross-reference each other
- [ ] SVG and PNG generate without errors
- [ ] Documentation is AI-friendly (structured, concrete, complete)

## Tips for AI Regeneration

1. **Start with the pipeline diagram**: Understanding the architecture is key
2. **Build the matrix systematically**: Go through each marks.json file
3. **Choose a good walkthrough example**: Should touch most marks
4. **Show actual output**: Don't just describe, show real code
5. **Cross-reference aggressively**: Link between all documents
6. **Think about debugging**: What would someone need to know to fix issues?
7. **Keep it concrete**: Avoid abstractions, show real examples

## Output Files

Generate:
1. `mulle-sde-craft-pipeline.dot` - Graphviz source
2. `mulle-sde-craft-pipeline.svg` - Vector graphic
3. `mulle-sde-craft-pipeline.png` - Raster graphic
4. `mulle-sde-craft-marks-matrix.md` - Mark reference table
5. `mulle-sde-craft-walkthrough.md` - Narrative trace
6. `mulle-sde-craft-pipeline-PROMPT.md` - This file
