# walk

## SYNOPSIS

mulle-sourcetree **walk** [options] <shell command>

## DESCRIPTION

Walk over the nodes described by the config file and execute a shell command for each node. The walk command provides extensive filtering, traversal, and callback options for processing sourcetree nodes.

Node information is passed to the shell command via environment variables. The command can be used for various operations like listing, processing, or analyzing sourcetree nodes.

## ENVIRONMENT VARIABLES

The following environment variables are set for each node during execution:

### Basic Node Information
- `WALK_NODE` : Complete node line content
- `NODE_FILENAME` : Where the node will be fetched to
- `NODE_ADDRESS` : Address part of the node
- `NODE_BRANCH` : Branch part of the node
- `NODE_FETCHOPTIONS` : Fetch options for the node
- `NODE_MARKS` : Marks of the node
- `NODE_RAW_USERINFO` : Raw userinfo (possibly base64 encoded)
- `NODE_TAG` : Tag part of the node
- `NODE_TYPE` : Node type
- `NODE_URL` : URL part of the node
- `NODE_UUID` : UUID of the node

### Walk Context Variables
- `WALK_DATASOURCE` : Current config file path
- `WALK_DEPENDENCY` : Parent dependency address
- `WALK_DESTINATION` : Recursion destination
- `WALK_INDENT` : Indentation spaces
- `WALK_INDEX` : Current node index
- `WALK_LEVEL` : Recursion depth
- `WALK_MODE` : Current walk mode
- `WALK_PARENT` : Parent node address
- `WALK_PARENT_NAME` : Parent node name
- `WALK_VIRTUAL` : Virtual path prefix
- `WALK_VIRTUAL_ADDRESS` : Virtual address

## OPTIONS

### Traversal Options
- `--flat` : Walk nodes without recursion (default)
- `--pre-order` : Walk tree depth-first (Root, Left, Right)
- `--in-order` : Walk tree in-order (Left, Root, Right)
- `--post-order` : Walk tree post-order (Left, Right, Root)
- `--breadth-order` : Walk tree breadth-first
- `--backwards` : Walk nodes in reverse order

### Filtering Options
- `-n <types>` : Node types to include (exclude with `no-<type>`)
- `-m <marks>` : Marks to match
- `-q <qualifier>` : Qualifier expression for marks
- `--callback-qualifier <q>` : Separate qualifier for callbacks
- `--descend-qualifier <q>` : Qualifier for recursion
- `--nodetypes <types>` : Node types to process

### Behavior Options
- `--cd` : Change to node's directory before executing command
- `--no-cd` : Don't change directory (default)
- `--lenient` : Allow command to fail without stopping walk
- `--no-lenient` : Stop on command failure (default)
- `--eval` : Evaluate the command string (default)
- `--no-eval` : Don't evaluate command string
- `--eval-node` : Evaluate node variables (NODE_EVALED_*)

### Deduplication Options
- `--no-dedupe` : Process all nodes, even duplicates
- `--dedupe-mode <mode>` : Set deduplication method

### Advanced Options
- `--comments` : Include comment nodes
- `--no-comments` : Exclude comment nodes
- `--bequeath` : Include bequeathed nodes
- `--no-bequeath` : Exclude bequeathed nodes
- `--walk-db` : Walk database instead of config files
- `--walk-config` : Walk config files (default)
- `--min-walk-level <n>` : Minimum recursion depth
- `--max-walk-level <n>` : Maximum recursion depth

## DEDUPLICATION MODES

- `address` : Dedupe by address
- `address-filename` : Dedupe by address and filename
- `address-marks-filename` : Dedupe by address, marks, and filename
- `address-url` : Dedupe by address and URL
- `filename` : Dedupe by filename
- `hacked-marks-nodeline-no-uuid` : Default mode
- `linkorder` : Dedupe for link ordering
- `nodeline` : Dedupe by complete node line
- `nodeline-no-uuid` : Dedupe by node line without UUID
- `none` : No deduplication
- `url-filename` : Dedupe by URL and filename

## QUALIFIER LANGUAGE

The qualifier language allows complex filtering of nodes based on marks:

```
<expr>  ::= <sexpr> AND <expr>
         | <sexpr> OR <expr>
         | <sexpr>

<sexpr> ::= (<expr>)
         | NOT <sexpr>
         | MATCHES <pattern>

<pattern> ::= <mark> '*'
            | <mark>

<mark> ::= only-[a-z-]*
        | no-[a-z-]*
```

## EXAMPLES

### Basic Usage
```bash
# List all node addresses
mulle-sourcetree walk 'printf "%s\n" "${NODE_ADDRESS}"'

# Show node information with indentation
mulle-sourcetree walk 'printf "%s%s\n" "${WALK_INDENT}" "${NODE_ADDRESS}"'
```

### Filtering Examples
```bash
# Only process build nodes
mulle-sourcetree walk --marks build 'echo "${NODE_ADDRESS}"'

# Use qualifier for complex filtering
mulle-sourcetree walk --qualifier 'MATCHES build' 'echo "${NODE_ADDRESS}"'

# Filter by node type
mulle-sourcetree walk --nodetypes git 'echo "${NODE_ADDRESS}: ${NODE_TYPE}"'
```

### Advanced Traversal
```bash
# Recursive walk with depth indication
mulle-sourcetree walk --pre-order 'printf "%s%s\n" "${WALK_INDENT}" "${NODE_ADDRESS}"'

# Breadth-first traversal
mulle-sourcetree walk --breadth-order 'echo "${WALK_LEVEL}: ${NODE_ADDRESS}"'

# Walk backwards
mulle-sourcetree walk --backwards 'echo "${NODE_ADDRESS}"'
```

### Working Directory Examples
```bash
# Change to node directory
mulle-sourcetree walk --cd 'pwd && ls -la'

# Execute command in node context
mulle-sourcetree walk --cd --lenient 'make clean'
```

### Finding Specific Nodes
```bash
# Find a specific dependency
mulle-sourcetree walk --lenient '[ "${NODE_ADDRESS}" = "zlib" ] && echo "${NODE_FILENAME}"'

# Search for duplicates
mulle-sourcetree walk --no-dedupe --lenient \
  '[ "${NODE_ADDRESS}" = "foo" ] && echo "${NODE_MARKS} (${WALK_DATASOURCE})"'
```

### Database vs Config Walking
```bash
# Walk database (after sync)
mulle-sourcetree walk --walk-db 'echo "${NODE_ADDRESS}"'

# Walk config files
mulle-sourcetree walk --walk-config 'echo "${NODE_ADDRESS}"'
```

## NOTES

- If no command is provided, prints the complete node line
- The working directory is changed to the node directory when using `--cd`
- Failed commands stop the walk unless `--lenient` is used
- Comment nodes are ignored unless `--comments` is specified
- Bequeathed nodes are excluded unless `--bequeath` is used
- Deduplication prevents processing the same node multiple times
- Environment variables provide comprehensive node information
- Complex filtering is possible with the qualifier language

## SEE ALSO

- [mulle-sourcetree list](list.md) - List nodes without executing commands
- [mulle-sourcetree status](status.md) - Show sourcetree status
- [mulle-sourcetree filter](filter.md) - Test filters with marks
- [mulle-sourcetree star-search](star-search.md) - Search for duplicate nodes