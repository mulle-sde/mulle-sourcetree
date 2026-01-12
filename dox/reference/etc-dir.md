# etc-dir

## SYNOPSIS

mulle-sourcetree **etc-dir**

## DESCRIPTION

Print the path to the sourcetree etc directory. The etc directory contains sourcetree configuration files and is typically located at `${MULLE_SOURCETREE_PROJECT_DIR}/.mulle/etc/sourcetree/`.

## EXAMPLES

### Get Etc Directory Path
```bash
# Print the etc directory path
mulle-sourcetree etc-dir
```

### Sample Output
```
/home/user/project/.mulle/etc/sourcetree
```

### Use in Scripts
```bash
# Use in shell scripts
ETC_DIR=$(mulle-sourcetree etc-dir)
echo "Config files are in: $ETC_DIR"
```

## DIRECTORY CONTENTS

The etc directory typically contains:
- `config` - Main sourcetree configuration file
- `config.<platform>` - Platform-specific configuration files
- Other configuration files

## USE CASES

### Configuration Management
```bash
# Edit main config file
mulle-sourcetree etc-dir
# Output: /home/user/project/.mulle/etc/sourcetree
# Then: vim /home/user/project/.mulle/etc/sourcetree/config
```

### Backup Configuration
```bash
# Backup config files
ETC_DIR=$(mulle-sourcetree etc-dir)
cp -r "$ETC_DIR" "$ETC_DIR.backup"
```

### Check Configuration Location
```bash
# Verify configuration location
mulle-sourcetree etc-dir
```

## SEE ALSO

- [mulle-sourcetree project-dir](project-dir.md) - Print project directory
- [mulle-sourcetree var-dir](var-dir.md) - Print var directory
- [mulle-sourcetree share-dir](share-dir.md) - Print stash directory
- [mulle-sourcetree config](config.md) - Manage configuration files