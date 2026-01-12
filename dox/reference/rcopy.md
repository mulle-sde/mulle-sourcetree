# rcopy

## SYNOPSIS

mulle-sourcetree **rcopy** [options] <directory> <specifier> [qualifier]

## DESCRIPTION

Copy nodes from another sourcetree project. This is a simplified version of the `copy` command that allows you to copy complete nodes from another project's sourcetree.

The command reads the sourcetree configuration from the specified directory and copies matching nodes to the current project. You can specify which nodes to copy using a specifier and optionally filter them with qualifiers.

## OPTIONS

- `--update` : Update nodes if they already exist in the current sourcetree

## EXAMPLES

Copy a specific node from another project:
```bash
mulle-sourcetree rcopy ../other-project libz
```

Copy all nodes from another project:
```bash
mulle-sourcetree rcopy ../other-project "*"
```

Copy nodes with a specific qualifier:
```bash
mulle-sourcetree rcopy ../other-project "lib*" build
```

Update existing nodes when copying:
```bash
mulle-sourcetree rcopy --update ../other-project libz
```

## SPECIFIERS

- **Node name**: Copy a specific node by its address (e.g., `libz`, `src/mylib`)
- **Wildcard**: Use `*` to copy all nodes from the source project
- **Pattern**: Use shell-style wildcards to match multiple nodes (e.g., `lib*`, `src/*`)

## QUALIFIERS

Qualifiers allow you to filter nodes based on their marks. Only nodes that match the qualifier will be copied.

Common qualifiers include:
- `build` : Only copy nodes marked for building
- `require` : Only copy required nodes
- `share` : Only copy shareable nodes

## HOW IT WORKS

1. **Reads source config**: The command reads the sourcetree configuration from the specified directory
2. **Filters nodes**: Applies the specifier and qualifier to select nodes to copy
3. **Checks duplicates**: Verifies if nodes already exist in the current sourcetree
4. **Copies or updates**: Either adds new nodes or updates existing ones (with `--update`)

## NOTES

- This is a simplified version of the `copy` command
- The source directory must contain a valid sourcetree configuration
- Use `--update` to overwrite existing nodes with the same address
- Without `--update`, duplicate nodes are skipped with a warning
- Changes take effect immediately in the configuration
- Use `sync` to apply changes to the filesystem

## SEE ALSO

- [mulle-sourcetree copy](copy.md) - More advanced copying with field-level control
- [mulle-sourcetree add](add.md) - Add new nodes to the sourcetree
- [mulle-sourcetree sync](sync.md) - Apply configuration changes to filesystem
- [mulle-sourcetree list](list.md) - List nodes in the sourcetree