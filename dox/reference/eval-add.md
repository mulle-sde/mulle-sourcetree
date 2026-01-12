# eval-add

## SYNOPSIS

mulle-sourcetree **eval-add** [options] <commands>

## DESCRIPTION

Process a batch of mulle-sourcetree add commands. The eval-add command takes a string containing multiple add commands separated by linefeeds and executes them sequentially.

This command is designed for processing "sourcetree" files or batch operations where multiple nodes need to be added to the sourcetree configuration.

## OPTIONS

- `-h`, `--help` : Show help information
- `--filename <name>` : Specify filename for error reporting (optional)

## PARAMETERS

- `<commands>` : String containing mulle-sourcetree add commands separated by newlines

## EXAMPLES

### Basic Batch Processing
```bash
mulle-sourcetree eval-add "
add src/mylib --url https://github.com/user/mylib.git
add src/lib2 --url https://github.com/user/lib2.git --marks no-require
add src/local --nodetype local
"
```

### From a File
```bash
# Read commands from a file
mulle-sourcetree eval-add "$(cat sourcetree-commands.txt)"
```

### With Error Context
```bash
# Specify filename for better error reporting
mulle-sourcetree eval-add --filename "project.sourcetree" "
add src/zlib --url https://github.com/madler/zlib.git
add src/expat --url https://github.com/libexpat/libexpat.git
"
```

## COMMAND FORMAT

### Supported Command Formats
```bash
# Full command with executable
mulle-sourcetree add src/mylib --url https://github.com/user/mylib.git

# Just the add part (prefix will be stripped)
add src/mylib --url https://github.com/user/mylib.git

# With line continuations
add src/mylib --url https://github.com/user/mylib.git \
              --branch develop
```

### Multi-line Commands
```bash
mulle-sourcetree eval-add "
add src/mylib \\
    --url https://github.com/user/mylib.git \\
    --branch develop \\
    --marks build
"
```

## PROCESSING RULES

1. **Line Parsing**: Commands are split by newlines
2. **Continuation**: Backslash at end of line continues to next line
3. **Prefix Stripping**: "mulle-sourcetree add" prefix is automatically removed
4. **Whitespace**: Multiple spaces are collapsed to single spaces
5. **Security**: Commands containing `$(` or backticks are rejected

## ERROR HANDLING

- **Security Check**: Commands with `$(` or backticks are rejected
- **Syntax Errors**: Malformed commands show filename and command in error
- **Batch Processing**: Continues processing other commands if one fails
- **Error Context**: Uses `--filename` for better error reporting

## USE CASES

### Processing Sourcetree Files
```bash
# Process a .sourcetree file
mulle-sourcetree eval-add "$(cat project.sourcetree)"
```

### Bulk Node Addition
```bash
# Add multiple dependencies at once
mulle-sourcetree eval-add "
add src/zlib --url https://github.com/madler/zlib.git
add src/expat --url https://github.com/libexpat/libexpat.git
add src/curl --url https://github.com/curl/curl.git
"
```

### Automated Setup
```bash
# Use in scripts for project initialization
#!/bin/bash
mulle-sourcetree eval-add "
add src/boost --url https://github.com/boostorg/boost.git --marks no-build
add src/openssl --url https://github.com/openssl/openssl.git
add src/zlib --url https://github.com/madler/zlib.git
"
```

## NOTES

- Commands are executed in the order they appear
- Each command is processed independently
- Failed commands don't stop processing of remaining commands
- All the same options as `add` command are supported
- Useful for processing configuration files or batch operations
- Security measures prevent execution of dangerous commands

## SEE ALSO

- [mulle-sourcetree add](add.md) - Add a single node to the sourcetree
- [mulle-sourcetree sync](sync.md) - Apply configuration changes to filesystem
- [mulle-sourcetree list](list.md) - List nodes in the sourcetree