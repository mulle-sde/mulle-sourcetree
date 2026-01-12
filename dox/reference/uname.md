# uname

## SYNOPSIS

mulle-sourcetree **uname**

## DESCRIPTION

Print the simplified uname identifier for the current platform. The uname command outputs a normalized platform identifier used by mulle-sourcetree for platform-specific configuration.

This is a simplified version of the system `uname` command, providing consistent identifiers across different systems.

## EXAMPLES

### Get Platform Identifier
```bash
# Print current platform identifier
mulle-sourcetree uname
```

### Sample Output (Linux)
```
linux
```

### Sample Output (macOS)
```
darwin
```

### Sample Output (Windows with MSYS)
```
mingw
```

## COMMON PLATFORM IDENTIFIERS

- **linux**: Linux systems
- **darwin**: macOS systems
- **mingw**: Windows with MinGW/MSYS
- **freebsd**: FreeBSD systems
- **windows**: Windows (native)

## USE CASES

### Platform-Specific Configuration
```bash
# Check current platform for config decisions
PLATFORM=$(mulle-sourcetree uname)
if [ "$PLATFORM" = "darwin" ]; then
    echo "Running on macOS"
fi
```

### Conditional Operations
```bash
# Platform-specific sourcetree operations
case $(mulle-sourcetree uname) in
    darwin)
        mulle-sourcetree mark mylib only-platform-darwin
        ;;
    linux)
        mulle-sourcetree mark mylib only-platform-linux
        ;;
    mingw)
        mulle-sourcetree mark mylib only-platform-mingw
        ;;
esac
```

### Debugging Platform Issues
```bash
# Verify platform detection
echo "Platform: $(mulle-sourcetree uname)"
echo "System uname: $(uname -s | tr '[:upper:]' '[:lower:]')"
```

## RELATIONSHIP TO SYSTEM UNAME

The mulle-sourcetree uname command provides normalized identifiers:

| System uname | mulle-sourcetree uname |
|--------------|------------------------|
| Linux        | linux                  |
| Darwin       | darwin                 |
| MINGW32_NT   | mingw                  |
| FreeBSD      | freebsd                |
| Windows_NT   | windows                |

## CONFIGURATION FILES

Platform identifiers are used for platform-specific configuration files:
- `config` - Default configuration
- `config.darwin` - macOS-specific configuration
- `config.linux` - Linux-specific configuration
- `config.mingw` - Windows-specific configuration

## NOTES

- Always returns lowercase identifiers
- Consistent across different shell environments
- Used internally for platform detection
- No options or arguments
- Safe to use in scripts and automation

## SEE ALSO

- [mulle-sourcetree info](info.md) - Show all system information
- [mulle-sourcetree mode](mode.md) - Print sourcetree mode
- [mulle-sourcetree version](version.md) - Print version information
- `uname` - System uname command