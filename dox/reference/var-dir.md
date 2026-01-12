# var-dir

## SYNOPSIS

mulle-sourcetree **var-dir**

## DESCRIPTION

Print the path to the sourcetree var directory. The var directory contains sourcetree runtime data and databases, typically located at `${MULLE_SOURCETREE_PROJECT_DIR}/.mulle/var/sourcetree/`.

## EXAMPLES

### Get Var Directory Path
```bash
# Print the var directory path
mulle-sourcetree var-dir
```

### Sample Output
```
/home/user/project/.mulle/var/sourcetree
```

### Use in Scripts
```bash
# Use in shell scripts
VAR_DIR=$(mulle-sourcetree var-dir)
echo "Database files are in: $VAR_DIR"
```

## DIRECTORY CONTENTS

The var directory typically contains:
- `db` - Sourcetree database file
- `fix` - Fix tracking file
- Graveyard directories (for removed nodes)
- Other runtime data

## USE CASES

### Database Management
```bash
# Check database location
mulle-sourcetree var-dir
# Output: /home/user/project/.mulle/var/sourcetree
# Then: ls /home/user/project/.mulle/var/sourcetree/
```

### Backup Runtime Data
```bash
# Backup database and runtime files
VAR_DIR=$(mulle-sourcetree var-dir)
cp -r "$VAR_DIR" "$VAR_DIR.backup"
```

### Debug Database Issues
```bash
# Examine database file
VAR_DIR=$(mulle-sourcetree var-dir)
sqlite3 "$VAR_DIR/db" ".tables"
```

### Clean Runtime Data
```bash
# Remove all runtime data (use with caution)
VAR_DIR=$(mulle-sourcetree var-dir)
rm -rf "$VAR_DIR"/*
```

## RELATIONSHIP TO OTHER DIRECTORIES

- **Project Directory**: Root of the project
- **Etc Directory**: Configuration files
- **Var Directory**: Runtime data and databases
- **Stash Directory**: Fetched dependencies

## SEE ALSO

- [mulle-sourcetree etc-dir](etc-dir.md) - Print etc directory
- [mulle-sourcetree project-dir](project-dir.md) - Print project directory
- [mulle-sourcetree share-dir](share-dir.md) - Print stash directory
- [mulle-sourcetree reset](reset.md) - Clear database
- [mulle-sourcetree status](status.md) - Show database status