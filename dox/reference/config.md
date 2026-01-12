# config

## SYNOPSIS

mulle-sourcetree **config** <command> [options]

## DESCRIPTION

Manage sourcetree configuration files and switch between different configurations. This command provides tools to list, copy, remove, and check the status of sourcetree configurations.

Configurations allow you to maintain different sets of dependencies for different purposes (development, production, different platforms, etc.). The active configuration is determined by the `MULLE_SOURCETREE_CONFIG_NAME` environment variable or the `--config-name` flag.

## COMMANDS

### list
List available sourcetree configuration files in both user and shared directories.

**Options:**
- `-n`, `--name-only` : Output only configuration names (not full paths)
- `-s <sep>`, `--separator <sep>` : Separator for names (default: space)
- `--no-warn` : Suppress warnings when no sourcetree exists
- `--fail-silently-if-missing` : Don't show errors for missing configurations

**Examples:**
```bash
# List all configurations with full paths
mulle-sourcetree config list

# Get just the names for scripting
mulle-sourcetree config list --name-only

# Comma-separated list for processing
mulle-sourcetree config list --name-only --separator ','

# Silent operation
mulle-sourcetree config list --no-warn
```

### copy
Duplicate the current (or specified) configuration to a new name.

**Options:**
- `-h`, `--help` : Display help information

**Examples:**
```bash
# Backup current configuration
mulle-sourcetree config copy backup

# Create experimental branch
mulle-sourcetree config copy experimental

# Copy specific configuration
mulle-sourcetree --config-name production config copy production-v2
```

### remove
Delete a configuration file. If the configuration exists in the shared directory, it creates an empty file in the user directory to hide it.

**Options:**
- `-h`, `--help` : Display help information

**Examples:**
```bash
# Remove current configuration
mulle-sourcetree config remove

# Remove specific configuration
mulle-sourcetree config remove experimental

# Remove backup (safe operation)
mulle-sourcetree config remove backup
```

### status
Check if any sourcetree configuration exists. Returns exit code 0 if found, 1 if not found.

**Return Values:**
- `0` : Configuration exists
- `1` : No configuration found

**Examples:**
```bash
# Check configuration status
mulle-sourcetree config status && echo "Config exists" || echo "No config"

# Use in scripts
if mulle-sourcetree config status >/dev/null 2>&1; then
    echo "Sourcetree is configured"
else
    echo "No sourcetree configuration found"
fi
```

## CONFIGURATION HIERARCHY

### Search Order
Configurations are searched in this priority order:
1. `${MULLE_SOURCETREE_ETC_DIR}/<name>` (user-specific)
2. `${MULLE_SOURCETREE_ETC_DIR}/<name>.<platform>` (platform-specific)
3. `${MULLE_SOURCETREE_SHARE_DIR}/<name>` (shared)
4. `${MULLE_SOURCETREE_SHARE_DIR}/<name>.<platform>` (shared platform-specific)

### Directory Structure
```
project/
├── .mulle/
│   └── etc/
│       └── sourcetree/
│           ├── config           # Default user config
│           ├── config.darwin    # macOS-specific
│           ├── config.linux     # Linux-specific
│           └── experimental     # Custom config
└── mulle/share/
    └── sourcetree/
        └── config               # Shared config
```

## ENVIRONMENT VARIABLES

### Core Variables
- `MULLE_SOURCETREE_CONFIG_NAME` : Active configuration name (default: "config")
- `MULLE_SOURCETREE_ETC_DIR` : User configuration directory
- `MULLE_SOURCETREE_SHARE_DIR` : Shared configuration directory

### Project-Specific
- `MULLE_SOURCETREE_CONFIG_NAME_<PROJECT>` : Project-specific configuration
- `MULLE_SOURCETREE_CONFIG_DIR` : Base configuration directory

## USE CASES

### Multi-Platform Development
```bash
# Create platform-specific configurations
mulle-sourcetree config copy config.darwin
mulle-sourcetree config copy config.linux

# Platform automatically selected based on MULLE_UNAME
mulle-sourcetree sync  # Uses config.darwin on macOS
```

### Feature Branch Dependencies
```bash
# Create feature-specific dependency set
mulle-sourcetree config copy feature-x
mulle-sourcetree --config-name feature-x add --url https://github.com/user/feature.git src/feature

# Switch between branches
MULLE_SOURCETREE_CONFIG_NAME=feature-x mulle-sourcetree sync
MULLE_SOURCETREE_CONFIG_NAME=config mulle-sourcetree sync
```

### Build Variants
```bash
# Development with debug libraries
mulle-sourcetree config copy development
mulle-sourcetree --config-name development mark src/mylib build

# Production with minimal dependencies
mulle-sourcetree config copy production
mulle-sourcetree --config-name production mark src/mylib no-build
```

### CI/CD Pipelines
```bash
# Different configs for different stages
mulle-sourcetree config copy ci
mulle-sourcetree config copy release

# Use appropriate config in pipeline
if [ "$CI_STAGE" = "test" ]; then
    export MULLE_SOURCETREE_CONFIG_NAME=ci
else
    export MULLE_SOURCETREE_CONFIG_NAME=release
fi
mulle-sourcetree sync
```

### Backup and Recovery
```bash
# Automated backup
BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
mulle-sourcetree config copy "$BACKUP_NAME"

# List available backups
mulle-sourcetree config list --name-only | grep '^backup-'

# Restore from backup
mulle-sourcetree --config-name "$BACKUP_NAME" config copy config
```

## TROUBLESHOOTING

### Common Issues

**"Configuration already exists" error:**
```bash
# Use a different name
mulle-sourcetree config copy config-v2

# Or remove the existing one first
mulle-sourcetree config remove conflicting-name
```

**Configuration not found:**
```bash
# Check available configurations
mulle-sourcetree config list

# Verify environment variable
echo "Config name: $MULLE_SOURCETREE_CONFIG_NAME"

# Check if directories exist
ls -la $(mulle-sourcetree etc-dir)
```

**Permission issues:**
```bash
# Check directory permissions
ls -ld $(mulle-sourcetree etc-dir)

# Ensure write permissions
chmod u+w $(mulle-sourcetree etc-dir)
```

### Validation

Verify configuration integrity:
```bash
# Check if config file exists and is readable
CONFIG_FILE="$(mulle-sourcetree etc-dir)/config"
[ -f "$CONFIG_FILE" ] && [ -r "$CONFIG_FILE" ] && echo "Config OK"

# Validate configuration syntax
mulle-sourcetree list >/dev/null 2>&1 && echo "Config valid"
```

## TECHNICAL DETAILS

### Configuration File Format
Configurations are plain text files with one node per line:
```
address nodetype url marks...
```

### Platform Detection
- Uses `MULLE_UNAME` environment variable
- Supports: `darwin`, `linux`, `mingw`, `freebsd`, `windows`
- Automatic fallback to base configuration

### Inheritance Rules
- User configs override shared configs
- Platform-specific configs override generic configs
- Empty files in user directory hide shared configs

### Atomic Operations
- Copy operations are atomic (use temporary files)
- Failed operations don't leave partial state
- Rollback on error conditions

## NOTES

- Configuration names must be valid filenames
- Shared configurations cannot be truly deleted (only hidden)
- Platform-specific configs are automatically selected
- Use `--config-name` for explicit configuration selection
- Environment variables override command-line flags
- Configurations are project-specific (not global)

## SEE ALSO

- [mulle-sourcetree list](list.md) - List nodes in current configuration
- [mulle-sourcetree sync](sync.md) - Apply configuration to filesystem
- [mulle-sourcetree add](add.md) - Add nodes to configuration
- [mulle-sourcetree info](info.md) - Show configuration information
- [mulle-sourcetree --config-name`](list.md) - Use specific configuration