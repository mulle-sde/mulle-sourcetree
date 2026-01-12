# sync

## SYNOPSIS

mulle-sourcetree **sync** [options]

## DESCRIPTION

Apply recent edits in the source tree to the filesystem. The configuration is read and the changes applied. This will fetch repositories and archives, if the destination is absent.

Use `${MULLE_EXECUTABLE_NAME}` fix, if you want to sync the source tree with changes you made in the filesystem. You can inhibit the fetching of a dependency by setting MULLE_SOURCETREE_FETCH_<name> to 'NO'. e.g. mulle-sde environment --os darwin MULLE_SOURCETREE_FETCH_FOUNDATION NO. mulle-sourcetree mark Foundation no-require-os-darwin

## OPTIONS

### Update Control Options
- `-r` : sync recursively
- `--serial` : don't fetch dependencies in parallel
- `--parallel` : fetch dependencies in parallel (default)
- `--quick-check` : if present in filesystem assume node is OK
- `--no-fix` : do not write ${SOURCETREE_FIX_FILENAME} files
- `--override-branch <branch>` : temporary override of the _branch for all nodes

### Fetch Options (passed through to mulle-fetch)
- `--cache-dir` : specify cache directory
- `--mirror-dir` : specify mirror directory
- `--search-path` : specify search path
- `--refresh` : refresh cache/mirror
- `--no-refresh` : don't refresh cache/mirror
- `--symlinks` : use symlinks
- `--no-symlinks` : don't use symlinks
- `--absolute-symlinks` : use absolute symlinks
- `--no-absolute-symlinks` : don't use absolute symlinks

## ENVIRONMENT

- **MULLE_SOURCETREE_RESOLVE_TAG** : resolve tags using mulle-fetch resolve (YES)
- **MULLE_SOURCETREE_FETCH_<name>** : set to NO to inhibit fetch of a dependency

## EXAMPLES

Basic sync:
```bash
mulle-sourcetree sync
```

Recursive sync:
```bash
mulle-sourcetree sync -r
```

Serial sync (no parallel fetching):
```bash
mulle-sourcetree sync --serial
```

Override branch for all nodes:
```bash
mulle-sourcetree sync --override-branch develop
```

Quick check (assume existing files are OK):
```bash
mulle-sourcetree sync --quick-check
```

Inhibit fetching of specific dependency:
```bash
MULLE_SOURCETREE_FETCH_FOUNDATION=NO mulle-sourcetree sync
```

## SEE ALSO

- [mulle-sourcetree fix](fix.md) - Support to track user modifications in the filesystem
- [mulle-sourcetree status](status.md) - Query state of the tree
- `mulle-fetch` - The underlying fetch tool