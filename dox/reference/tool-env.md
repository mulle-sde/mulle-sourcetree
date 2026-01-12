# tool-env

## SYNOPSIS

mulle-sourcetree **tool-env**

## DESCRIPTION

Print environment variables for use by other tools. The tool-env command outputs shell-compatible environment variable assignments for key sourcetree paths.

This command is designed to be used by other tools and scripts that need to know the sourcetree configuration.

## EXAMPLES

### Get Environment Variables
```bash
# Print sourcetree environment variables
mulle-sourcetree tool-env
```

### Sample Output
```
MULLE_SOURCETREE_PROJECT_DIR='/home/user/my-project'
MULLE_SOURCETREE_STASH_DIR='/home/user/my-project/stash'
```

### Use in Scripts
```bash
# Source environment variables in bash
eval $(mulle-sourcetree tool-env)

# Use in makefiles
TOOL_ENV := $(shell mulle-sourcetree tool-env)
```

## OUTPUT FORMAT

The command outputs shell variable assignments in the format:
```
VARIABLE_NAME='value'
```

## VARIABLES PROVIDED

- **MULLE_SOURCETREE_PROJECT_DIR**: Path to the project root directory
- **MULLE_SOURCETREE_STASH_DIR**: Path to the stash directory for fetched dependencies

## USE CASES

### Build System Integration
```bash
# In Makefiles
TOOL_ENV := $(shell mulle-sourcetree tool-env)
include $(TOOL_ENV)
```

### Shell Script Integration
```bash
# Source variables in shell scripts
eval "$(mulle-sourcetree tool-env)"
echo "Project: $MULLE_SOURCETREE_PROJECT_DIR"
echo "Stash: $MULLE_SOURCETREE_STASH_DIR"
```

### CI/CD Integration
```bash
# Export variables for CI systems
export $(mulle-sourcetree tool-env)
```

### Development Tools
```bash
# Use in custom development tools
eval "$(mulle-sourcetree tool-env)"
# Now scripts can use $MULLE_SOURCETREE_PROJECT_DIR
```

## NOTES

- Output is designed to be `eval`'d in shell scripts
- Variables are properly quoted for shell safety
- Only outputs essential path variables
- No options or arguments accepted
- Safe to use in automated scripts

## SEE ALSO

- [mulle-sourcetree info](info.md) - Show all sourcetree information
- [mulle-sourcetree project-dir](project-dir.md) - Print project directory
- [mulle-sourcetree share-dir](share-dir.md) - Print stash directory