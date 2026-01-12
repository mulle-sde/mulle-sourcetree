# desecrate

## SYNOPSIS

mulle-sourcetree **desecrate**

## DESCRIPTION

Remove all graveyard directories. The desecrate command permanently deletes all graveyard directories that contain the remains of previously removed sourcetree nodes.

Graveyards are special directories where removed nodes are stored instead of being completely deleted. This allows for recovery of accidentally removed nodes. The desecrate command removes these graveyards permanently.

## OPTIONS

This command has no options.

## EXAMPLES

### Remove All Graveyards
```bash
mulle-sourcetree desecrate
```

## WHAT ARE GRAVEYARDS?

Graveyards are directories that contain:
- Configuration files of removed nodes
- Metadata about removed nodes
- Backup information for potential recovery

### Graveyard Locations
- Located in: `${MULLE_SOURCETREE_VAR_DIR}/../../<hostname>/sourcetree/graveyard`
- One graveyard per host system
- Contains subdirectories for each removed node

## WHEN TO USE

### Free Up Disk Space
```bash
# Remove accumulated graveyard data
mulle-sourcetree desecrate
```

### Clean System After Testing
```bash
# Clean up after extensive testing and node removal
mulle-sourcetree desecrate
```

### System Maintenance
```bash
# Periodic cleanup of graveyard directories
mulle-sourcetree desecrate
```

## WHAT IT DOES

1. **Finds All Graveyards**: Searches for graveyard directories across all host systems
2. **Removes Directories**: Permanently deletes all found graveyard directories
3. **Cleans Host Data**: Removes graveyard data for all configured hosts

## NOTES

- **Permanent Deletion**: This action cannot be undone
- **No Recovery**: Removed graveyards cannot be restored
- **Host-Specific**: Removes graveyards for all hosts on the system
- **Safe Operation**: Only removes graveyard directories, not active nodes
- **No Filesystem Impact**: Does not affect fetched files or working directories

## RELATIONSHIP TO CLEAN

The desecrate command is equivalent to:
```bash
mulle-sourcetree clean --all-graveyards --no-fs
```

It removes graveyards but does not touch fetched files.

## BACKUP RECOMMENDATION

Since desecrate permanently removes graveyard data, consider the implications:

```bash
# If you need to keep graveyard data
# Don't run desecrate

# If you're sure you don't need recovery
mulle-sourcetree desecrate
```

## SEE ALSO

- [mulle-sourcetree clean](clean.md) - Remove fetched files and optionally graveyards
- [mulle-sourcetree remove](remove.md) - Remove nodes (creates graveyards)
- [mulle-sourcetree list](list.md) - List current nodes