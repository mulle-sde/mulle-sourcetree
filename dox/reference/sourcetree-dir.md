# mulle-sourcetree sourcetree-dir

Display the sourcetree configuration directory path.

## Synopsis

```bash
mulle-sourcetree sourcetree-dir [options]
```

## Description

The `sourcetree-dir` command displays the path to the sourcetree configuration directory where mulle-sourcetree stores its configuration files, database, and state information. This directory contains all the metadata and settings that define the sourcetree structure.

## Options

- `--absolute` : Display absolute path (default)
- `--relative` : Display path relative to current directory
- `--create` : Create the directory if it doesn't exist
- `--list` : List contents of the sourcetree directory
- `--validate` : Validate configuration files
- `--quiet` : Suppress output

## Examples

### Basic Usage
```bash
# Display sourcetree directory path
mulle-sourcetree sourcetree-dir

# Display relative path
mulle-sourcetree sourcetree-dir --relative

# Create directory if needed
mulle-sourcetree sourcetree-dir --create
```

### Directory Operations
```bash
# List contents
mulle-sourcetree sourcetree-dir --list

# List with details
mulle-sourcetree sourcetree-dir --list --verbose

# Validate configuration
mulle-sourcetree sourcetree-dir --validate
```

### Integration with Scripts
```bash
# Use in shell scripts
SOURCETREE_DIR="$(mulle-sourcetree sourcetree-dir)"
echo "Sourcetree config in: $SOURCETREE_DIR"

# Access configuration files
CONFIG_FILE="$SOURCETREE_DIR/config"
if [ -f "$CONFIG_FILE" ]; then
  echo "Configuration found"
fi

# Backup sourcetree configuration
cp -r "$SOURCETREE_DIR" ~/sourcetree-backup/
```

## Directory Structure

### Typical Contents
The sourcetree directory typically contains:

- **config/**: Main configuration files
- **db/**: Database files and state
- **cache/**: Cached information and metadata
- **logs/**: Operation logs and history
- **tmp/**: Temporary files during operations

### File Types
- **.config**: Configuration files
- **.db**: Database files
- **.cache**: Cached data
- **.log**: Log files
- **.tmp**: Temporary files

## Use Cases

### Configuration Management
```bash
# Edit main configuration
$EDITOR "$(mulle-sourcetree sourcetree-dir)/config/main"

# View configuration files
ls -la "$(mulle-sourcetree sourcetree-dir)/config/"

# Backup configuration
cp -r "$(mulle-sourcetree sourcetree-dir)/config" ~/config-backup/

# Restore configuration
cp ~/config-backup/* "$(mulle-sourcetree sourcetree-dir)/config/"
```

### Database Operations
```bash
# Access database files
DB_DIR="$(mulle-sourcetree sourcetree-dir)/db"
ls "$DB_DIR"

# Backup database
cp "$DB_DIR/sourcetree.db" ~/sourcetree-backup.db

# Check database integrity
mulle-sourcetree sourcetree-dir --validate-db
```

### Cache Management
```bash
# Clear cache
rm -rf "$(mulle-sourcetree sourcetree-dir)/cache/"*

# View cache contents
ls -la "$(mulle-sourcetree sourcetree-dir)/cache/"

# Check cache size
du -sh "$(mulle-sourcetree sourcetree-dir)/cache"
```

## Platform-Specific Locations

### Unix-like Systems
```bash
# Project-specific location
./.mulle-sourcetree/

# User-specific location (if configured)
~/.config/mulle-sourcetree/

# System-wide location (rare)
#/etc/mulle-sourcetree/
```

### Windows
```bash
# Project-specific location
.\.mulle-sourcetree\

# User-specific location
%APPDATA%\mulle-sourcetree\

# System-wide location
C:\ProgramData\mulle-sourcetree\
```

### macOS
```bash
# Project-specific location
./.mulle-sourcetree/

# User-specific location
~/Library/Application Support/mulle-sourcetree/

# System-wide location
/Library/Application Support/mulle-sourcetree/
```

## Directory Priority

### Search Order
mulle-sourcetree searches for configuration in this order:

1. **Project-specific**: `./.mulle-sourcetree/` (highest priority)
2. **User-specific**: `~/<config-dir>/mulle-sourcetree/`
3. **System-wide**: `/<system-dir>/mulle-sourcetree/` (lowest priority)

### Override Behavior
- Project-specific settings override user settings
- User settings override system defaults
- Missing files fall back to built-in defaults

## Security Considerations

### Permission Management
```bash
# Check directory permissions
ls -la "$(mulle-sourcetree sourcetree-dir)"

# Set secure permissions
chmod 755 "$(mulle-sourcetree sourcetree-dir)"
chmod 644 "$(mulle-sourcetree sourcetree-dir)/config/"*

# Verify ownership
stat "$(mulle-sourcetree sourcetree-dir)"
```

### File Validation
```bash
# Validate configuration files
mulle-sourcetree sourcetree-dir --validate

# Check for security issues
mulle-sourcetree sourcetree-dir --security-scan

# Verify file integrity
mulle-sourcetree sourcetree-dir --verify-integrity
```

### Access Control
```bash
# Check read access
mulle-sourcetree sourcetree-dir --readable

# Check write access
mulle-sourcetree sourcetree-dir --writable

# Verify configuration access
mulle-sourcetree sourcetree-dir --check-config-access
```

## Integration with Other Commands

### With config
```bash
# Edit configuration
$EDITOR "$(mulle-sourcetree sourcetree-dir)/config/main"

# Show configuration status
mulle-sourcetree config status

# Reload configuration
mulle-sourcetree config reload

# Backup configuration
mulle-sourcetree config backup
```

### With status
```bash
# Show sourcetree status
mulle-sourcetree status --sourcetree-dir

# Check directory health
mulle-sourcetree status --sourcetree-health

# Show directory usage
mulle-sourcetree status --sourcetree-usage
```

### With list
```bash
# List configuration files
mulle-sourcetree list --config-dir "$(mulle-sourcetree sourcetree-dir)"

# List database contents
mulle-sourcetree list --db-dir "$(mulle-sourcetree sourcetree-dir)/db"

# List cached items
mulle-sourcetree list --cache-dir "$(mulle-sourcetree sourcetree-dir)/cache"
```

## Advanced Features

### Directory Mirroring
```bash
# Mirror sourcetree directory
mulle-sourcetree sourcetree-dir --mirror /path/to/backup

# Sync with remote location
mulle-sourcetree sourcetree-dir --sync-remote user@host:/remote/sourcetree

# Create symbolic links
mulle-sourcetree sourcetree-dir --link /custom/sourcetree/location
```

### Version Control
```bash
# Initialize git repository
cd "$(mulle-sourcetree sourcetree-dir)" && git init

# Track configuration changes
git add config/
git commit -m "Configuration update"

# Show change history
git log --oneline
```

### Backup and Restore
```bash
# Create sourcetree backup
mulle-sourcetree sourcetree-dir --backup /path/to/backup

# Restore from backup
mulle-sourcetree sourcetree-dir --restore /path/to/backup

# Incremental backup
mulle-sourcetree sourcetree-dir --incremental-backup
```

### Monitoring
```bash
# Monitor directory changes
mulle-sourcetree sourcetree-dir --monitor

# Log directory operations
mulle-sourcetree sourcetree-dir --log-operations

# Alert on configuration changes
mulle-sourcetree sourcetree-dir --alert-changes
```

## Troubleshooting

### Common Issues
```bash
# Directory not found
mulle-sourcetree sourcetree-dir --create

# Permission denied
sudo mulle-sourcetree sourcetree-dir --create

# Corrupted configuration
mulle-sourcetree sourcetree-dir --repair
```

### Path Issues
```bash
# Wrong path detected
mulle-sourcetree sourcetree-dir --debug-path

# Path doesn't exist
mulle-sourcetree sourcetree-dir --create --parents

# Multiple installations conflict
mulle-sourcetree sourcetree-dir --resolve-conflicts
```

### Configuration Issues
```bash
# Invalid configuration
mulle-sourcetree sourcetree-dir --validate-config

# Missing configuration files
mulle-sourcetree sourcetree-dir --create-config

# Configuration conflicts
mulle-sourcetree sourcetree-dir --resolve-config-conflicts
```

## Integration with Development Workflow

### Configuration Management
```bash
# Edit sourcetree configuration
$EDITOR "$(mulle-sourcetree sourcetree-dir)/config/sourcetree.config"

# View current configuration
cat "$(mulle-sourcetree sourcetree-dir)/config/sourcetree.config"

# Validate configuration
mulle-sourcetree sourcetree-dir --validate
```

### Database Operations
```bash
# Access sourcetree database
DB_FILE="$(mulle-sourcetree sourcetree-dir)/db/sourcetree.db"

# Backup database
cp "$DB_FILE" ~/sourcetree-db-backup.db

# Check database status
mulle-sourcetree dbstatus
```

### Cache Operations
```bash
# Clear sourcetree cache
rm -rf "$(mulle-sourcetree sourcetree-dir)/cache/"*

# View cache statistics
ls -la "$(mulle-sourcetree sourcetree-dir)/cache/"

# Optimize cache
mulle-sourcetree sourcetree-dir --optimize-cache
```

## Performance Considerations

- Configuration files are cached for performance
- Database operations are optimized for speed
- Cache files reduce repeated computations
- Use `--quiet` for scripts to reduce output

## Notes

- Sourcetree directory is automatically created when needed
- Configuration files are loaded in priority order
- Database files contain critical state information
- Cache files can be safely deleted if needed

## See Also

- [`config`](config.md) - Manage configuration
- [`status`](status.md) - Show system status
- [`list`](list.md) - List directory contents
- [`project-dir`](project-dir.md) - Show project directory