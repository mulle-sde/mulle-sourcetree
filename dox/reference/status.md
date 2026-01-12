# status

## SYNOPSIS

mulle-sourcetree **status** [options]

## DESCRIPTION

Emit status of your sourcetree. The nodes listed are your projects sourcetree nodes and those nodes inherited by dependencies.

- **status** - shows the state of the database if any.
- **Filesystem** - shows the type of the dependency (directory or symlink)
- **Sourcetree** - shows if that project has a sourcetree.
- **Database** - shows if that project has synced at least once.

## OPTIONS

- `--all` : visit all nodes, even if they are unused due to sharing
- `--shallow` : don't visit sourcetrees of nodes
- `--deep` : visit the sourcetrees of nodes (default)
- `--is-uptodate` : return <> 0 if a sync is needed (preselects --shallow)
- `--output-filename` : add filename to output
- `-n <value>` : node types to walk (default: ALL)
- `-p <value>` : specify permissions (missing)
- `-m <value>` : specify marks to match (e.g. build)

## RETURN VALUES

- **0** : OK
- **1** : error
- **3** : there is no sourcetree
- **4** : needs update

## EXAMPLES

Basic status check:
```bash
mulle-sourcetree status
```

Check if up to date:
```bash
mulle-sourcetree status --is-uptodate
```

Shallow status (don't visit subtrees):
```bash
mulle-sourcetree status --shallow
```

Include filenames in output:
```bash
mulle-sourcetree status --output-filename
```

Status for specific marks:
```bash
mulle-sourcetree status -m build
```

## OUTPUT FORMAT

The output shows semicolon-separated fields:
```
Node;treestatus;Filesystem;Sourcetree;Database
```

Where:
- **Node**: The node address/path
- **treestatus**: Status of the sourcetree (ok, dirty, outdated, etc.)
- **Filesystem**: Type of filesystem object (directory, symlink, file, etc.)
- **Sourcetree**: Whether the project has a sourcetree (YES/NO/-)
- **Database**: Whether the project has been synced (YES/NO/-)

## SEE ALSO

- [mulle-sourcetree sync](sync.md) - Synchronize the project tree
- [mulle-sourcetree list](list.md) - List nodes in the sourcetree