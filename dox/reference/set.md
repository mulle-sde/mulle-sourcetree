# set

## SYNOPSIS

mulle-sourcetree **set** <address> [key [value]]*

## DESCRIPTION

Change any value of a node referenced by <address> with the set command. Changes are applied with the next sync. (This command only affects the local sourcetree.)

## KEYS

- **address** : the address of the node
- **branch** : the (git) branch of the node
- **fetchoptions** : options passed to mulle-fetch
- **marks** : marks of the node
- **nodetype** : type of the node
- **tag** : the (git) tag of the node
- **url** : the url of the node
- **userinfo** : the userinfo of the node
- **raw_userinfo** : raw encoded userinfo

## EXAMPLES

Set the branch for a node:
```bash
mulle-sourcetree set src/mylib branch develop
```

Set multiple properties:
```bash
mulle-sourcetree set src/mylib branch develop tag v1.2.3
```

Set marks:
```bash
mulle-sourcetree set src/mylib marks "no-build,no-require"
```

Set URL:
```bash
mulle-sourcetree set src/mylib url https://github.com/user/repo.git
```

Set nodetype:
```bash
mulle-sourcetree set src/mylib nodetype git
```

## NOTES

- Changes take effect on the next `sync` command
- The node must exist in the sourcetree
- If a node is marked with `no-set`, the command will fail
- Address conflicts are checked to prevent duplicates
- Supermarks are automatically decomposed into individual marks

## SEE ALSO

- [mulle-sourcetree get](get.md) - Get node properties
- [mulle-sourcetree sync](sync.md) - Apply configuration changes to filesystem
- [mulle-sourcetree mark](mark.md) - Add/remove marks from nodes