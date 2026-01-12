# touch

## SYNOPSIS

mulle-sourcetree **touch**

## DESCRIPTION

Update the modification time of sourcetree configuration files. The touch command marks the sourcetree as "dirty" by updating the timestamps of configuration files, which will trigger a rescan on the next operation.

This command updates the modification time of:
- `${MULLE_SOURCETREE_ETC_DIR}/config`
- `${MULLE_SOURCETREE_ETC_DIR}/config.${MULLE_UNAME}` (if it exists)

## EXAMPLES

### Mark Configuration as Dirty
```bash
# Mark sourcetree as needing update
mulle-sourcetree touch
```

### Force Rescan
```bash
# Force sourcetree to rescan on next operation
mulle-sourcetree touch
mulle-sourcetree status  # Will rescan configuration
```

## USE CASES

### After Manual Config Changes
```bash
# After editing config files manually
vim .mulle/etc/sourcetree/config
mulle-sourcetree touch
mulle-sourcetree sync
```

### Force Configuration Reload
```bash
# Force reload of configuration
mulle-sourcetree touch
mulle-sourcetree list  # Will reload config
```

### Development Workflow
```bash
# In development scripts to ensure fresh config
mulle-sourcetree touch
# ... make changes ...
mulle-sourcetree sync
```

## NOTES

- Only affects configuration files, not fetched dependencies
- Safe to run multiple times
- No options or arguments
- Updates timestamps to current time
- Triggers configuration reload on next operation

## SEE ALSO

- [mulle-sourcetree sync](sync.md) - Apply configuration changes
- [mulle-sourcetree status](status.md) - Check sourcetree status
- [mulle-sourcetree reset](reset.md) - Clear database for fresh sync