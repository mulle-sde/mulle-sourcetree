# share-dir

## SYNOPSIS

mulle-sourcetree **share-dir**

mulle-sourcetree **stash-dir**

## DESCRIPTION

Print the path to the sourcetree stash directory. The stash directory is where fetched dependencies are stored. It defaults to `${MULLE_SOURCETREE_PROJECT_DIR}/stash/` but can be configured via the `MULLE_SOURCETREE_STASH_DIR` environment variable.

Both `share-dir` and `stash-dir` commands are equivalent and can be used interchangeably.

## EXAMPLES

### Get Stash Directory Path
```bash
# Print the stash directory path
mulle-sourcetree share-dir
# or
mulle-sourcetree stash-dir
```

### Sample Output
```
/home/user/project/stash
```

### Use in Scripts
```bash
# Use in shell scripts
STASH_DIR=$(mulle-sourcetree share-dir)
echo "Dependencies are stored in: $STASH_DIR"
```

## DIRECTORY CONTENTS

The stash directory typically contains:
- Fetched git repositories
- Downloaded archives (tar, zip, etc.)
- Unpacked dependencies
- Symlinks to shared dependencies

## USE CASES

### Examine Fetched Dependencies
```bash
# List all fetched dependencies
ls $(mulle-sourcetree share-dir)
```

### Check Disk Usage
```bash
# Check space used by dependencies
du -sh $(mulle-sourcetree share-dir)
```

### Manual Dependency Management
```bash
# Clean specific dependency
STASH_DIR=$(mulle-sourcetree share-dir)
rm -rf "$STASH_DIR/zlib"
mulle-sourcetree sync  # Will refetch zlib
```

### Backup Dependencies
```bash
# Backup all fetched dependencies
STASH_DIR=$(mulle-sourcetree share-dir)
tar -czf dependencies.tar.gz -C "$STASH_DIR" .
```

### Debug Fetch Issues
```bash
# Check if dependency was fetched correctly
STASH_DIR=$(mulle-sourcetree share-dir)
ls -la "$STASH_DIR/zlib/"
```

## CONFIGURATION

### Default Location
```
${PROJECT_DIR}/stash/
```

### Custom Location
```bash
# Set custom stash directory
export MULLE_SOURCETREE_STASH_DIR=/tmp/my-stash
mulle-sourcetree share-dir
# Output: /tmp/my-stash
```

## RELATIONSHIP TO OTHER DIRECTORIES

- **Project Directory**: Root of the project
- **Etc Directory**: Configuration files
- **Var Directory**: Runtime data and databases
- **Stash Directory**: Fetched dependencies

## SEE ALSO

- [mulle-sourcetree etc-dir](etc-dir.md) - Print etc directory
- [mulle-sourcetree project-dir](project-dir.md) - Print project directory
- [mulle-sourcetree var-dir](var-dir.md) - Print var directory
- [mulle-sourcetree clean](clean.md) - Remove fetched files
- [mulle-sourcetree sync](sync.md) - Fetch dependencies