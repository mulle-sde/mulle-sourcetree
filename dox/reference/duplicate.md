# duplicate

## SYNOPSIS

mulle-sourcetree **duplicate** [options] <address>

## DESCRIPTION

Duplicate a node in the sourcetree. The new node will have a numbered suffix appended (#1 for the first duplicate, #2 for the second, etc.). The duplicate is automatically marked as 'no-fs' to prevent duplicate fetches since it references the same URL as the original.

This command is useful when you need multiple references to the same dependency with different configurations or marks.

## OPTIONS

### Common Node Options
- `--address <dir>` : address of the node in the project
- `--branch <value>` : branch to use instead of the default for git
- `--fetchoptions <value>` : options for mulle-fetch --options
- `--marks <value>` : sourcetree marks of the node like no-require
- `--nodetype <value>` : the node type
- `--tag <value>` : tag to checkout for git
- `--url <url>` : url of the node
- `--userinfo <value>` : userinfo for node

## EXAMPLES

Duplicate a node:
```bash
mulle-sourcetree duplicate src/mylib
```

This creates `src/mylib#1` (or `#2`, `#3`, etc. depending on existing duplicates).

Duplicate with custom marks:
```bash
mulle-sourcetree duplicate --marks "no-build,no-require" src/mylib
```

Duplicate with different branch:
```bash
mulle-sourcetree duplicate --branch develop src/mylib
```

## HOW DUPLICATES WORK

1. **Automatic Naming**: The duplicate gets a numbered suffix (#1, #2, #3, etc.)
2. **Same URL**: The duplicate references the same URL as the original
3. **No-FS Mark**: Automatically marked as 'no-fs' to prevent duplicate fetches
4. **Independent Configuration**: Can have different marks, branches, tags, etc.

## USE CASES

### Multiple Build Configurations
```bash
# Original for release builds
mulle-sourcetree add --marks build src/mylib

# Duplicate for testing
mulle-sourcetree duplicate --marks "no-build,test-only" src/mylib
```

### Platform-Specific Variants
```bash
# Original
mulle-sourcetree add src/mylib

# Windows-specific duplicate
mulle-sourcetree duplicate --marks only-platform-windows src/mylib
```

### Different Branches
```bash
# Original on main branch
mulle-sourcetree add src/mylib

# Development duplicate
mulle-sourcetree duplicate --branch develop src/mylib
```

## NOTES

- Duplicates are automatically numbered sequentially
- The first duplicate gets `#1`, second gets `#2`, etc.
- Duplicates share the same URL but can have different configurations
- Automatically marked as 'no-fs' to avoid duplicate filesystem operations
- Useful for having multiple variants of the same dependency
- Changes take effect immediately in the configuration
- Use `sync` to apply changes to the filesystem

## SEE ALSO

- [mulle-sourcetree add](add.md) - Add a new node to the sourcetree
- [mulle-sourcetree remove](remove.md) - Remove a node from the sourcetree
- [mulle-sourcetree set](set.md) - Change node properties
- [mulle-sourcetree mark](mark.md) - Add marks to nodes