# mulle-sourcetree libexec-dir

Display the libexec directory path used by mulle-sourcetree.

## Synopsis

```bash
mulle-sourcetree libexec-dir [options]
```

## Description

The `libexec-dir` command displays the path to the libexec directory used by mulle-sourcetree for executable programs and scripts that are not intended to be run directly by users. This directory contains internal utilities, helper programs, and system executables.

## Options

- `--absolute` : Display absolute path (default)
- `--relative` : Display path relative to current directory
- `--create` : Create the directory if it doesn't exist
- `--list` : List contents of the libexec directory
- `--validate` : Validate executable files
- `--quiet` : Suppress output

## Examples

### Basic Usage
```bash
# Display libexec directory path
mulle-sourcetree libexec-dir

# Display relative path
mulle-sourcetree libexec-dir --relative

# Create directory if needed
mulle-sourcetree libexec-dir --create
```

### Directory Operations
```bash
# List contents
mulle-sourcetree libexec-dir --list

# List with details
mulle-sourcetree libexec-dir --list --verbose

# Validate executables
mulle-sourcetree libexec-dir --validate
```

### Integration with Scripts
```bash
# Use in shell scripts
LIBEXEC_DIR="$(mulle-sourcetree libexec-dir)"
echo "Internal executables in: $LIBEXEC_DIR"

# Access internal tools
HELPER_SCRIPT="$LIBEXEC_DIR/mulle-sourcetree-helper.sh"
if [ -x "$HELPER_SCRIPT" ]; then
  bash "$HELPER_SCRIPT" --assist
fi

# Run internal utilities
"$LIBEXEC_DIR/mulle-sourcetree-utility" --process-data
```

## Directory Structure

### Typical Contents
The libexec directory typically contains:

- **mulle-sourcetree-***: Internal utility programs
- **plugins/**: Plugin executables and helpers
- **tools/**: Development and build tools
- **scripts/**: System administration scripts
- **helpers/**: Support programs and utilities

### File Types
- **Executables**: Binary programs and utilities
- **Scripts**: Shell and interpreted scripts
- **Libraries**: Shared libraries for internal use
- **Configuration**: Internal configuration files

## Use Cases

### Internal Tool Access
```bash
# Access internal build tools
BUILD_TOOL="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-build"
"$BUILD_TOOL" --internal-build

# Use internal test runners
TEST_RUNNER="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-test-runner"
"$TEST_RUNNER" --run-suite internal

# Execute system utilities
SYS_UTIL="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-sys-util"
"$SYS_UTIL" --system-check
```

### Plugin Management
```bash
# Access plugin executables
PLUGIN_DIR="$(mulle-sourcetree libexec-dir)/plugins"
ls "$PLUGIN_DIR"

# Run plugin helpers
PLUGIN_HELPER="$PLUGIN_DIR/mulle-sourcetree-plugin-helper"
"$PLUGIN_HELPER" --load-plugin myplugin

# Execute plugin tools
"$PLUGIN_DIR/myplugin-executable" --plugin-option value
```

### Development Tools
```bash
# Use internal development tools
DEV_TOOL="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-dev-tool"
"$DEV_TOOL" --analyze-code

# Access build helpers
BUILD_HELPER="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-build-helper"
"$BUILD_HELPER" --prepare-build

# Run code generators
CODE_GEN="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-code-gen"
"$CODE_GEN" --generate-stubs
```

## Platform-Specific Locations

### Unix-like Systems
```bash
# System-wide location
/usr/local/libexec/mulle-sourcetree/

# User-specific location
~/.local/libexec/mulle-sourcetree/

# Project-specific location
./.mulle-sourcetree/libexec/
```

### Windows
```bash
# System-wide location
C:\Program Files\mulle-sourcetree\libexec\

# User-specific location
%LOCALAPPDATA%\mulle-sourcetree\libexec\

# Project-specific location
.\.mulle-sourcetree\libexec\
```

### macOS
```bash
# System-wide location
/Library/Application Support/mulle-sourcetree/libexec/

# User-specific location
~/Library/Application Support/mulle-sourcetree/libexec/

# Project-specific location
./.mulle-sourcetree/libexec/
```

## Directory Priority

### Search Order
mulle-sourcetree searches for libexec files in this order:

1. **Project-specific**: `./.mulle-sourcetree/libexec/`
2. **User-specific**: `~/<local-dir>/mulle-sourcetree/libexec/`
3. **System-wide**: `/<system-dir>/mulle-sourcetree/libexec/`

### Override Behavior
- Project-specific executables take precedence
- User executables override system defaults
- Missing executables fall back to built-in implementations

## Security Considerations

### Permission Management
```bash
# Check executable permissions
ls -la "$(mulle-sourcetree libexec-dir)"

# Set secure permissions
chmod 755 "$(mulle-sourcetree libexec-dir)"
chmod 755 "$(mulle-sourcetree libexec-dir)/"*

# Verify ownership
stat "$(mulle-sourcetree libexec-dir)"
```

### File Validation
```bash
# Validate executable files
mulle-sourcetree libexec-dir --validate

# Check for security issues
mulle-sourcetree libexec-dir --security-scan

# Verify file integrity
mulle-sourcetree libexec-dir --verify-integrity
```

### Access Control
```bash
# Check execution permissions
mulle-sourcetree libexec-dir --check-executable

# Verify file signatures (if available)
mulle-sourcetree libexec-dir --verify-signatures

# Audit executable access
mulle-sourcetree libexec-dir --audit-access
```

## Integration with Other Commands

### With plugin
```bash
# Install plugin executables
cp my-plugin-exec "$(mulle-sourcetree libexec-dir)/plugins/"

# List plugin executables
mulle-sourcetree libexec-dir --list plugins/

# Run plugin from libexec
mulle-sourcetree plugin run "$(mulle-sourcetree libexec-dir)/plugins/my-plugin"
```

### With tool
```bash
# Access tool executables
TOOL_EXEC="$(mulle-sourcetree libexec-dir)/tools/mulle-sourcetree-tool"
"$TOOL_EXEC" --tool-option

# List available tools
mulle-sourcetree libexec-dir --list tools/

# Configure tool paths
mulle-sourcetree tool set mytool "$(mulle-sourcetree libexec-dir)/tools/mytool"
```

### With test
```bash
# Access test executables
TEST_EXEC="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-test-exec"
"$TEST_EXEC" --run-tests

# Use test helpers
TEST_HELPER="$(mulle-sourcetree libexec-dir)/helpers/test-helper"
"$TEST_HELPER" --setup-test-env

# Run internal test suites
INTERNAL_TEST="$(mulle-sourcetree libexec-dir)/tests/internal-test-suite"
"$INTERNAL_TEST" --comprehensive
```

## Advanced Features

### Executable Management
```bash
# Install new executable
mulle-sourcetree libexec-dir --install-executable /path/to/executable

# Remove executable
mulle-sourcetree libexec-dir --remove-executable executable-name

# Update executables
mulle-sourcetree libexec-dir --update-executables

# Backup executables
mulle-sourcetree libexec-dir --backup-executables
```

### Script Management
```bash
# Install script
mulle-sourcetree libexec-dir --install-script /path/to/script.sh

# List installed scripts
mulle-sourcetree libexec-dir --list-scripts

# Validate scripts
mulle-sourcetree libexec-dir --validate-scripts

# Execute script
mulle-sourcetree libexec-dir --run-script script-name
```

### Library Management
```bash
# Install shared libraries
mulle-sourcetree libexec-dir --install-library /path/to/library.so

# List installed libraries
mulle-sourcetree libexec-dir --list-libraries

# Update library dependencies
mulle-sourcetree libexec-dir --update-libraries

# Check library compatibility
mulle-sourcetree libexec-dir --check-library-compat
```

## Troubleshooting

### Common Issues
```bash
# Executable not found
mulle-sourcetree libexec-dir --find-executable executable-name

# Permission denied
mulle-sourcetree libexec-dir --fix-permissions

# Corrupted executable
mulle-sourcetree libexec-dir --repair-executable executable-name
```

### Path Issues
```bash
# Wrong path detected
mulle-sourcetree libexec-dir --debug-path

# Path doesn't exist
mulle-sourcetree libexec-dir --create --parents

# Multiple installations conflict
mulle-sourcetree libexec-dir --resolve-conflicts
```

### Execution Issues
```bash
# Executable fails to run
mulle-sourcetree libexec-dir --debug-executable executable-name

# Missing dependencies
mulle-sourcetree libexec-dir --check-dependencies executable-name

# Incompatible architecture
mulle-sourcetree libexec-dir --check-architecture executable-name
```

## Integration with Build System

### Build Tools
```bash
# Use internal build tools
BUILD_TOOL="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-builder"
"$BUILD_TOOL" --build-project

# Access compiler wrappers
CC_WRAPPER="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-cc-wrapper"
"$CC_WRAPPER" --wrap-gcc gcc

# Run build helpers
BUILD_HELPER="$(mulle-sourcetree libexec-dir)/helpers/build-helper"
"$BUILD_HELPER" --prepare-environment
```

### Development Tools
```bash
# Use code analysis tools
ANALYZER="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-analyzer"
"$ANALYZER" --analyze-project

# Access debuggers
DEBUGGER="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-debugger"
"$DEBUGGER" --debug-program

# Run profilers
PROFILER="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-profiler"
"$PROFILER" --profile-application
```

### Test Tools
```bash
# Use test frameworks
TEST_FRAMEWORK="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-test-framework"
"$TEST_FRAMEWORK" --run-tests

# Access test utilities
TEST_UTIL="$(mulle-sourcetree libexec-dir)/utils/test-util"
"$TEST_UTIL" --generate-test-data

# Run coverage tools
COVERAGE_TOOL="$(mulle-sourcetree libexec-dir)/mulle-sourcetree-coverage"
"$COVERAGE_TOOL" --measure-coverage
```

## Notes

- Libexec directory contains internal executables
- Files are typically not user-executable directly
- Directory is automatically created when needed
- Some executables may require specific permissions

## See Also

- [`etc-dir`](etc-dir.md) - Show etc directory
- [`share-dir`](share-dir.md) - Show share directory
- [`plugin`](plugin.md) - Manage plugins
- [`tool`](tool.md) - Manage tools