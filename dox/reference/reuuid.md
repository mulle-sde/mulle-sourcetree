# reuuid

## SYNOPSIS

mulle-sourcetree **reuuid** [options]

## DESCRIPTION

Generate new universally unique identifiers (UUIDs) for all nodes in the sourcetree configuration. This command is essential when duplicating projects to prevent UUID conflicts between the original and copy.

UUIDs are used internally by sourcetree to track nodes uniquely. When you copy a project, both the original and copy will have identical UUIDs, which can cause database corruption and synchronization issues. The reuuid command resolves this by assigning fresh UUIDs to all nodes.

**Important:** This command removes all '#' comments from configuration files and requires a database reset afterward.

## OPTIONS

This command currently has no options.

## EXAMPLES

### Basic UUID Regeneration
```bash
# Generate new UUIDs for all nodes in current configuration
mulle-sourcetree reuuid
```

### Complete Project Forking Workflow
```bash
# 1. Create project copy
cp -r my-project my-project-fork
cd my-project-fork

# 2. Generate unique identity
mulle-sourcetree reuuid

# 3. Reset database state
mulle-sourcetree reset

# 4. Rebuild with new identity
mulle-sourcetree sync
```

### Template-Based Project Creation
```bash
# Use project as template
cp -r project-template new-project
cd new-project

# Make it unique
mulle-sourcetree reuuid
mulle-sourcetree reset
mulle-sourcetree sync
```

## TECHNICAL OPERATION

### Process Flow

1. **Configuration Loading**: Reads current sourcetree config file
2. **UUID Generation**: Creates RFC 4122 compliant UUIDs for each node
3. **Comment Removal**: Strips all '#' comments (implementation limitation)
4. **File Update**: Writes modified configuration with new UUIDs
5. **Validation**: Ensures all nodes have valid UUIDs

### UUID Format
Generated UUIDs follow the standard format:
```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```
Example: `f47ac10b-58cc-4372-a567-0e02b2c3d479`

## USE CASES

### Project Branching
```bash
# Create development branch with independent sourcetree
cp -r main-project dev-project
cd dev-project
mulle-sourcetree reuuid  # Independent identity
mulle-sourcetree reset   # Clean state
mulle-sourcetree sync    # Fresh start
```

### Multi-Environment Setup
```bash
# Development environment
cp -r base-project dev-env
cd dev-env
mulle-sourcetree reuuid

# Testing environment
cp -r base-project test-env
cd test-env
mulle-sourcetree reuuid

# Production environment
cp -r base-project prod-env
cd prod-env
mulle-sourcetree reuuid
```

### Template Distribution
```bash
# Prepare template for distribution
mulle-sourcetree reuuid  # Remove template UUIDs
# Package template without UUID conflicts
```

### Collaborative Development
```bash
# Team member creates working copy
cp -r shared-project my-workspace
cd my-workspace
mulle-sourcetree reuuid  # Avoid conflicts with shared project
```

## UUID CONFLICT SCENARIOS

### Database Corruption
Without unique UUIDs, sourcetree databases can become corrupted:
```bash
# Original project database
# Copy project database
# Result: Conflicting entries, corruption
```

### Synchronization Failures
```bash
# Both projects try to sync same dependency
# Result: Race conditions, inconsistent state
```

### Merge Conflicts
```bash
# Changes in copy can't be merged back
# Result: Lost work, manual conflict resolution
```

### Dependency Confusion
```bash
# Projects reference wrong dependencies
# Result: Build failures, runtime errors
```

## VERIFICATION AND VALIDATION

### Check UUID Uniqueness
```bash
# Verify all UUIDs are unique
mulle-sourcetree list --output-uuid | sort | uniq -c | grep -v '^ *1 '

# Should return no output (all UUIDs unique)
```

### Validate UUID Format
```bash
# Check UUID format compliance
mulle-sourcetree list --output-uuid | grep -E '^[^-]*-[^-]*-[^-]*-[^-]*-[^-]*$'

# All output should match UUID pattern
```

### Configuration Integrity
```bash
# Verify config file is valid after reuuid
mulle-sourcetree list >/dev/null && echo "Configuration valid"
```

## TROUBLESHOOTING

### Comment Loss Issue
```bash
# Problem: Comments are removed
# Solution: Recreate comments after reuuid
vim .mulle/etc/sourcetree/config
# Add back important comments
```

### Database Reset Required
```bash
# Problem: Sync fails after reuuid
# Solution: Always reset database
mulle-sourcetree reset
mulle-sourcetree sync
```

### Permission Issues
```bash
# Problem: Cannot write config file
# Solution: Check permissions
ls -la $(mulle-sourcetree etc-dir)/config
chmod u+w $(mulle-sourcetree etc-dir)/config
```

### Multiple Projects Conflict
```bash
# Problem: Still getting conflicts
# Solution: Ensure all copies run reuuid
find . -name "config" -exec grep -l "shared-uuid" {} \;
# Run reuuid in each conflicting project
```

## WORKFLOW PATTERNS

### Safe Project Duplication
```bash
#!/bin/bash
# duplicate-project.sh

ORIGINAL="$1"
COPY="$2"

if [ -z "$ORIGINAL" ] || [ -z "$COPY" ]; then
    echo "Usage: $0 <original> <copy>"
    exit 1
fi

# Create copy
cp -r "$ORIGINAL" "$COPY"
cd "$COPY"

# Make unique
mulle-sourcetree reuuid
mulle-sourcetree reset
mulle-sourcetree sync

echo "Project duplicated successfully"
```

### Batch UUID Regeneration
```bash
# Regenerate UUIDs for multiple projects
for project in project1 project2 project3; do
    cd "$project"
    mulle-sourcetree reuuid
    mulle-sourcetree reset
    cd ..
done
```

### Template Preparation
```bash
# Prepare project template
mulle-sourcetree reuuid  # Remove identifying UUIDs
mulle-sourcetree reset   # Clean state
# Template is now ready for distribution
```

## PERFORMANCE CONSIDERATIONS

- **Execution Time**: Proportional to number of nodes
- **Memory Usage**: Minimal (config file size)
- **Disk I/O**: Reads and writes config file
- **Network**: None required

## ENVIRONMENT VARIABLES

- `MULLE_SOURCETREE_CONFIG_NAME` : Configuration file to modify
- `MULLE_SOURCETREE_ETC_DIR` : Directory containing config files

## NOTES

- **Comment Loss**: All '#' comments are permanently removed
- **Database Reset**: Always required after reuuid
- **Fresh Sync**: Required to rebuild database with new UUIDs
- **Data Preservation**: All node data except UUIDs and comments preserved
- **Idempotent Operation**: Safe to run multiple times
- **Local Scope**: Only affects current sourcetree configuration
- **No Options**: Command has no configurable options
- **Atomic Operation**: Either succeeds completely or fails without changes

## SEE ALSO

- [mulle-sourcetree reset](reset.md) - Clear database after UUID changes
- [mulle-sourcetree sync](sync.md) - Rebuild database with new UUIDs
- [mulle-sourcetree list](list.md) - Display nodes with UUID information
- [mulle-sourcetree duplicate](duplicate.md) - Create node duplicates with new UUIDs
- [mulle-sourcetree config](config.md) - Manage configuration files