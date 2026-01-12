# add

## SYNOPSIS

mulle-sourcetree **add** [options] <address|url>

## DESCRIPTION

Add a node to the sourcetree. This command creates a new node entry in the sourcetree configuration. You can specify either a URL for external repositories/archives or an address for existing local subdirectories.

Nodes with URLs will be fetched and potentially unpacked during the next `sync` operation. This command only modifies the local sourcetree configuration and does not perform any filesystem operations.

## OPTIONS

### Node Configuration Options
- `--address <dir>` : Explicitly set the address of the node in the project
- `--branch <value>` : Git branch to use instead of the default
- `--fetchoptions <value>` : Options passed to mulle-fetch
- `--marks <value>` : Comma-separated list of sourcetree marks (e.g., "no-require,no-build")
- `--nodetype <value>` : Node type (git, tar, zip, local, none, comment, symlink)
- `--tag <value>` : Git tag to checkout
- `--url <url>` : URL of the external repository or archive
- `--userinfo <value>` : Userinfo for authentication (encoded automatically)
- `--raw-userinfo <value>` : Raw userinfo string (base64 encoded)

### Control Options
- `--if-missing` : Only add if a node with the same address is not already present

## EXAMPLES

### Basic Usage

Add a local subdirectory:
```bash
mulle-sourcetree add src/mylib
```

Add an external Git repository:
```bash
mulle-sourcetree add --url https://github.com/user/repo.git src/repo
```

### Advanced Configuration

Add with specific branch and marks:
```bash
mulle-sourcetree add --branch develop --marks "no-build,no-require" src/mylib
```

Add with custom fetch options:
```bash
mulle-sourcetree add --fetchoptions "--depth 1" --url https://github.com/user/repo.git src/repo
```

Add with authentication:
```bash
mulle-sourcetree add --userinfo "username:password" --url https://github.com/user/private.git src/private
```

### Special Node Types

Add a comment node:
```bash
mulle-sourcetree add --nodetype comment "This is a comment node"
```

Add a local directory explicitly:
```bash
mulle-sourcetree add --nodetype local existing-folder
```

Add a placeholder node:
```bash
mulle-sourcetree add --nodetype none --marks "no-fs" placeholder-node
```

### Conditional Operations

Add only if missing:
```bash
mulle-sourcetree add --if-missing src/optional-lib
```

Force add (overwrite existing):
```bash
mulle-sourcetree add --force src/mylib
```

## NODE TYPES

### Repository Types
- **git** : Git repository (automatically detected for .git URLs)
- **svn** : Subversion repository
- **hg** : Mercurial repository

### Archive Types
- **tar** : Tar archive (automatically detected for .tar URLs)
- **zip** : Zip archive (automatically detected for .zip URLs)
- **tgz** : Gzipped tar archive

### Special Types
- **local** : Local directory (automatically marked no-delete,no-update,no-share)
- **none** : Placeholder node (automatically marked no-delete,no-fs,no-update,no-share)
- **comment** : Comment node for documentation (automatically marked no-fs)
- **symlink** : Symbolic link

## WORKFLOW INTEGRATION

### Typical Development Workflow
```bash
# Add a new dependency
mulle-sourcetree add --url https://github.com/user/library.git src/library

# Configure it appropriately
mulle-sourcetree set src/library marks "build,no-require"

# Fetch and set up
mulle-sourcetree sync
```

### Batch Addition with Scripts
```bash
# Add multiple dependencies
for dep in library1 library2 library3; do
    mulle-sourcetree add --url "https://github.com/user/${dep}.git" "src/${dep}"
done
```

## TROUBLESHOOTING

### Common Issues

**"A node already exists" error:**
```bash
# Use --if-missing to avoid conflicts
mulle-sourcetree add --if-missing src/mylib

# Or use different address
mulle-sourcetree add --url https://github.com/user/repo.git src/myrepo
```

**"Please specify --nodetype" error:**
```bash
# Provide explicit nodetype
mulle-sourcetree add --nodetype git --url https://example.com/repo src/repo
```

**Authentication issues:**
```bash
# Use userinfo for private repositories
mulle-sourcetree add --userinfo "user:token" --url https://github.com/user/private.git src/private
```

### Validation

Check if node was added correctly:
```bash
mulle-sourcetree list | grep "mylib"
mulle-sourcetree get src/mylib all
```

## TECHNICAL DETAILS

### Node Resolution Process

1. **Input Analysis**: Parse address/URL and options
2. **Type Detection**: Guess nodetype from URL or explicit specification
3. **Address Resolution**: Determine final address in sourcetree
4. **Mark Processing**: Decompose supermarks and apply automatic marks
5. **Validation**: Check for conflicts and validate parameters
6. **Configuration**: Write node to sourcetree config file

### Automatic Behaviors

- **Type Guessing**: URLs ending in .git → git, .tar.gz → tar, etc.
- **Mark Assignment**: Local/none/comment types get protective marks
- **Supermark Decomposition**: Tool → no-header,no-link, etc.
- **Conflict Prevention**: Duplicate addresses blocked by default

## ENVIRONMENT VARIABLES

- `MULLE_SOURCETREE_CONFIG_NAME` : Configuration file to modify
- `MULLE_SOURCETREE_STASH_DIR` : Where fetched dependencies are stored

## NOTES

- Changes are immediate in configuration but require `sync` for filesystem effects
- Node type detection is automatic but can be overridden
- Supermarks are expanded to individual marks automatically
- Local directories get protective marks to prevent accidental deletion
- Use `--if-missing` for idempotent operations in scripts
- Raw userinfo should be base64-encoded for complex authentication

## SEE ALSO

- [mulle-sourcetree remove](remove.md) - Remove a node from the sourcetree
- [mulle-sourcetree sync](sync.md) - Fetch and setup added nodes
- [mulle-sourcetree list](list.md) - List nodes in the sourcetree
- [mulle-sourcetree set](set.md) - Modify node properties
- [mulle-sourcetree get](get.md) - Retrieve node information
- [mulle-sourcetree eval-add](eval-add.md) - Batch add multiple nodes