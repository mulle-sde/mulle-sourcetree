# mulle-sourcetree Command Reference

## Overview

**mulle-sourcetree** is a command-line tool for managing source trees and dependency configurations in the Mulle ecosystem. It provides a structured way to define, manipulate, and synchronize project dependencies and subprojects through a node-based configuration system.

## Command Categories

### Core Operations
- **[`add`](add.md)** - Add a new node to the sourcetree
- **[`list`](list.md)** - List all nodes in the sourcetree
- **[`status`](status.md)** - Display sourcetree status and validation
- **[`sync`](sync.md)** - Synchronize the sourcetree with the filesystem

### Node Management
- **[`set`](set.md)** - Set properties on existing nodes
- **[`get`](get.md)** - Get properties from nodes
- **[`remove`](remove.md)** - Remove nodes from the sourcetree
- **[`move`](move.md)** - Move or rename nodes
- **[`mark`](mark.md)** - Add marks to nodes
- **[`unmark`](unmark.md)** - Remove marks from nodes
- **[`duplicate`](duplicate.md)** - Duplicate nodes
- **[`rename`](rename.md)** - Rename nodes
- **[`copy`](copy.md)** - Copy nodes
- **[`rcopy`](rcopy.md)** - Copy nodes from another sourcetree

### Configuration & Info
- **[`config`](config.md)** - Manage sourcetree configuration settings
- **[`info`](info.md)** - Display detailed information about nodes
- **[`json`](json.md)** - Output sourcetree data as JSON
- **[`walk`](walk.md)** - Walk through the sourcetree structure

### System Operations
- **[`clean`](clean.md)** - Remove files added by sync
- **[`fix`](fix.md)** - Track filesystem modifications
- **[`reset`](reset.md)** - Clear database to force sync
- **[`reuuid`](reuuid.md)** - Create new UUIDs for sourcetree
- **[`rewrite`](rewrite.md)** - Clean up node marks
- **[`craftorder`](craftorder.md)** - Emit build-order nodes
- **[`wrap`](wrap.md)** - Wrap node types in environment variables
- **[`dbstatus`](dbstatus.md)** - Query database state
- **[`dotdump`](dotdump.md)** - Create visual sourcetree diagram
- **[`filter`](filter.md)** - Test mark filters
- **[`eval-add`](eval-add.md)** - Batch process add commands
- **[`supermark`](supermark.md)** - Manage supermarks
- **[`star-search`](star-search.md)** - Search for duplicate nodes
- **[`test`](test.md)** - Test mark matching
- **[`touch`](touch.md)** - Mark sourcetree as dirty
- **[`uname`](uname.md)** - Show system information
- **[`plugin`](plugin.md)** - Manage plugins
- **[`desecrate`](desecrate.md)** - Remove all graveyards

### Utility Commands
- **[`etc-dir`](etc-dir.md)** - Print etc directory path
- **[`project-dir`](project-dir.md)** - Print project directory path
- **[`var-dir`](var-dir.md)** - Print var directory path
- **[`share-dir`](share-dir.md)** - Print share directory path
- **[`pwd`](pwd.md)** - Print current directory
- **[`mode`](mode.md)** - Show current mode
- **[`libexec-dir`](libexec-dir.md)** - Print libexec directory path
- **[`sourcetree-dir`](sourcetree-dir.md)** - Print sourcetree directory path
- **[`tool-env`](tool-env.md)** - Show tool environment
- **[`shell`](shell.md)** - Show shell information
- **[`version`](version.md)** - Show version information
- **[`commands`](commands.md)** - List all commands

## Quick Start Examples

### Basic Node Management
```bash
# Add a git repository as a dependency
mulle-sourcetree add https://github.com/example/library.git

# List all nodes
mulle-sourcetree list

# Get information about a specific node
mulle-sourcetree get example/library

# Remove a node
mulle-sourcetree remove example/library
```

### Configuration and Status
```bash
# Check sourcetree status
mulle-sourcetree status

# View configuration
mulle-sourcetree config list

# Synchronize filesystem with configuration
mulle-sourcetree sync
```

### Advanced Operations
```bash
# Set custom properties on a node
mulle-sourcetree set example/library marks "no-update,no-delete"

# Export sourcetree as JSON
mulle-sourcetree json

# Walk and display the tree structure
mulle-sourcetree walk
```

## Command Reference Table

| Command | Category | Description |
|---------|----------|-------------|
| `add` | Core | Add nodes to the sourcetree |
| `list` | Core | List sourcetree nodes |
| `status` | Core | Show sourcetree status |
| `sync` | Core | Synchronize sourcetree |
| `set` | Node | Set node properties |
| `get` | Node | Get node properties |
| `remove` | Node | Remove nodes |
| `move` | Node | Move/rename nodes |
| `mark` | Node | Add marks to nodes |
| `unmark` | Node | Remove marks from nodes |
| `duplicate` | Node | Duplicate nodes |
| `rename` | Node | Rename nodes |
| `copy` | Node | Copy nodes |
| `rcopy` | Node | Copy nodes from another sourcetree |
| `config` | Config | Manage configuration |
| `info` | Config | Display node information |
| `json` | Config | JSON output |
| `walk` | Config | Walk tree structure |
| `clean` | System | Remove files added by sync |
| `fix` | System | Track filesystem modifications |
| `reset` | System | Clear database to force sync |
| `reuuid` | System | Create new UUIDs for sourcetree |
| `rewrite` | System | Clean up node marks |
| `craftorder` | System | Emit build-order nodes |
| `wrap` | System | Wrap node types in environment variables |
| `dbstatus` | System | Query database state |
| `dotdump` | System | Create visual sourcetree diagram |
| `filter` | System | Test mark filters |
| `eval-add` | System | Batch process add commands |
| `supermark` | System | Manage supermarks |
| `star-search` | System | Search for duplicate nodes |
| `test` | System | Test mark matching |
| `touch` | System | Mark sourcetree as dirty |
| `uname` | System | Show system information |
| `plugin` | System | Manage plugins |
| `desecrate` | System | Remove all graveyards |
| `etc-dir` | Utility | Print etc directory path |
| `project-dir` | Utility | Print project directory path |
| `var-dir` | Utility | Print var directory path |
| `share-dir` | Utility | Print share directory path |
| `pwd` | Utility | Print current directory |
| `mode` | Utility | Show current mode |
| `libexec-dir` | Utility | Print libexec directory path |
| `sourcetree-dir` | Utility | Print sourcetree directory path |
| `tool-env` | Utility | Show tool environment |
| `shell` | Utility | Show shell information |
| `version` | Utility | Show version information |
| `commands` | Utility | List all commands |

## Getting Help

### Command Help
```bash
# Get help for a specific command
mulle-sourcetree <command> --help

# List all available commands
mulle-sourcetree --help

# Get detailed command information
mulle-sourcetree <command> --help --verbose
```

### Documentation
- Each command has a dedicated documentation file in this reference
- Use `--help` for quick command usage
- Check `mulle-sourcetree status` for current configuration state

## Common Workflows

### Adding Dependencies
1. **Add** dependency: `mulle-sourcetree add <url>`
2. **Configure** properties: `mulle-sourcetree set <node> <properties>`
3. **Sync** filesystem: `mulle-sourcetree sync`
4. **Verify** status: `mulle-sourcetree status`

### Managing Nodes
1. **List** nodes: `mulle-sourcetree list`
2. **Get** node info: `mulle-sourcetree get <node>`
3. **Modify** properties: `mulle-sourcetree set <node> <key> <value>`
4. **Sync** changes: `mulle-sourcetree sync`

### Configuration Management
1. **View** config: `mulle-sourcetree config list`
2. **Set** config: `mulle-sourcetree config set <key> <value>`
3. **Export** data: `mulle-sourcetree json`
4. **Validate** setup: `mulle-sourcetree status`

## Troubleshooting

### Common Issues
```bash
# Check for configuration errors
mulle-sourcetree status --verbose

# Validate node definitions
mulle-sourcetree list --validate

# Reset problematic nodes
mulle-sourcetree sync --reset
```

### Node Problems
```bash
# Check node properties
mulle-sourcetree get <node> --all

# Fix missing nodes
mulle-sourcetree sync --fetch

# Remove corrupted nodes
mulle-sourcetree remove <node> --force
```

### Configuration Issues
```bash
# Reset configuration
mulle-sourcetree config reset

# Check configuration file
mulle-sourcetree config list --file

# Reinitialize sourcetree
mulle-sourcetree status --reinit
```

## Advanced Usage

### Custom Node Properties
```bash
# Set multiple properties
mulle-sourcetree set mylib marks "no-update,no-share"
mulle-sourcetree set mylib branch "develop"
mulle-sourcetree set mylib url "https://custom.repo.git"
```

### Batch Operations
```bash
# Add multiple nodes
mulle-sourcetree add lib1 lib2 lib3

# Set properties on multiple nodes
mulle-sourcetree set lib1 lib2 marks "shared"
```

### Integration with Scripts
```bash
# Export for scripting
mulle-sourcetree json > sourcetree.json

# Process node information
for node in $(mulle-sourcetree list --names); do
   mulle-sourcetree get $node url
done
```

## Related Documentation

- **[TODO.md](../TODO.md)** - Current development status and process guide
- **[README.md](../../README.md)** - Project overview and installation
- **[mulle-sde.md](../mulle-sde.md)** - Build system guidelines
- **[mulle-fetch.md](../mulle-fetch.md)** - Fetching and cloning documentation