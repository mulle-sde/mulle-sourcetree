# Prompt for Regenerating mulle-sourcetree Sync Flow Flowchart

This document contains the prompt to regenerate or modify the `mulle-sourcetree-sync-marks-flow` flowchart and documentation.

## Context

The mulle-sourcetree project uses "marks" to control node behavior during sync operations. These marks determine whether nodes are fetched, updated, deleted, or inherited by parent projects. The flowchart visualizes this decision tree.

## Task Description

Create a comprehensive flowchart showing how marks influence the sync/fetch process during `mulle-sourcetree sync`, along with accompanying documentation.

## Requirements

### 1. Flowchart Structure (Graphviz DOT format)

Create a directed graph (`digraph`) with these characteristics:

**Layout:**
- `rankdir=TB` (top to bottom)
- Use clusters for grouped logic (e.g., `r_is_fetchable()` function, fetch options)

**Node Shapes and Colors:**
- **Decision points** (mark checks): Yellow diamonds (`shape=diamond, fillcolor="#fff9c4"`)
- **Actions/operations**: Blue rounded boxes (`shape=box, style=rounded, fillcolor="#64b5f6"`)
- **Skip/block outcomes**: Orange rounded boxes (`fillcolor="#ffccbc"`)
- **Success/remember outcomes**: Green rounded boxes (`fillcolor="#c8e6c9"`)
- **Fatal errors**: Red rounded boxes (`fillcolor="#ef5350"`)
- **Start/end points**: Ellipses (`shape=ellipse`)
- **Notes/info**: Note shape for supplementary information

**Flow Logic to Include:**

1. **Early Exit Checks:**
   - `no-fs` → skip (no filesystem representation)
   - `comment` nodetype → skip
   - `no-update` → check if exists, check if required, remember or fail

2. **New Node Handling:**
   - Check if node exists in database
   - If file exists: check `no-clobber`, `no-delete`, `no-share-shirk`
   - If squatted by amalgamation → skip

3. **Fetchability Check (cluster: r_is_fetchable):**
   - `no-fetch` → block
   - `no-platform-<os>` or `no-fetch-platform-<os>` → block
   - `only-platform-<os>` or `only-fetch-platform-<os>` → override and allow
   - Otherwise → allow fetch

4. **Fetch Options (cluster: Fetch Options from marks):**
   - Show how marks translate to mulle-fetch options:
     - `no-symlink` → `--no-symlink` or `--copy`
     - `no-readwrite` → `--write-protect`

5. **Fetch Execution:**
   - Call mulle-fetch
   - On success → remember in database
   - On failure:
     - Check `no-require` or `no-require-os-<os>`
     - If not required → add to missing DB
     - If required → FAIL

6. **Update/Change Operations:**
   - Check `no-delete` before moving/removing
   - Perform update operations (checkout, upgrade, set-url, move)

7. **Recursion Control:**
   - Check `no-descend` → don't recurse into sourcetree
   - Check `no-bequeath` (only at walk level > 0) → don't inherit to parent
   - Otherwise → recurse into node's sourcetree

**Legend:**
Include a legend cluster showing all shape/color meanings.

### 2. Documentation Structure (Markdown)

Create a companion `.md` file with:

**Header:**
- Title and brief description
- **Prominently embed the SVG**: `![flowchart](mulle-sourcetree-sync-marks-flow.svg)`
- Brief explanation encouraging readers to trace through the flowchart

**Mark Categories Section:**
Organize marks by function with three columns: Mark | Effect | In Flowchart

Categories:
1. Marks that Skip Nodes Entirely
2. Marks that Control Update Behavior  
3. Marks that Control Fetch Blocking
4. Marks that Control Fetch Options
5. Marks that Control Error Handling
6. Marks that Control Deletion/Movement
7. Marks that Control Recursion
8. Marks that Control Sharing and Squatting

**How to Read the Flowchart Section:**
- Explain visual language (shapes, colors)
- Provide guidance on tracing through the flow

**Sync Flow Summary:**
- Step-by-step walkthrough matching the flowchart
- Reference specific decision points

**Common Mark Combinations:**
- Real-world examples with explanations:
  - Optional System Dependency
  - Local Development Override
  - Platform-Specific Dependency
  - Shared Dependency
  - Amalgamated Dependency
  - Non-Bequeathed Dependency

**Implementation Notes:**
- Key source files
- Important functions
- Mark semantic (disable by default, `no-*` removes, `only-*` overrides)

**Files Section:**
- List all generated files (.dot, .svg, .png, .md)

**Related Tools:**
- Cross-reference other marks.json files for related tools

### 3. Key Marks to Include

Ensure these marks are represented in the flowchart:

**Sync Control:**
- `no-fs`, `no-update`, `no-fetch`, `no-delete`, `no-clobber`

**Platform/OS:**
- `no-platform-<os>`, `no-fetch-platform-<os>`, `only-platform-<os>`, `only-fetch-platform-<os>`

**Requirements:**
- `no-require`, `no-require-os-<os>`

**Fetch Options:**
- `no-symlink`, `symlink-<os>`, `no-readwrite`

**Recursion:**
- `no-descend`, `no-bequeath`, `no-bequeath-os-<os>`

**Sharing:**
- `share`, `no-share`, `no-share-shirk`, `basename`

### 4. Output Files

Generate:
1. `mulle-sourcetree-sync-marks-flow.dot` - Graphviz source
2. `mulle-sourcetree-sync-marks-flow.svg` - Vector graphic (via `dot -Tsvg`)
3. `mulle-sourcetree-sync-marks-flow.png` - Raster graphic (via `dot -Tpng`)
4. `mulle-sourcetree-sync-marks-flow.md` - Documentation

### 5. Style Guidelines

**Flowchart:**
- Keep it readable: use whitespace, clear labels
- Use `\n` for multi-line labels
- Group related logic in clusters
- Consistent arrow labels ("yes"/"no" for decisions)

**Documentation:**
- Concise, clear language
- Use tables for structured information
- Code blocks for mark examples
- Reference flowchart throughout
- Provide practical examples

## Source Code References

To understand the actual implementation, examine:
- `src/mulle-sourcetree-action.sh` - Main sync logic, mark checking
  - Function: `sourcetree::action::r_is_fetchable()` - Fetch blocking marks
  - Function: `sourcetree::action::r_fetch_eval_options()` - Fetch option marks
  - Function: `sourcetree::action::r_update_actions_for_node()` - Update logic
- `src/mulle-sourcetree-walk.sh` - Walking/recursion logic, bequeath marks
- `src/mulle-sourcetree-sync.sh` - Sync orchestration
- `mulle-sourcetree-marks.json` - Complete mark definitions

## Example Usage

```bash
# Generate flowchart files
dot -Tsvg mulle-sourcetree-sync-marks-flow.dot -o mulle-sourcetree-sync-marks-flow.svg
dot -Tpng mulle-sourcetree-sync-marks-flow.dot -o mulle-sourcetree-sync-marks-flow.png

# View
xdg-open mulle-sourcetree-sync-marks-flow.svg
```

## Tips for AI Regeneration

1. **Start with the flow logic**: Map out the decision tree before writing DOT syntax
2. **Test incrementally**: Generate the flowchart after major sections to catch issues early
3. **Check mark consistency**: Every mark checked in code should appear in flowchart
4. **Cross-reference**: Ensure documentation matches flowchart structure
5. **Use clusters**: They help organize complex subgraphs visually
6. **Color coding is crucial**: Helps readers quickly identify decision vs. action vs. outcome

## Validation Checklist

- [ ] All major marks are represented as decision points
- [ ] Flow paths match actual code logic
- [ ] Legend explains all shapes/colors
- [ ] Documentation prominently shows SVG at top
- [ ] All mark categories are explained with flowchart references
- [ ] Common use cases have practical examples
- [ ] Both SVG and PNG generate without errors
- [ ] Documentation references source files and functions
