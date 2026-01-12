# move

## SYNOPSIS

mulle-sourcetree **move** <specifier> top|bottom|up|down>
mulle-sourcetree **move** <specifier> to|before|after <specifier>

## DESCRIPTION

Change the position of a node with a certain <specifier> in the sourcetree. Node specifiers are:

- index position in the tree starting from 0 (use mulle-sourcetree list --output-index)
- node address
- node URL evaluated and "as is"
- the UUID of the node (use mulle-sourcetree list --output-uuid)

Changing the order of the node affects the order dependencies are crafted and also affects the linkorder.

With "to","before","after" you can move a node relative to another node of the tree.

## EXAMPLES

Move node to top of list:
```bash
mulle-sourcetree move src/mylib top
```

Move node to bottom:
```bash
mulle-sourcetree move src/mylib bottom
```

Move node up one position:
```bash
mulle-sourcetree move src/mylib up
```

Move node down one position:
```bash
mulle-sourcetree move src/mylib down
```

Move node to specific index:
```bash
mulle-sourcetree move src/mylib to 5
```

Move node before another node:
```bash
mulle-sourcetree move src/mylib before src/otherlib
```

Move node after another node:
```bash
mulle-sourcetree move src/mylib after src/otherlib
```

Move by UUID:
```bash
mulle-sourcetree move 78cfb19c-00ec-4df6-9c13-00a6aa134000 top
```

Move by URL:
```bash
mulle-sourcetree move https://github.com/user/repo.git to 0
```

## NOTES

- Changes take effect immediately in the configuration
- Use `sync` to apply changes to the filesystem if needed
- Node order affects dependency resolution and linking order
- Invalid specifiers or positions will result in errors
- The command validates that the move operation is possible

## SEE ALSO

- [mulle-sourcetree list](list.md) - List nodes in the sourcetree
- [mulle-sourcetree sync](sync.md) - Apply configuration changes to filesystem