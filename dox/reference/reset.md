# reset

## SYNOPSIS

mulle-sourcetree **reset** [options]

## DESCRIPTION

Clear the sourcetree database to force a fresh synchronization. The reset command removes the local database file, causing the next `sync` operation to rebuild the entire sourcetree state from the configuration files.

This command is essential when the database becomes corrupted, outdated, or when you want to ensure a completely clean state. By default, graveyards (containing information about removed nodes) are preserved for recovery purposes.

## OPTIONS

### Primary Options
- `-g`, `--remove-graveyard` : Remove graveyard directories along with database
- `--no-remove-graveyard` : Preserve graveyards (default)

### Inherited Options
- `-r`, `--recurse` : Reset recursively through subtrees (when not in flat mode)
- `--flat` : Only reset current sourcetree (disable recursion)

## EXAMPLES

### Basic Database Reset
```bash
# Clear database for fresh synchronization
mulle-sourcetree reset
mulle-sourcetree sync  # Rebuild from configuration
```

### Complete Cleanup
```bash
# Reset database and remove all graveyards
mulle-sourcetree reset --remove-graveyard
```

### Recursive Operations
```bash
# Reset current sourcetree and all subtrees
mulle-sourcetree reset

# Reset only current sourcetree (flat mode)
mulle-sourcetree --flat reset
```

### Development Workflow
```bash
# Clean start after configuration changes
mulle-sourcetree reset
mulle-sourcetree sync --quick-check
```

## DATABASE OPERATIONS

### What Gets Removed

**Core Database Files:**
- `${MULLE_SOURCETREE_VAR_DIR}/db` - Main sourcetree database
- `${MULLE_SOURCETREE_VAR_DIR}/fix` - Fix tracking file

**Optional Removals:**
- Graveyard directories (with `--remove-graveyard`)
- Host-specific graveyards (with `--remove-graveyard`)

### What Gets Preserved

**Configuration Files:**
- All config files in `${MULLE_SOURCETREE_ETC_DIR}`
- Platform-specific configurations
- Shared configurations

**Fetched Dependencies:**
- All files in `${MULLE_SOURCETREE_STASH_DIR}`
- Symlinks and directories created during sync
- Local repository clones

**Recovery Data:**
- Graveyard contents (unless `--remove-graveyard` used)
- Configuration backup information

## WORKFLOW INTEGRATION

### Configuration Changes
```bash
# After modifying sourcetree configuration
vim .mulle/etc/sourcetree/config
mulle-sourcetree reset
mulle-sourcetree sync
```

### Troubleshooting Sync Issues
```bash
# When sync appears stuck or corrupted
mulle-sourcetree status  # Check current state
mulle-sourcetree reset   # Clear database
mulle-sourcetree sync    # Fresh synchronization
```

### Development Iteration
```bash
# Quick development cycle
mulle-sourcetree reset --remove-graveyard
mulle-sourcetree sync --serial  # Slower but more reliable
```

### CI/CD Pipeline Reset
```bash
# Ensure clean state in automated builds
mulle-sourcetree reset --remove-graveyard || true
mulle-sourcetree sync --parallel
```

## RECURSIVE BEHAVIOR

### Share Mode (Default)
```bash
mulle-sourcetree reset
```
- Resets current sourcetree database
- Recursively resets all subtree databases
- Maintains shared dependency relationships

### Flat Mode
```bash
mulle-sourcetree --flat reset
```
- Only resets current sourcetree database
- Does not affect subtree databases
- Faster for isolated operations

### Recurse Flag
```bash
mulle-sourcetree -r reset
```
- Forces recursive behavior
- Overrides flat mode settings
- Explicit recursive operation

## GRAVEYARD MANAGEMENT

### Default Behavior (Preserve)
```bash
mulle-sourcetree reset
```
- Keeps all graveyard directories
- Preserves recovery information
- Allows undeletion of recently removed nodes

### Complete Cleanup
```bash
mulle-sourcetree reset --remove-graveyard
```
- Removes all graveyard directories
- Irrevocably deletes recovery data
- Frees disk space

### Selective Graveyard Removal
```bash
# Remove only current host's graveyard
mulle-sourcetree reset --remove-graveyard

# Keep cross-platform graveyards
# (useful for multi-platform development)
```

## TROUBLESHOOTING

### Common Issues

**Permission denied:**
```bash
# Check file ownership
ls -la $(mulle-sourcetree var-dir)/db

# Use sudo if necessary
sudo mulle-sourcetree reset
```

**Database still exists after reset:**
```bash
# Check if file is locked by another process
lsof $(mulle-sourcetree var-dir)/db

# Kill conflicting processes
kill -9 <process-id>
mulle-sourcetree reset
```

**Reset doesn't help sync issues:**
```bash
# Try complete cleanup
mulle-sourcetree clean --fs --all-graveyards
mulle-sourcetree reset --remove-graveyard
mulle-sourcetree sync
```

### Verification

Check reset effectiveness:
```bash
# Verify database removal
ls -la $(mulle-sourcetree var-dir)/db || echo "Database removed"

# Check graveyard status
ls -la $(${MULLE_SOURCETREE_VAR_DIR}/../../*}/sourcetree/graveyard 2>/dev/null || echo "No graveyards"
```

## TECHNICAL DETAILS

### Database Structure
The sourcetree database contains:
- Node synchronization state
- File modification timestamps
- Dependency relationships
- Fix tracking information

### Reset Process
1. **Lock Acquisition**: Ensure exclusive database access
2. **File Removal**: Delete database and fix files
3. **Graveyard Cleanup**: Optionally remove graveyard directories
4. **Recursive Processing**: Handle subtrees if in recursive mode
5. **State Reset**: Clear all cached synchronization data

### Performance Considerations
- **Database Removal**: Instantaneous (file deletion only)
- **Graveyard Cleanup**: Proportional to graveyard size
- **Recursive Reset**: Scales with number of subtrees
- **Memory Usage**: Minimal (no large data structures)

### Safety Mechanisms
- **Atomic Operations**: File removals are atomic
- **Backup Preservation**: Configuration files untouched
- **Recovery Options**: Graveyards provide undo capability
- **Process Safety**: Handles concurrent access gracefully

## ENVIRONMENT VARIABLES

- `MULLE_SOURCETREE_VAR_DIR` : Location of database files
- `MULLE_SOURCETREE_MODE` : Affects recursive behavior

## DIFFERENCE FROM CLEAN

| Command | Database | Files | Graveyards | Use Case |
|---------|----------|-------|------------|----------|
| `clean` | Preserved | Removed | Preserved | Free disk space |
| `reset` | Removed | Preserved | Preserved | Fix sync issues |
| `reset -g` | Removed | Preserved | Removed | Complete reset |

## RECOVERY WORKFLOW

### Standard Recovery
```bash
# Reset and rebuild
mulle-sourcetree reset
mulle-sourcetree sync
```

### Emergency Recovery
```bash
# Complete cleanup and rebuild
mulle-sourcetree clean --fs --all-graveyards
mulle-sourcetree reset --remove-graveyard
mulle-sourcetree sync --serial
```

### Backup-Based Recovery
```bash
# Restore from configuration backup
cp backup-config .mulle/etc/sourcetree/config
mulle-sourcetree reset
mulle-sourcetree sync
```

## NOTES

- Database location: `${MULLE_SOURCETREE_VAR_DIR}/db`
- Fix file location: `${MULLE_SOURCETREE_VAR_DIR}/fix`
- Graveyards provide recovery from accidental deletions
- Reset is faster than full clean + sync cycle
- Safe to run multiple times without side effects
- Configuration files are never modified by reset
- Recursive behavior depends on sourcetree mode

## SEE ALSO

- [mulle-sourcetree sync](sync.md) - Rebuild database after reset
- [mulle-sourcetree clean](clean.md) - Remove fetched files
- [mulle-sourcetree status](status.md) - Check database state
- [mulle-sourcetree desecrate](desecrate.md) - Remove all graveyards
- [mulle-sourcetree info](info.md) - Show database information