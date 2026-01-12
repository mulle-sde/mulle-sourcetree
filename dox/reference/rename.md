# rename

## SYNOPSIS

mulle-sourcetree **rename** <nodename> <newnodename>

## DESCRIPTION

Rename a node by changing its address. This command is a convenience wrapper around the `set` command that specifically changes the address field of a node.

The rename operation will update the node's address in the sourcetree configuration. The new address must not conflict with existing nodes.

## EXAMPLES

Rename a node:
```bash
mulle-sourcetree rename src/mylib src/newlib
```

Rename with a simpler name:
```bash
mulle-sourcetree rename src/complex-library-name lib
```

## HOW IT WORKS

The rename command internally calls:
```bash
mulle-sourcetree set <oldname> address <newname>
```

This means it follows the same validation rules as the `set` command:
- The old node must exist
- The new address must not conflict with existing nodes
- The node must not be marked as `no-set`

## NOTES

- This is a convenience command that wraps the `set address` functionality
- All validation rules from the `set` command apply
- Changes take effect immediately in the configuration
- Use `sync` to apply changes to the filesystem if needed
- Cannot rename nodes that are marked as `no-set`

## SEE ALSO

- [mulle-sourcetree set](set.md) - Change node properties (rename uses this internally)
- [mulle-sourcetree move](move.md) - Change node position in the sourcetree
- [mulle-sourcetree duplicate](duplicate.md) - Create duplicate nodes
- [mulle-sourcetree list](list.md) - List nodes in the sourcetree