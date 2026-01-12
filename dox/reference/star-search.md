# star-search

## SYNOPSIS

mulle-sourcetree **star-search** <node-address>

## DESCRIPTION

Search for duplicate nodes by name across the sourcetree. The star-search command finds all nodes with the same address and displays their marks, tags, branches, URLs, and source locations.

This command is useful for identifying duplicate dependencies and understanding how the same dependency is configured in different parts of the sourcetree.

## PARAMETERS

- `<node-address>` : The address of the node to search for

## EXAMPLES

### Basic Search
```bash
# Search for all nodes named 'zlib'
mulle-sourcetree star-search zlib
```

### Sample Output
```
no-require v1.2.3 master https://github.com/madler/zlib.git (.mulle/etc/sourcetree/config)
build v1.2.3 develop https://github.com/madler/zlib.git (subproject/.mulle/etc/sourcetree/config)
```

### Search for Common Dependencies
```bash
# Find all curl configurations
mulle-sourcetree star-search curl

# Find all openssl configurations
mulle-sourcetree star-search openssl
```

## OUTPUT FORMAT

Each line shows:
```
<marks> <tag> <branch> <url> (<config-file>)
```

Where:
- `<marks>` : Comma-separated list of marks
- `<tag>` : Version tag
- `<branch>` : Git branch
- `<url>` : Repository URL
- `<config-file>` : Relative path to configuration file

## USE CASES

### Identify Duplicates
```bash
# Find duplicate dependencies
mulle-sourcetree star-search boost
# Shows all boost configurations across the project
```

### Debug Configuration Conflicts
```bash
# Check if same dependency has conflicting configurations
mulle-sourcetree star-search libpng
# Look for different versions or branches
```

### Understand Dependency Sharing
```bash
# See how dependencies are shared across subprojects
mulle-sourcetree star-search zlib
# Shows which subprojects use which versions
```

### Version Management
```bash
# Check which projects use which versions
mulle-sourcetree star-search qt
# Helps plan version upgrades
```

## HOW IT WORKS

1. **Walks Configuration**: Searches through all sourcetree config files
2. **Finds Matches**: Locates all nodes with matching addresses
3. **Deduplicates**: Uses `nodeline-no-uuid` deduplication mode
4. **Formats Output**: Displays configuration details for each match
5. **Sorts Results**: Ensures consistent output ordering

## DIFFERENCE FROM LIST

- **list**: Shows all nodes in current sourcetree
- **star-search**: Shows all configurations of a specific node across all sourcetrees

## NOTES

- Searches recursively through all sourcetree configurations
- Shows relative paths to config files
- Useful for understanding complex project structures
- Helps identify configuration inconsistencies
- Output is sorted for consistent results

## SEE ALSO

- [mulle-sourcetree list](list.md) - List nodes in current sourcetree
- [mulle-sourcetree walk](walk.md) - Walk nodes with custom commands
- [mulle-sourcetree status](status.md) - Show sourcetree status
- [mulle-sourcetree duplicate](duplicate.md) - Create node duplicates