# rewrite

## SYNOPSIS

mulle-sourcetree **rewrite** [options]

## DESCRIPTION

Clean up sourcetree configuration files by rewriting marks. If you hand-edited a sourcetree config file, the marks may contain duplicates and might be sorted in the wrong order. The rewrite command cleans this up by:

- Removing duplicate marks
- Sorting marks in the correct order
- Sanitizing mark formatting
- Ensuring consistent mark representation

**Note:** This will lose all '#' comments in the configuration file.

## OPTIONS

- `-h`, `--help` : Show help information

## EXAMPLES

### Basic Usage
```bash
# Clean up the current sourcetree configuration
mulle-sourcetree rewrite
```

## WHEN TO USE

### After Manual Editing
```bash
# If you manually edit config files and marks get messy
mulle-sourcetree rewrite
```

### Before Committing Changes
```bash
# Clean up configuration before committing
mulle-sourcetree rewrite
git add .mulle/etc/sourcetree/config
git commit -m "Clean up sourcetree marks"
```

### After Bulk Operations
```bash
# After running multiple mark/unmark operations
mulle-sourcetree mark src/* build
mulle-sourcetree unmark src/lib1 no-build
mulle-sourcetree rewrite  # Clean up any inconsistencies
```

## WHAT IT DOES

### Mark Deduplication
**Before:**
```
mylib;git;https://github.com/user/mylib.git;;no-require,no-require,build
```

**After:**
```
mylib;git;https://github.com/user/mylib.git;;build,no-require
```

### Mark Sorting
**Before:**
```
mylib;git;https://github.com/user/mylib.git;;no-require,build,no-public
```

**After:**
```
mylib;git;https://github.com/user/mylib.git;;build,no-public,no-require
```

### Mark Sanitization
**Before:**
```
mylib;git;https://github.com/user/mylib.git;;no-require,,build,
```

**After:**
```
mylib;git;https://github.com/user/mylib.git;;build,no-require
```

## NOTES

- **Destructive Operation**: Removes all '#' comments from config files
- **Safe for Marks**: Only affects mark formatting, not functionality
- **No Data Loss**: Preserves all node information except comments
- **Immediate Effect**: Changes take effect immediately in configuration
- **No Sync Needed**: Changes are to configuration only, not filesystem

## BACKUP RECOMMENDATION

Since rewrite modifies configuration files, consider backing up before running:

```bash
# Backup before rewrite
cp .mulle/etc/sourcetree/config .mulle/etc/sourcetree/config.backup
mulle-sourcetree rewrite
```

## SEE ALSO

- [mulle-sourcetree mark](mark.md) - Add marks to nodes
- [mulle-sourcetree unmark](unmark.md) - Remove marks from nodes
- [mulle-sourcetree set](set.md) - Change node properties
- [mulle-sourcetree list](list.md) - List nodes and their marks