# project-dir

## SYNOPSIS

mulle-sourcetree **project-dir**

## DESCRIPTION

Print the path to the sourcetree project directory. The project directory is the root directory of the project that contains the sourcetree configuration.

## EXAMPLES

### Get Project Directory Path
```bash
# Print the project directory path
mulle-sourcetree project-dir
```

### Sample Output
```
/home/user/my-project
```

### Use in Scripts
```bash
# Use in shell scripts
PROJECT_DIR=$(mulle-sourcetree project-dir)
echo "Project is located at: $PROJECT_DIR"
```

## RELATIONSHIP TO OTHER DIRECTORIES

- **Project Directory**: Root of the project
- **Etc Directory**: `${PROJECT_DIR}/.mulle/etc/sourcetree/`
- **Var Directory**: `${PROJECT_DIR}/.mulle/var/sourcetree/`
- **Stash Directory**: `${PROJECT_DIR}/stash/` (or custom location)

## USE CASES

### Project Navigation
```bash
# Navigate to project root
cd $(mulle-sourcetree project-dir)
```

### Path Calculations
```bash
# Calculate relative paths
PROJECT_DIR=$(mulle-sourcetree project-dir)
ETC_DIR=$(mulle-sourcetree etc-dir)
REL_PATH=${ETC_DIR#$PROJECT_DIR/}
echo "Config relative to project: $REL_PATH"
```

### Build Scripts
```bash
# Use in build scripts
PROJECT_ROOT=$(mulle-sourcetree project-dir)
cd "$PROJECT_ROOT"
make
```

### Backup Operations
```bash
# Backup entire project
PROJECT_DIR=$(mulle-sourcetree project-dir)
tar -czf "${PROJECT_DIR}.tar.gz" -C "$(dirname "$PROJECT_DIR")" "$(basename "$PROJECT_DIR")"
```

## SEE ALSO

- [mulle-sourcetree etc-dir](etc-dir.md) - Print etc directory
- [mulle-sourcetree var-dir](var-dir.md) - Print var directory
- [mulle-sourcetree share-dir](share-dir.md) - Print stash directory
- [mulle-sourcetree info](info.md) - Show all directory information