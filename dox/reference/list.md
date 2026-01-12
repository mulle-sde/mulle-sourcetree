# list

## SYNOPSIS

mulle-sourcetree **list** [options]

## DESCRIPTION

List nodes in the sourcetree. You can restrict the nodes listed by nodetype and marks. The output can be formatted in printf like fashion. You can also list as mulle-sourcetree shell commands, to copy parts of the sourcetree to another project.

This command only reads config files.

A '/' indicates the project (which is no dependency)
A '-' indicates a no-bequeath entry.
A '*' indicates a duplicate (most often conflicting marks). Use the mulle-sourcetree star-search command to list duplicates by name.

Use the `mulle-sourcetree-export-json` command to list the current config in JSON format.

## OPTIONS

### Output Format Options
- `-l` : output long information
- `-ll` : output full information (except UUID)
- `-g` : output branch/tag information (-G for raw output)
- `-m` : output marks
- `-s` : output supermarks, supermarks are mark macros
- `-r` : recursive list
- `-u` : output URL information (use -U for raw output)

### Behavior Options
- `--bequeath` : inherit from nodes marked no-bequeath
- `--no-bequeath` : don't inherit from no-bequeath nodes (default)
- `--config-file <file>` : list a specific config file (no recursion)
- `--dedupe-mode <mode>` : change the way duplicates are detected
- `--format <format>` : supply a custom format (abfimntu_)
- `--force-format <format>` : like --format but unmodifiable by -g, -m etc.
- `--marks <value>` : specify marks to match (e.g. build)
- `--no-dedupe` : don't remove what are considered duplicates
- `--nodetype <value>` : node type to list, can be used multiple times
- `--qualifier <value>` : specify marks qualifier (see `walk` command)
- `--verbatim` : don't interpret errors

### Output Control Options
- `--output-banner` : print a banner with config information
- `--output-eval` : show evaluated values as passed to ${MULLE_FETCH:-mulle-fetch}
- `--output-format <value>` : possible values (fmt, cmd, raw)
- `--output-full` : show url and various fetch options
- `--output-no-column` : don't columnize output
- `--output-no-header` : suppress header in raw and default lists
- `--output-no-indent` : suppress indentation on recursive list
- `--output-no-marks <list>` : suppress output of certain marks (comma sep)
- `--output-no-separator` : suppress separator line if header is printed
- `--output-uuid` : print the UUID of each line

## DEDUPE MODES

- `address` : address
- `address-filename` : combination of address and filename
- `address-marks-filename` : combination of address marks url
- `address-url` : combination of address and url
- `filename` : name where sync will place it
- `hacked-marks-nodeline-no-uuid` : the default
- `linkorder` : used by linkorder
- `nodeline` : all fields
- `nodeline-no-uuid` : all fields except uuid
- `none` : no dedupe
- `url-filename` : combination of url and filename

## EXAMPLES

Basic listing:
```bash
mulle-sourcetree list
```

List with marks:
```bash
mulle-sourcetree list --marks build
```

List specific nodetype:
```bash
mulle-sourcetree list --nodetype git
```

Recursive listing:
```bash
mulle-sourcetree list -r
```

Custom format:
```bash
mulle-sourcetree list --format "%a;%u;%m"
```

List as commands for copying:
```bash
mulle-sourcetree list --output-format cmd
```

## SEE ALSO

- [mulle-sourcetree star-search](star-search.md) - Search for duplicates by name
- [mulle-sourcetree walk](walk.md) - Visit all sourcetree nodes with callback
- `mulle-sourcetree-export-json` - Export sourcetree as JSON