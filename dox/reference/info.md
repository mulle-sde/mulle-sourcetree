# info

## SYNOPSIS

mulle-sourcetree **info**

## DESCRIPTION

Display comprehensive information about the current sourcetree configuration and runtime environment. This command provides a detailed overview of all sourcetree-related paths, settings, and status information.

The info command is essential for debugging sourcetree setup issues, verifying configuration correctness, and understanding the current runtime environment. Use `--no-defer` to check the current directory specifically without searching parent directories.

## EXAMPLES

### Basic Information Display
```bash
# Show complete sourcetree information
mulle-sourcetree info
```

### Directory-Specific Check
```bash
# Check current directory only (no parent search)
mulle-sourcetree --no-defer info
```

### Script Integration
```bash
# Capture info for processing
INFO_OUTPUT=$(mulle-sourcetree info)

# Extract specific values
PROJECT_DIR=$(echo "$INFO_OUTPUT" | grep "MULLE_SOURCETREE_PROJECT_DIR" | cut -d: -f2 | xargs)
echo "Working in: $PROJECT_DIR"
```

### Conditional Operations
```bash
# Check if in correct mode
if mulle-sourcetree info | grep -q "SOURCETREE_MODE.*share"; then
    echo "In share mode"
else
    echo "Not in share mode"
fi
```

## OUTPUT FORMAT

The command outputs key-value pairs in the format:
```
VARIABLE_NAME : value
```

### Core Path Variables
- `MULLE_SOURCETREE_PROJECT_DIR` : Root directory of the project
- `MULLE_SOURCETREE_ETC_DIR` : Configuration files directory
- `MULLE_SOURCETREE_VAR_DIR` : Runtime data and database directory
- `MULLE_SOURCETREE_STASH_DIR` : Fetched dependencies storage
- `MULLE_SOURCETREE_STASH_DIRNAME` : Name of stash directory (usually "stash")

### Configuration Variables
- `SOURCETREE_CONFIG_NAME` : Active configuration name
- `SOURCETREE_CONFIG_DIR` : Directory containing active config
- `SOURCETREE_START` : Starting point for sourcetree operations
- `SOURCETREE_MODE` : Current mode (share/flat/recurse)

### Database Variables
- `SOURCETREE_DB_FILENAME` : Path to sourcetree database
- `SOURCETREE_FIX_FILENAME` : Path to fix tracking file

### Runtime Variables
- `MULLE_VIRTUAL_ROOT` : Virtual root directory
- `PWD` : Current working directory
- `MULLE_FLAG_DB_LOG_EXEKUTOR` : Database logging flag
- `MULLE_FLAG_WALK_LOG_EXEKUTOR` : Walk operation logging flag

## SAMPLE OUTPUT

```
MULLE_SOURCETREE_PROJECT_DIR   : /home/user/my-project
MULLE_SOURCETREE_ETC_DIR       : /home/user/my-project/.mulle/etc/sourcetree
MULLE_SOURCETREE_STASH_DIRNAME : stash
MULLE_SOURCETREE_STASH_DIR     : /home/user/my-project/stash
MULLE_SOURCETREE_VAR_DIR       : /home/user/my-project/.mulle/var/sourcetree
MULLE_VIRTUAL_ROOT             : /home/user/my-project
PWD                            : /home/user/my-project/src
SOURCETREE_CONFIG_NAME         : config
SOURCETREE_CONFIG_DIR          : /home/user/my-project/.mulle/etc/sourcetree
SOURCETREE_DB_FILENAME         : /home/user/my-project/.mulle/var/sourcetree/db
SOURCETREE_FIX_FILENAME        : /home/user/my-project/.mulle/var/sourcetree/fix
SOURCETREE_MODE                : share
SOURCETREE_START               : /home/user/my-project/.mulle/etc/sourcetree
MULLE_FLAG_DB_LOG_EXEKUTOR     : NO
MULLE_FLAG_WALK_LOG_EXEKUTOR   : NO
```

## INTERPRETING OUTPUT

### Path Verification
```bash
# Check if all expected directories exist
mulle-sourcetree info | while IFS=: read key value; do
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    if [[ "$value" =~ ^/ ]] && [ ! -e "$value" ]; then
        echo "Missing: $key -> $value"
    fi
done
```

### Configuration Analysis
```bash
# Extract configuration details
CONFIG_NAME=$(mulle-sourcetree info | grep "SOURCETREE_CONFIG_NAME" | cut -d: -f2 | xargs)
MODE=$(mulle-sourcetree info | grep "SOURCETREE_MODE" | cut -d: -f2 | xargs)
echo "Using config '$CONFIG_NAME' in $MODE mode"
```

## USE CASES

### Debugging Setup Issues
```bash
# Diagnose path problems
mulle-sourcetree info | grep -E "(DIR|FILE)"

# Check database status
mulle-sourcetree info | grep "DB_FILENAME"
ls -la "$(mulle-sourcetree info | grep "SOURCETREE_DB_FILENAME" | cut -d: -f2 | xargs)"
```

### Environment Validation
```bash
# Verify all required directories exist
REQUIRED_VARS=("MULLE_SOURCETREE_PROJECT_DIR" "MULLE_SOURCETREE_ETC_DIR" "MULLE_SOURCETREE_VAR_DIR")
for var in "${REQUIRED_VARS[@]}"; do
    value=$(mulle-sourcetree info | grep "$var" | cut -d: -f2 | xargs)
    if [ ! -d "$value" ]; then
        echo "ERROR: $var directory missing: $value"
    fi
done
```

### Build System Integration
```bash
# Export paths for build scripts
eval "$(mulle-sourcetree info | sed 's/ : /=/' | sed 's/^/export /')"
echo "Project: $MULLE_SOURCETREE_PROJECT_DIR"
echo "Stash: $MULLE_SOURCETREE_STASH_DIR"
```

### CI/CD Pipeline Debugging
```bash
# Log sourcetree state for debugging
echo "=== Sourcetree Info ==="
mulle-sourcetree info
echo "=== Directory Contents ==="
ls -la "$MULLE_SOURCETREE_ETC_DIR"
ls -la "$MULLE_SOURCETREE_VAR_DIR"
```

## DIFFERENCE FROM --no-defer

### Normal Mode (Default)
```bash
mulle-sourcetree info
```
- Searches up the directory tree for sourcetree configuration
- Shows information for the found sourcetree
- Useful for getting project-wide information

### No-Defer Mode
```bash
mulle-sourcetree --no-defer info
```
- Only checks the current directory
- Doesn't search parent directories
- Useful for checking if current directory has sourcetree setup

## TROUBLESHOOTING

### Common Issues

**No output or errors:**
```bash
# Check if in a sourcetree project
mulle-sourcetree --no-defer info 2>&1 || echo "Not in sourcetree project"

# Verify directories exist
find . -name ".mulle" -type d 2>/dev/null
```

**Missing directories:**
```bash
# Check what directories are missing
mulle-sourcetree info | while IFS=: read key value; do
    value=$(echo "$value" | xargs)
    if [[ "$value" =~ ^/ ]] && [ ! -e "$value" ]; then
        echo "Missing: $value"
        case "$key" in
            *ETC*) echo "  Run: mkdir -p '$value'" ;;
            *VAR*) echo "  Run: mkdir -p '$value'" ;;
            *STASH*) echo "  Run: mkdir -p '$value'" ;;
        esac
    fi
done
```

**Incorrect paths:**
```bash
# Compare with expected structure
echo "Expected: $(pwd)/.mulle/etc/sourcetree"
mulle-sourcetree info | grep "MULLE_SOURCETREE_ETC_DIR"
```

### Validation Scripts

Verify sourcetree health:
```bash
#!/bin/bash
# sourcetree-health-check.sh

echo "=== Sourcetree Health Check ==="

# Get info
INFO=$(mulle-sourcetree info 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: Not in sourcetree project"
    exit 1
fi

# Check directories
echo "$INFO" | grep "_DIR" | while IFS=: read key value; do
    value=$(echo "$value" | xargs)
    if [ ! -d "$value" ]; then
        echo "WARNING: Missing directory $value"
    else
        echo "OK: $key exists"
    fi
done

# Check database
DB_FILE=$(echo "$INFO" | grep "SOURCETREE_DB_FILENAME" | cut -d: -f2 | xargs)
if [ -f "$DB_FILE" ]; then
    echo "OK: Database exists"
else
    echo "WARNING: Database missing (run 'mulle-sourcetree sync')"
fi

echo "=== Health check complete ==="
```

## TECHNICAL DETAILS

### Information Sources
- Environment variables set by sourcetree initialization
- Configuration file parsing
- Directory structure analysis
- Database file detection

### Output Processing
- Variables are displayed in alphabetical order
- Paths are shown as absolute paths
- Boolean flags show YES/NO values
- Missing optional values are omitted

### Performance Impact
- Minimal I/O operations (reads config files only)
- No network operations
- Fast execution (typically < 100ms)
- Safe to run repeatedly

## ENVIRONMENT VARIABLES

The info command displays values for these key variables:
- `MULLE_SOURCETREE_*` : Core sourcetree paths and settings
- `SOURCETREE_*` : Internal sourcetree state
- `MULLE_VIRTUAL_ROOT` : Virtual root directory
- `MULLE_FLAG_*` : Debug and logging flags

## NOTES

- All output is to stdout (can be redirected)
- No options or arguments accepted
- Safe to run in any directory
- Useful for debugging and documentation
- Output format is consistent and parseable
- Shows both user-set and computed values

## SEE ALSO

- [mulle-sourcetree status](status.md) - Show synchronization status
- [mulle-sourcetree list](list.md) - List sourcetree nodes
- [mulle-sourcetree config](config.md) - Manage configurations
- [mulle-sourcetree --no-defer`](list.md) - Local directory operations