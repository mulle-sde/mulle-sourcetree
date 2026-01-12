# mark

## SYNOPSIS

mulle-sourcetree **mark** [options] <node> <mark>

## DESCRIPTION

Add or remove marks from a node. Only negative marks (starting with "no-" or "only-") are actually stored in the node configuration. All positive marks are implicit.

Marks control various aspects of node behavior in the sourcetree. They can affect whether nodes are built, updated, shared, or participate in various operations.

## OPTIONS

- `--extended-mark` : allow the use of non-predefined marks
- `--regex` : use regular expression to find node address
- `--set` : clear previous marks and set new marks

## MARK TYPES

### Build & Craft
- `[no-]build` : the node contains a buildable project (used by craftorder)
- `[no-]header` : the node produces includable headers
- `[no-]link` : the node produces a linkable library

### Update & Sync
- `[no-]update` : the node takes part in update operations
- `[no-]require` : the node must exist
- `[no-]share` : the node may be shared with subtree nodes of the same URL

### Operations
- `[no-]delete` : the node may be deleted or moved
- `[no-]descend` : the node takes part in recursive operations
- `[no-]set` : the node's properties can be changed

### Platform Specific
- `[no-]platform-<name>` : platform-specific marks (darwin, linux, windows, etc.)
- `[no-]cmake-platform-<name>` : cmake platform-specific marks

### Advanced
- `[no-]all-load` : affects loading behavior
- `[no-]clobber` : affects file overwrite behavior
- `[no-]dependency` : affects dependency resolution
- `[no-]dynamic-link` : affects linking behavior
- `[no-]fs` : affects filesystem operations
- `[no-]import` : affects import behavior
- `[no-]inplace` : affects in-place operations
- `[no-]intermediate-link` : affects intermediate linking
- `[no-]public` : affects public visibility
- `[no-]readwrite` : affects read/write permissions
- `[no-]recurse` : affects recursive operations
- `[no-]singlephase` : affects build phases
- `[no-]static-link` : affects static linking

## EXAMPLES

Mark a node as not buildable:
```bash
mulle-sourcetree mark src/mylib no-build
```

Mark a node as required:
```bash
mulle-sourcetree mark src/mylib require
```

Remove a mark (implicit positive becomes negative):
```bash
mulle-sourcetree mark src/mylib no-require
```

Clear all marks and set new ones:
```bash
mulle-sourcetree mark --set src/mylib "no-build,no-update"
```

Use extended marks:
```bash
mulle-sourcetree mark --extended-mark src/mylib custom-mark
```

Use regex to match multiple nodes:
```bash
mulle-sourcetree mark --regex "src/lib.*" no-build
```

## HOW MARKS WORK

- **Negative marks** (no-*, only-*): Explicitly stored in configuration
- **Positive marks**: Implicit when negative marks are absent
- **Supermarks**: Can be decomposed into multiple individual marks
- **Inheritance**: Marks can affect child nodes in recursive operations

## COMMON USE CASES

### Disable building for documentation
```bash
mulle-sourcetree mark docs no-build
```

### Make node read-only
```bash
mulle-sourcetree mark src/vendor no-set,no-delete
```

### Platform-specific builds
```bash
mulle-sourcetree mark src/windows-only only-platform-windows
```

### Exclude from updates
```bash
mulle-sourcetree mark src/stable no-update
```

## NOTES

- Only negative marks are stored in the configuration file
- Positive marks are implicit (absence of corresponding negative mark)
- Use `list` command to examine current marks on nodes
- Extended marks require the `--extended-mark` option
- Regex matching requires the `--regex` option
- The `--set` option clears all existing marks first

## SEE ALSO

- [mulle-sourcetree unmark](unmark.md) - Remove marks from nodes
- [mulle-sourcetree list](list.md) - List nodes with their marks
- [mulle-sourcetree knownmarks](knownmarks.md) - List all known marks
- [mulle-sourcetree set](set.md) - Change node properties