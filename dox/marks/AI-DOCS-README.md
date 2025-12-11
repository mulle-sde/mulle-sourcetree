# mulle-sourcetree AI Documentation

This directory contains comprehensive AI-friendly documentation for the mulle-sourcetree and mulle-sde build system.

## Documentation Sets

### 1. Sync/Fetch Flow Documentation

**Purpose:** Understand how marks control node fetching and syncing

**Files:**
- `mulle-sourcetree-sync-marks-flow.svg` - Flowchart (embed in docs)
- `mulle-sourcetree-sync-marks-flow.png` - Raster alternative
- `mulle-sourcetree-sync-marks-flow.dot` - Source for regeneration
- `mulle-sourcetree-sync-marks-flow.md` - Complete explanation
- `FLOWCHART-PROMPT.md` - Regeneration instructions

**Start here:** Open `mulle-sourcetree-sync-marks-flow.md`

**Key concepts:**
- Decision tree showing mark-based control flow
- Covers: fetch blocking, update control, deletion protection, recursion
- Includes common mark combinations and debugging tips

---

### 2. Craft Pipeline Documentation

**Purpose:** Understand how marks flow through the build pipeline

**Files:**
- `mulle-sde-craft-pipeline.svg` - Architecture diagram (embed in docs)
- `mulle-sde-craft-pipeline.png` - Raster alternative
- `mulle-sde-craft-pipeline.dot` - Source for regeneration
- `mulle-sde-craft-marks-matrix.md` - Mark usage by tool
- `mulle-sde-craft-walkthrough.md` - Dependency journey narrative
- `mulle-sde-craft-pipeline-PROMPT.md` - Regeneration instructions

**Start here:** Open `mulle-sde-craft-marks-matrix.md`

**Key concepts:**
- Pipeline from sourcetree → code generation → build → link
- Mark usage matrix showing which tool uses which mark
- Step-by-step walkthrough of a dependency
- Debugging guidance for build issues

---

## Mark Definition Files

These JSON files provide structured mark definitions for AI consumption:

- `mulle-sourcetree-marks.json` - Sync/fetch marks
- `mulle-sourcetree-to-c-marks.json` - Header generation marks
- `mulle-sourcetree-to-cmake-marks.json` - CMake generation marks
- `../mulle-craft/mulle-craft-marks.json` - Build marks

---

## Quick Navigation

### "Why isn't my dependency being fetched?"
→ See `mulle-sourcetree-sync-marks-flow.md`
→ Check for: `no-fetch`, `no-update`, `no-platform-*`, `no-require`

### "Why isn't my dependency being built?"
→ See `mulle-sde-craft-marks-matrix.md` 
→ Check for: `no-build`, `no-craft-*`, `no-require-*`

### "Why isn't my dependency being linked?"
→ See `mulle-sde-craft-marks-matrix.md`
→ Check for: `no-link`, `no-cmake-add`, `no-actual-link`

### "How do I trace a dependency through the system?"
→ See `mulle-sde-craft-walkthrough.md`
→ Follow the step-by-step example

### "What does mark X do?"
→ See the relevant marks.json file
→ Or search in the matrix/flowchart docs

---

## Documentation Philosophy

All documentation is designed for **AI consumption**:

1. **Visual first:** Diagrams embedded prominently at the top
2. **Structured data:** Tables, JSON, clear sections
3. **Concrete examples:** Real code, real output, real scenarios
4. **Cross-referenced:** Documents link to each other
5. **Regeneratable:** PROMPT files explain how to recreate from scratch
6. **Debuggable:** Practical troubleshooting guidance

---

## Regeneration

Each documentation set includes a PROMPT.md file with complete instructions for regeneration by AI or humans.

**To regenerate sync flow docs:**
```bash
# Read FLOWCHART-PROMPT.md
# Regenerate .dot file
dot -Tsvg mulle-sourcetree-sync-marks-flow.dot -o mulle-sourcetree-sync-marks-flow.svg
```

**To regenerate craft pipeline docs:**
```bash
# Read mulle-sde-craft-pipeline-PROMPT.md
# Regenerate .dot file
dot -Tsvg mulle-sde-craft-pipeline.dot -o mulle-sde-craft-pipeline.svg
```

---

## Source Code References

**mulle-sourcetree:**
- Main sync logic: `src/mulle-sourcetree-action.sh`
- Walking/recursion: `src/mulle-sourcetree-walk.sh`
- Header generation: `mulle-sourcetree-to-c`
- CMake generation: `mulle-sourcetree-to-cmake`

**mulle-sde:**
- Craftorder: `libexec/mulle-sde-craftorder`
- Linkorder: `libexec/mulle-sde-linkorder`

**mulle-craft:**
- Build logic: `src/mulle-craft-build.sh`
- Mark qualification: `src/mulle-craft-qualifier.sh`

---

## Contributing

When adding new marks or changing behavior:

1. Update the relevant marks.json file
2. Update the flowchart/matrix documentation
3. Add examples to the walkthrough
4. Update the PROMPT files if structure changes

---

## License

Same as mulle-sourcetree project.

## Author

Documentation created with assistance from Claude (Anthropic) for Mulle kybernetiK.
