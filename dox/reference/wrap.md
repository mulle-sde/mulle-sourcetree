# wrap

## SYNOPSIS

mulle-sourcetree **wrap** [options]

## DESCRIPTION

Wrap tar, git, zip, and svn nodetypes in environment variables. Also wrap branches, tags, and URLs in environment variables. This command modifies the sourcetree configuration to allow runtime configuration through environment variables.

The wrap command transforms static values in the sourcetree configuration into environment variable references, enabling dynamic configuration without modifying the config files directly.

## OPTIONS

- `-h`, `--help` : Show help information

## HOW IT WORKS

The wrap command processes each node in the sourcetree and creates environment variable wrappers for:

1. **Node Types**: tar, git, zip, svn nodetypes
2. **Tags**: Version tags
3. **Branches**: Git branches (except for archives)
4. **URLs**: Repository and archive URLs

### Environment Variable Naming

For each node with address `mylib`, the following environment variables are created:

- `MYLIB_NODETYPE` : Controls the node type
- `MYLIB_TAG` : Controls the tag/version
- `MYLIB_BRANCH` : Controls the branch (git repos only)
- `MYLIB_URL` : Controls the repository/archive URL

## EXAMPLES

### Basic Usage
```bash
# Wrap all configurable values in the current sourcetree
mulle-sourcetree wrap
```

### Runtime Configuration
After wrapping, you can override values using environment variables:

```bash
# Override a library's tag
MYLIB_TAG=v2.1.0 mulle-sourcetree sync

# Use a different branch
MYLIB_BRANCH=develop mulle-sourcetree sync

# Change node type
MYLIB_NODETYPE=local mulle-sourcetree sync

# Use a different URL
MYLIB_URL=https://github.com/user/fork.git mulle-sourcetree sync
```

### Multiple Overrides
```bash
# Override multiple values at once
MYLIB_TAG=v1.2.3 OTHERLIB_BRANCH=feature-x mulle-sourcetree sync
```

## BEFORE AND AFTER

### Before wrap:
```
mylib;git;https://github.com/user/mylib.git;master;;no-require
```

### After wrap:
```
mylib;${MYLIB_NODETYPE:-git};${MYLIB_URL:-https://github.com/user/mylib.git};${MYLIB_BRANCH:-master};${MYLIB_TAG};;no-require
```

## USE CASES

### Development vs Production
```bash
# Development with latest code
MYLIB_BRANCH=develop mulle-sourcetree sync

# Production with stable release
MYLIB_TAG=v1.2.3 mulle-sourcetree sync
```

### Testing Different Versions
```bash
# Test compatibility with different library versions
MYLIB_TAG=v1.0.0 mulle-sourcetree sync
# ... run tests ...
MYLIB_TAG=v1.1.0 mulle-sourcetree sync
# ... run tests ...
```

### Using Forks or Mirrors
```bash
# Use a fork for development
MYLIB_URL=https://github.com/developer/mylib-fork.git mulle-sourcetree sync

# Use a mirror for faster downloads
MYLIB_URL=https://mirror.example.com/mylib.git mulle-sourcetree sync
```

### Platform-Specific Configuration
```bash
# Use local copy on macOS
MYLIB_NODETYPE=local MYLIB_URL=/opt/local/mylib mulle-sourcetree sync
```

## NOTES

- The command modifies the sourcetree configuration files
- Environment variables use the `:-` syntax for default values
- Only affects tar, git, zip, and svn nodetypes
- Branch wrapping is skipped for tar/zip archives
- URL wrapping only applies to http, ftp, file URLs and absolute paths
- Changes take effect immediately in the configuration
- Use `sync` to apply the wrapped configuration

## ENVIRONMENT VARIABLE SYNTAX

The wrap command uses bash parameter expansion syntax:

- `${VAR}` : Use environment variable or empty if not set
- `${VAR:-default}` : Use environment variable or default value if not set

## SEE ALSO

- [mulle-sourcetree sync](sync.md) - Apply configuration changes to filesystem
- [mulle-sourcetree set](set.md) - Change node properties directly
- [mulle-sourcetree list](list.md) - List current node configuration
- [mulle-sourcetree get](get.md) - Get current node values