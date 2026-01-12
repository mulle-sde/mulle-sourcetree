# mulle-sourcetree copy

Create a copy of a node with different configuration or location.

## Synopsis

```bash
mulle-sourcetree copy [options] <source-node> <target-node>
```

## Description

The `copy` command creates a new node that is a copy of an existing node, but with potentially different properties, marks, or location. This allows you to maintain multiple variants of the same dependency with different configurations.

## Options

- `--address <address>` : Set specific address for the copy
- `--marks <marks>` : Apply different marks to the copy
- `--url <url>` : Use different URL for the copy
- `--branch <branch>` : Use different branch for the copy
- `--tag <tag>` : Use different tag for the copy
- `--force` : Overwrite existing target if it exists
- `--dry-run` : Show what would be copied without executing
- `--verbose` : Show detailed copy information

## Examples

### Basic copy
```bash
mulle-sourcetree copy mylib mylib-copy
```

### Copy with different marks
```bash
mulle-sourcetree copy mylib mylib-test --marks "test,no-build"
```

### Copy with different location
```bash
mulle-sourcetree copy mylib mylib-alt --address src/alternatives/mylib
```

### Copy with different branch
```bash
mulle-sourcetree copy mylib mylib-dev --branch develop
```

## Copy Process

### Configuration Duplication
1. **Validate source**: Ensure source node exists
2. **Check target**: Verify target name/address is available
3. **Copy properties**: Duplicate all node properties
4. **Apply modifications**: Override specified properties
5. **Register copy**: Add new node to sourcetree database

### Filesystem Handling
1. **Create new location**: Set up directory structure for target
2. **Copy or link files**: Depending on configuration, copy files or create links
3. **Update references**: Adjust any references to point to new location
4. **Sync changes**: Apply filesystem changes during next sync

## Common Use Cases

### Testing Variants
```bash
# Create test version with different configuration
mulle-sourcetree copy mylib mylib-test --marks "test,no-share"

# Create development version
mulle-sourcetree copy mylib mylib-dev --branch develop
```

### Multiple Deployment Configurations
```bash
# Static version for deployment
mulle-sourcetree copy mylib mylib-static --marks "static"

# Debug version for development
mulle-sourcetree copy mylib mylib-debug --marks "debug"
```

### Backup and Recovery
```bash
# Create backup before major changes
mulle-sourcetree copy mylib mylib-backup

# Create experimental version
mulle-sourcetree copy mylib mylib-experimental --branch experimental
```

## Copy vs Duplicate

### Copy
- Creates new node with modified properties
- Can change URL, branch, marks, address
- More flexible configuration changes
- May create separate file copies

### Duplicate
- Creates identical copy with new name
- Preserves all original properties
- Minimal configuration changes
- Shares files by default

## Notes

- Copy allows changing any property of the source node
- Changes take effect during next `sync` operation
- Use `--dry-run` to preview what will be changed
- Some property changes may require filesystem operations

## See Also

- [`duplicate`](duplicate.md) - Create identical copy of a node
- [`move`](move.md) - Move existing node to new location
- [`set`](set.md) - Modify properties of existing node
- [`sync`](sync.md) - Apply configuration changes to filesystem