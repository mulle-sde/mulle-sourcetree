# clean

## SYNOPSIS

mulle-sourcetree **clean** [options]

## DESCRIPTION

Remove fetched files, symlinks, and optionally graveyards from the sourcetree. The clean command removes filesystem artifacts created during sync operations while preserving the sourcetree database and configuration.

By default, clean removes fetched files but keeps graveyards for recovery. Use specific options to control what gets cleaned. The database itself is never removed (use `reset` for that).

## OPTIONS

### Primary Cleaning Options
- `--fs` : Remove fetched files and directories (default when no graveyard options used)
- `--no-fs` : Don't remove fetched files

### Graveyard Management
- `--graveyard` : Remove host graveyard only, implies --no-fs
- `--all-graveyards` : Remove all graveyards across all hosts, implies --no-fs
- `--no-graveyard` : Don't remove graveyards (default)

### Advanced Options
- `--share` : Forcibly remove share directory (even if not empty)
- `--no-share` : Don't forcibly remove share directory (default)

## EXAMPLES

### Basic Usage

Clean all fetched files (default):
```bash
mulle-sourcetree clean
```

Clean only the current host's graveyard:
```bash
mulle-sourcetree clean --graveyard
```

Clean all graveyards on all hosts:
```bash
mulle-sourcetree clean --all-graveyards
```

### Advanced Cleaning

Clean everything including share directory:
```bash
mulle-sourcetree clean --fs --all-graveyards --share
```

Clean only fetched files, preserve graveyards:
```bash
mulle-sourcetree clean --fs --no-graveyard
```

Clean graveyards but not fetched files:
```bash
mulle-sourcetree clean --no-fs --all-graveyards
```

### Selective Cleaning

Clean only in specific modes:
```bash
# Clean recursively
mulle-sourcetree -r clean

# Clean in flat mode only
mulle-sourcetree --flat clean
```

## CLEANING PROCESS

### What Gets Removed

**Fetched Files:**
- Git repositories cloned during sync
- Downloaded archives (tar, zip, etc.)
- Extracted archive contents
- Generated files from build processes

**Filesystem Objects:**
- Regular files and directories
- Symbolic links created during sync
- Temporary files and caches

**Graveyards:**
- Backup directories containing removed nodes
- Host-specific graveyards (`${MULLE_SOURCETREE_VAR_DIR}/../../<hostname>/sourcetree/graveyard`)
- All graveyards when using `--all-graveyards`

**Share Directory:**
- Shared dependency storage (`${MULLE_SOURCETREE_STASH_DIR}`)
- Only removed if empty (unless `--share` is used)

### Protection Mechanisms

**Files NOT Removed:**
- Files marked with `no-delete` marks
- Local directories (nodetype `local`)
- Placeholder nodes (nodetype `none`)
- Comment nodes (nodetype `comment`)
- The sourcetree database itself
- Configuration files (unless explicitly requested)

## WORKFLOW INTEGRATION

### Development Cleanup
```bash
# Clean after experimental changes
mulle-sourcetree clean
mulle-sourcetree sync  # Fresh start
```

### Disk Space Management
```bash
# Check space usage before cleaning
du -sh $(mulle-sourcetree share-dir)

# Clean everything
mulle-sourcetree clean --fs --all-graveyards --share
```

### Recovery Operations
```bash
# Clean but keep graveyards for recovery
mulle-sourcetree clean --fs --no-graveyard

# Later recover if needed
# (graveyards contain backup copies)
```

## TROUBLESHOOTING

### Common Issues

**"Permission denied" errors:**
```bash
# Use sudo if necessary, or check file ownership
ls -la $(mulle-sourcetree share-dir)
```

**Files not being removed:**
```bash
# Check for no-delete marks
mulle-sourcetree list --marks no-delete

# Remove protection marks first
mulle-sourcetree unmark src/problematic no-delete
```

**Graveyard removal fails:**
```bash
# Check graveyard location
mulle-sourcetree var-dir
ls -la $(mulle-sourcetree var-dir)/../../*
```

### Verification

Check what would be cleaned:
```bash
# See what files exist before cleaning
find $(mulle-sourcetree share-dir) -type f | head -10

# Verify cleaning worked
mulle-sourcetree status
```

## TECHNICAL DETAILS

### Cleaning Algorithm

1. **Walk Configuration**: Traverse sourcetree nodes based on mode
2. **Evaluate Protection**: Check `no-delete` marks and node types
3. **Collect Targets**: Identify files/directories to remove
4. **Move to Graveyard**: Backup removable items (unless graveyard disabled)
5. **Remove Filesystem**: Delete files and directories
6. **Clean Graveyards**: Remove graveyard directories if requested
7. **Update Database**: Mark nodes as needing resync

### Graveyard System

- **Purpose**: Backup system for recovery
- **Location**: `${MULLE_SOURCETREE_VAR_DIR}/../../<hostname>/sourcetree/graveyard`
- **Contents**: Complete directory trees of removed nodes
- **Cleanup**: Use `--graveyard` or `--all-graveyards` to remove

### Performance Considerations

- **Parallel Processing**: Multiple files removed simultaneously
- **Recursive Walking**: Respects sourcetree mode (flat/share/recurse)
- **Memory Usage**: Minimal memory footprint
- **Disk I/O**: Intensive during large cleanups

## ENVIRONMENT VARIABLES

- `MULLE_SOURCETREE_STASH_DIR` : Location of fetched dependencies
- `MULLE_SOURCETREE_VAR_DIR` : Location of runtime data and graveyards

## NOTES

- Default behavior removes fetched files but preserves graveyards
- Graveyard operations automatically disable filesystem cleaning
- Protected files (no-delete) are never removed
- Share directory removal requires explicit `--share` flag
- Operations respect sourcetree mode and recursion settings
- Recovery possible from graveyards unless explicitly removed

## SEE ALSO

- [mulle-sourcetree sync](sync.md) - Fetch dependencies after cleaning
- [mulle-sourcetree reset](reset.md) - Clear database (more aggressive)
- [mulle-sourcetree status](status.md) - Check sourcetree state
- [mulle-sourcetree desecrate](desecrate.md) - Remove all graveyards
- [mulle-sourcetree list](list.md) - List nodes with protection marks