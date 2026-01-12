# remove

## SYNOPSIS

mulle-sourcetree **remove** [options] <address|url>

## DESCRIPTION

Remove nodes with the given url or address. You can specify multiple nodes to remove. (This command only affects the local sourcetree.)

## OPTIONS

- `--if-present` : don't complain if address is missing

## EXAMPLES

Remove a single node:
```bash
mulle-sourcetree remove src/mylib
```

Remove multiple nodes:
```bash
mulle-sourcetree remove src/lib1 src/lib2 src/lib3
```

Remove by URL:
```bash
mulle-sourcetree remove https://github.com/user/repo.git
```

Remove only if present (don't error if missing):
```bash
mulle-sourcetree remove --if-present src/optional-lib
```

## NOTES

- Removes nodes from the sourcetree configuration
- Does not remove files from the filesystem (use filesystem tools for that)
- Changes take effect immediately in the configuration
- Use `sync` to apply changes to the filesystem
- Can remove by address or URL
- Multiple nodes can be removed in a single command
- With `--if-present`, missing nodes are silently ignored

## SEE ALSO

- [mulle-sourcetree add](add.md) - Add a node to the sourcetree
- [mulle-sourcetree sync](sync.md) - Apply configuration changes to filesystem
- [mulle-sourcetree list](list.md) - List nodes in the sourcetree