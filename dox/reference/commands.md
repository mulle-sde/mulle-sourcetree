# mulle-sourcetree commands

List all available commands in mulle-sourcetree.

## Synopsis

```bash
mulle-sourcetree commands [options]
```

## Description

The `commands` command displays a comprehensive list of all available commands in mulle-sourcetree, organized by category. This provides an overview of the complete command set and helps users discover available functionality.

## Options

- `--all` : List all commands (default)
- `--core` : List only core operations commands
- `--node` : List only node management commands
- `--config` : List only configuration commands
- `--system` : List only system operations commands
- `--utility` : List only utility commands
- `--help` : Show help for each command
- `--quiet` : Suppress output

## Examples

### Basic Usage
```bash
# List all commands
mulle-sourcetree commands

# List commands by category
mulle-sourcetree commands --core
mulle-sourcetree commands --node
mulle-sourcetree commands --config
```

### Detailed Information
```bash
# Show help for all commands
mulle-sourcetree commands --help

# List with descriptions
mulle-sourcetree commands --verbose

# Show command categories
mulle-sourcetree commands --categories
```

### Integration with Scripts
```bash
# Use in shell scripts
ALL_COMMANDS="$(mulle-sourcetree commands --all)"
echo "Available commands: $ALL_COMMANDS"

# Count commands
COMMAND_COUNT="$(mulle-sourcetree commands | wc -l)"
echo "Total commands: $COMMAND_COUNT"

# Check if command exists
if mulle-sourcetree commands | grep -q "add"; then
  echo "add command is available"
fi
```

## Command Categories

### Core Operations
Essential commands for basic sourcetree management:

- **add**: Add nodes to the sourcetree
- **list**: List sourcetree nodes
- **status**: Show sourcetree status
- **sync**: Synchronize sourcetree

### Node Management
Commands for manipulating individual nodes:

- **set**: Set node properties
- **get**: Get node properties
- **remove**: Remove nodes
- **move**: Move/rename nodes
- **mark**: Mark nodes with special properties
- **unmark**: Remove marks from nodes
- **duplicate**: Duplicate nodes
- **rename**: Rename nodes
- **copy**: Copy nodes
- **rcopy**: Recursively copy nodes

### Configuration & Info
Commands for configuration and information:

- **config**: Manage configuration settings
- **info**: Show detailed node information
- **json**: Output sourcetree as JSON
- **walk**: Walk through sourcetree structure

### System Operations
Advanced system-level operations:

- **clean**: Clean sourcetree artifacts
- **fix**: Fix sourcetree issues
- **reset**: Reset sourcetree state
- **reuuid**: Regenerate node UUIDs
- **rewrite**: Rewrite sourcetree files
- **craftorder**: Show craft order
- **wrap**: Wrap sourcetree operations
- **dbstatus**: Show database status
- **dotdump**: Dump graphviz dot file
- **filter**: Filter sourcetree nodes
- **eval-add**: Evaluate and add nodes
- **supermark**: Manage supermarks
- **star-search**: Search with wildcards
- **test**: Run tests
- **touch**: Update node timestamps
- **uname**: Show system information
- **plugin**: Manage plugins
- **desecrate**: Remove sacred marks

### Utility Commands
Helper and informational commands:

- **etc-dir**: Show etc directory
- **project-dir**: Show project directory
- **var-dir**: Show var directory
- **share-dir**: Show share directory
- **pwd**: Show current directory
- **mode**: Show/change operating mode
- **libexec-dir**: Show libexec directory
- **sourcetree-dir**: Show sourcetree directory
- **tool-env**: Show tool environment
- **shell**: Start interactive shell
- **version**: Show version information
- **commands**: List commands (this command)

## Use Cases

### Command Discovery
```bash
# Find commands for specific tasks
mulle-sourcetree commands | grep "add"
mulle-sourcetree commands | grep "list"
mulle-sourcetree commands | grep "config"

# Discover new commands
mulle-sourcetree commands --new
mulle-sourcetree commands --experimental
```

### Documentation Generation
```bash
# Generate command reference
mulle-sourcetree commands --help > command-reference.md

# Create command index
mulle-sourcetree commands --categories > command-categories.txt

# Export command list
mulle-sourcetree commands --all --format json > commands.json
```

### Interactive Exploration
```bash
# Start shell and explore commands
mulle-sourcetree shell
$ mulle-sourcetree commands --help | less
$ mulle-sourcetree commands --core

# Get help for specific commands
$ mulle-sourcetree add --help
$ mulle-sourcetree list --help
```

## Command Information

### Command Details
Each command provides information including:

- **Name**: Command identifier
- **Category**: Functional category
- **Description**: Brief description
- **Options**: Available command-line options
- **Examples**: Usage examples
- **Related**: Related commands

### Command Status
```bash
# Show command availability
mulle-sourcetree commands --available

# Show deprecated commands
mulle-sourcetree commands --deprecated

# Show experimental commands
mulle-sourcetree commands --experimental
```

## Integration with Other Commands

### With help
```bash
# Get help for all commands
mulle-sourcetree commands --help

# Get help for specific category
mulle-sourcetree commands --core --help

# Show help examples
mulle-sourcetree commands --examples
```

### With config
```bash
# Configure command display
mulle-sourcetree config set commands.show_category true
mulle-sourcetree config set commands.show_description true

# Show command configuration
mulle-sourcetree config list commands

# Reset command settings
mulle-sourcetree config reset commands
```

### With info
```bash
# Show detailed command information
mulle-sourcetree info --command add

# Show command relationships
mulle-sourcetree info --command-dependencies add

# Show command usage statistics
mulle-sourcetree info --command-usage
```

## Advanced Features

### Command Filtering
```bash
# Filter by pattern
mulle-sourcetree commands --filter "*add*"

# Filter by category
mulle-sourcetree commands --category core

# Filter by status
mulle-sourcetree commands --status stable
```

### Command Analysis
```bash
# Analyze command usage
mulle-sourcetree commands --analyze

# Show command dependencies
mulle-sourcetree commands --dependencies

# Show command relationships
mulle-sourcetree commands --relationships
```

### Custom Command Lists
```bash
# Create custom command list
mulle-sourcetree commands --create-list my-commands

# Load custom command list
mulle-sourcetree commands --load-list my-commands

# Edit custom command list
mulle-sourcetree commands --edit-list my-commands
```

## Troubleshooting

### Common Issues
```bash
# Commands not showing
mulle-sourcetree commands --debug

# Wrong command count
mulle-sourcetree commands --validate

# Missing command descriptions
mulle-sourcetree commands --rebuild-cache
```

### Category Issues
```bash
# Wrong category assignment
mulle-sourcetree commands --fix-categories

# Missing categories
mulle-sourcetree commands --add-category utility

# Category conflicts
mulle-sourcetree commands --resolve-category-conflicts
```

### Display Issues
```bash
# Formatting problems
mulle-sourcetree commands --format plain

# Encoding issues
mulle-sourcetree commands --encoding utf-8

# Terminal width issues
mulle-sourcetree commands --width 80
```

## Integration with Development Workflow

### IDE Integration
```bash
# Configure IDE command completion
mulle-sourcetree commands --completion-script bash > ~/.bashrc.d/mulle-completion.bash

# Generate IDE command reference
mulle-sourcetree commands --ide-format vscode > .vscode/mulle-commands.json

# Create editor snippets
mulle-sourcetree commands --snippets vim > ~/.vim/snippets/mulle.snippets
```

### Build System Integration
```bash
# Use in Makefiles
.PHONY: help
help:
	mulle-sourcetree commands --help

# Integration with build scripts
build.sh:
	#!/bin/bash
	echo "Available commands:"
	mulle-sourcetree commands --core
	echo "Run 'mulle-sourcetree <command> --help' for details"
```

### Documentation Integration
```bash
# Generate documentation
mulle-sourcetree commands --generate-docs > docs/commands.md

# Update documentation index
mulle-sourcetree commands --update-index docs/index.md

# Validate documentation
mulle-sourcetree commands --validate-docs docs/
```

## Performance Considerations

- Command listing is cached for performance
- Use specific categories for faster results
- Avoid `--help` for large command sets
- Consider output format for scripting

## Security Considerations

### Command Validation
```bash
# Validate command integrity
mulle-sourcetree commands --validate

# Check command permissions
mulle-sourcetree commands --check-permissions

# Audit command access
mulle-sourcetree commands --audit
```

### Safe Execution
```bash
# Show safe commands only
mulle-sourcetree commands --safe

# Hide dangerous commands
mulle-sourcetree commands --hide-dangerous

# Require confirmation for dangerous commands
mulle-sourcetree commands --require-confirmation
```

## Notes

- Commands are automatically discovered
- Categories help organize related functionality
- Some commands may be platform-specific
- Command availability may depend on configuration

## See Also

- [`help`](help.md) - Get help for commands
- [`info`](info.md) - Show detailed information
- [`config`](config.md) - Manage configuration
- [`status`](status.md) - Show system status