# mulle-sourcetree fix

Automatically fix common sourcetree issues and inconsistencies.

## Synopsis

```bash
mulle-sourcetree fix [options] [node]
```

## Description

The `fix` command automatically detects and repairs common issues in the sourcetree configuration and filesystem state. It performs diagnostic checks and applies corrective actions to maintain sourcetree integrity.

## Options

- `--all` : Fix all detectable issues
- `--check-only` : Only check for issues, don't fix them
- `--force` : Apply fixes without confirmation
- `--verbose` : Show detailed fix information
- `--dry-run` : Show what would be fixed without executing
- `--backup` : Create backups before making changes

## Examples

### Basic Fixing
```bash
# Fix current sourcetree issues
mulle-sourcetree fix

# Fix specific node
mulle-sourcetree fix mylib

# Check what needs fixing
mulle-sourcetree fix --check-only
```

### Safe Fixing
```bash
# Preview fixes before applying
mulle-sourcetree fix --dry-run

# Fix with backups
mulle-sourcetree fix --backup

# Force fixes without prompts
mulle-sourcetree fix --force
```

### Comprehensive Fixing
```bash
# Fix everything
mulle-sourcetree fix --all

# Verbose output
mulle-sourcetree fix --verbose
```

## Types of Fixes

### Configuration Issues
- **Missing nodes**: Add nodes referenced but not defined
- **Broken references**: Fix invalid node references
- **Inconsistent marks**: Correct conflicting mark combinations
- **Invalid properties**: Fix malformed property values

### Filesystem Issues
- **Missing directories**: Create required directories
- **Incorrect permissions**: Fix file and directory permissions
- **Broken symlinks**: Repair or remove broken symbolic links
- **Stale files**: Remove outdated temporary files

### Synchronization Issues
- **Outdated nodes**: Update nodes that are behind
- **Missing fetches**: Fetch nodes that should be present
- **Incorrect locations**: Move nodes to correct locations
- **Version mismatches**: Align node versions with requirements

### Integrity Issues
- **Corrupted databases**: Rebuild corrupted sourcetree databases
- **Invalid UUIDs**: Regenerate invalid unique identifiers
- **Orphaned entries**: Remove entries without corresponding nodes
- **Circular dependencies**: Detect and break circular references

## Fix Categories

### Automatic Fixes
- Applied without user intervention
- Safe operations with no data loss
- Configuration corrections
- Permission fixes

### Interactive Fixes
- Require user confirmation
- May involve data changes
- Complex operations
- Potentially destructive actions

### Manual Fixes
- Cannot be automated safely
- Require user decision
- Complex dependency issues
- Major configuration changes

## Safety Features

### Backup Creation
- Automatic backup of modified files
- Recovery options for failed fixes
- Rollback capability
- Data preservation

### Confirmation Prompts
- Interactive confirmation for risky operations
- Clear description of changes
- Option to skip individual fixes
- Cancellation support

### Validation Checks
- Pre-fix validation of operations
- Post-fix verification
- Error detection and reporting
- Rollback on failure

## Common Use Cases

### Maintenance
```bash
# Regular integrity check
mulle-sourcetree fix --check-only

# Automated maintenance
mulle-sourcetree fix --all --force

# Safe maintenance with backups
mulle-sourcetree fix --backup
```

### Troubleshooting
```bash
# Fix after failed operations
mulle-sourcetree fix

# Diagnose issues without fixing
mulle-sourcetree fix --check-only --verbose

# Fix specific problematic node
mulle-sourcetree fix problematic-node
```

### Development Workflow
```bash
# Fix before committing changes
mulle-sourcetree fix --dry-run

# Clean up after experiments
mulle-sourcetree fix --all

# Prepare for release
mulle-sourcetree fix --force --verbose
```

## Integration with Other Commands

### With status
```bash
# Check status before fixing
mulle-sourcetree status --verbose
mulle-sourcetree fix
```

### With clean
```bash
# Clean and fix
mulle-sourcetree clean --all
mulle-sourcetree fix --all
```

### With sync
```bash
# Fix before syncing
mulle-sourcetree fix
mulle-sourcetree sync
```

## Performance Considerations

- `--all` can be slow for large sourcetrees
- Use `--check-only` for fast diagnosis
- `--dry-run` helps plan fixing operations
- Consider backup overhead for large fixes

## Notes

- Some fixes may require special permissions
- Complex issues may need manual intervention
- Always review `--dry-run` output before applying fixes
- Consider creating backups for critical sourcetrees

## See Also

- [`status`](status.md) - Show sourcetree status
- [`clean`](clean.md) - Clean artifacts and caches
- [`reset`](reset.md) - Reset sourcetree state
- [`sync`](sync.md) - Synchronize sourcetree