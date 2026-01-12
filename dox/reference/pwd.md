# mulle-sourcetree pwd

Display the current working directory in the context of mulle-sourcetree.

## Synopsis

```bash
mulle-sourcetree pwd [options]
```

## Description

The `pwd` command displays the current working directory, similar to the Unix `pwd` command, but provides additional mulle-sourcetree specific information and formatting options. It shows the absolute path and can provide context about the current project and sourcetree state.

## Options

- `--absolute` : Display absolute path (default)
- `--relative` : Display path relative to project root
- `--canonical` : Display canonical (resolved) path
- `--project` : Show project root directory
- `--sourcetree` : Show sourcetree configuration directory
- `--quiet` : Suppress output

## Examples

### Basic Usage
```bash
# Display current working directory
mulle-sourcetree pwd

# Display relative to project root
mulle-sourcetree pwd --relative

# Display canonical path
mulle-sourcetree pwd --canonical
```

### Project Context
```bash
# Show project root
mulle-sourcetree pwd --project

# Show sourcetree config directory
mulle-sourcetree pwd --sourcetree

# Show both current and project directories
mulle-sourcetree pwd --verbose
```

### Integration with Scripts
```bash
# Use in shell scripts
CURRENT_DIR="$(mulle-sourcetree pwd)"
echo "Current directory: $CURRENT_DIR"

# Check if in project
if [ "$(mulle-sourcetree pwd --project)" != "$(mulle-sourcetree pwd)" ]; then
  echo "Not in project root"
fi

# Get relative path for logging
REL_PATH="$(mulle-sourcetree pwd --relative)"
echo "Relative location: $REL_PATH"
```

## Path Resolution

### Absolute vs Relative Paths
```bash
# Always get absolute path
ABS_PATH="$(mulle-sourcetree pwd --absolute)"

# Get path relative to project root
REL_PATH="$(mulle-sourcetree pwd --relative)"

# Get canonical path (resolve symlinks)
CANONICAL_PATH="$(mulle-sourcetree pwd --canonical)"
```

### Project Context
```bash
# Get project root directory
PROJECT_ROOT="$(mulle-sourcetree pwd --project)"

# Get sourcetree configuration directory
SOURCETREE_DIR="$(mulle-sourcetree pwd --sourcetree)"

# Calculate relative path from project root
CURRENT="$(mulle-sourcetree pwd)"
PROJECT="$(mulle-sourcetree pwd --project)"
REL_PATH="${CURRENT#$PROJECT/}"
```

## Use Cases

### Build Scripts
```bash
# Ensure we're in the right directory
if [ "$(mulle-sourcetree pwd)" != "$(mulle-sourcetree pwd --project)" ]; then
  echo "Must run from project root"
  exit 1
fi

# Log current location
echo "Building in: $(mulle-sourcetree pwd --relative)"

# Create output relative to current location
mkdir -p "$(mulle-sourcetree pwd)/build"
```

### Development Workflow
```bash
# Show current context
mulle-sourcetree pwd --verbose

# Navigate to project root
cd "$(mulle-sourcetree pwd --project)"

# Check if in sourcetree directory
if [[ "$(mulle-sourcetree pwd)" == *"sourcetree"* ]]; then
  echo "In sourcetree directory"
fi
```

### CI/CD Integration
```bash
# Set working directory info
export BUILD_DIR="$(mulle-sourcetree pwd)"
export PROJECT_DIR="$(mulle-sourcetree pwd --project)"

# Log build location
echo "Building in: $BUILD_DIR"
echo "Project root: $PROJECT_DIR"

# Verify correct working directory
if [ "$BUILD_DIR" != "$PROJECT_DIR" ]; then
  echo "Warning: Not building from project root"
fi
```

## Path Information

### Directory Components
```bash
# Get directory name
DIR_NAME="$(basename "$(mulle-sourcetree pwd)")"

# Get parent directory
PARENT_DIR="$(dirname "$(mulle-sourcetree pwd)")"

# Get full path components
IFS='/' read -ra PATH_COMPONENTS <<< "$(mulle-sourcetree pwd)"
```

### Path Validation
```bash
# Check if directory exists
mulle-sourcetree pwd --exists

# Check if writable
mulle-sourcetree pwd --writable

# Check if in project
mulle-sourcetree pwd --in-project
```

## Integration with Other Commands

### With status
```bash
# Show directory status
mulle-sourcetree status --directory "$(mulle-sourcetree pwd)"

# Check project status from current location
mulle-sourcetree status --from "$(mulle-sourcetree pwd --relative)"

# Show sourcetree status
mulle-sourcetree status --sourcetree-dir "$(mulle-sourcetree pwd --sourcetree)"
```

### With list
```bash
# List files in current directory
mulle-sourcetree list --directory "$(mulle-sourcetree pwd)"

# List relative to project
mulle-sourcetree list --relative-to "$(mulle-sourcetree pwd --project)"

# List sourcetree files
mulle-sourcetree list --config-dir "$(mulle-sourcetree pwd --sourcetree)"
```

### With config
```bash
# Show config for current directory
mulle-sourcetree config list --directory "$(mulle-sourcetree pwd)"

# Set directory-specific config
mulle-sourcetree config set --directory "$(mulle-sourcetree pwd)" key value

# Show project config
mulle-sourcetree config list --project-dir "$(mulle-sourcetree pwd --project)"
```

## Advanced Features

### Path Manipulation
```bash
# Convert to different formats
mulle-sourcetree pwd --format windows    # Windows path format
mulle-sourcetree pwd --format unix       # Unix path format
mulle-sourcetree pwd --format url        # URL format

# Resolve symlinks
mulle-sourcetree pwd --resolve-links

# Show path components
mulle-sourcetree pwd --components
```

### Context Information
```bash
# Show git information
mulle-sourcetree pwd --git-info

# Show project information
mulle-sourcetree pwd --project-info

# Show system information
mulle-sourcetree pwd --system-info
```

### Scripting Support
```bash
# Export path variables
eval "$(mulle-sourcetree pwd --export)"

# Source directory-specific scripts
source "$(mulle-sourcetree pwd)/.mulle-sourcetree/local.sh"

# Execute directory-specific commands
mulle-sourcetree pwd --exec "make clean"
```

## Troubleshooting

### Common Issues
```bash
# Path not found
mulle-sourcetree pwd --debug

# Wrong project detected
mulle-sourcetree pwd --reset-project

# Symlink resolution issues
mulle-sourcetree pwd --no-resolve-links
```

### Path Resolution
```bash
# Debug path resolution
mulle-sourcetree pwd --debug-path

# Show search paths
mulle-sourcetree pwd --search-paths

# Test path accessibility
mulle-sourcetree pwd --test-access
```

### Project Detection
```bash
# Force project redetection
mulle-sourcetree pwd --redetect-project

# Show project detection log
mulle-sourcetree pwd --project-log

# Override project detection
mulle-sourcetree pwd --project-override /path/to/project
```

## Integration with Development Tools

### Editor Integration
```bash
# Open current directory in editor
code "$(mulle-sourcetree pwd)"

# Open project root in editor
code "$(mulle-sourcetree pwd --project)"

# Configure editor workspace
echo "$(mulle-sourcetree pwd --project)" > .vscode/workspace.txt
```

### Version Control
```bash
# Show git status for current directory
cd "$(mulle-sourcetree pwd)" && git status

# Show git status for project
cd "$(mulle-sourcetree pwd --project)" && git status

# Check if directory is git repository
if git -C "$(mulle-sourcetree pwd)" rev-parse --git-dir > /dev/null 2>&1; then
  echo "In git repository"
fi
```

### Build Tools
```bash
# Run make from project root
cd "$(mulle-sourcetree pwd --project)" && make

# Run cmake from current directory
cd "$(mulle-sourcetree pwd)" && cmake .

# Run tests from appropriate directory
cd "$(mulle-sourcetree pwd --project)" && make test
```

## Performance Considerations

- Path resolution is cached for performance
- Use `--quiet` for scripts to reduce output
- Avoid frequent calls in tight loops
- Consider using environment variables for repeated access

## Security Considerations

### Path Validation
```bash
# Validate current path
mulle-sourcetree pwd --validate

# Check path permissions
mulle-sourcetree pwd --check-permissions

# Verify path safety
mulle-sourcetree pwd --safe-path
```

### Access Control
```bash
# Check read access
mulle-sourcetree pwd --readable

# Check write access
mulle-sourcetree pwd --writable

# Check execute access
mulle-sourcetree pwd --executable
```

## Notes

- Command respects current working directory
- Automatically detects project boundaries
- Path resolution follows platform conventions
- Output is designed to be script-friendly

## See Also

- [`project-dir`](project-dir.md) - Show project directory
- [`status`](status.md) - Show project status
- [`list`](list.md) - List directory contents
- [`config`](config.md) - Manage configuration