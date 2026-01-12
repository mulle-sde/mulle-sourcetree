# mode

## SYNOPSIS

mulle-sourcetree **mode**

## DESCRIPTION

Print the current sourcetree mode. The mode command displays the current operational mode of the sourcetree, which determines how operations are performed.

The sourcetree mode affects how nodes are processed and can be one of: `share`, `flat`, or `recurse`.

## EXAMPLES

### Check Current Mode
```bash
# Print current sourcetree mode
mulle-sourcetree mode
```

### Sample Output
```
share
```

### Conditional Operations
```bash
# Check mode and act accordingly
MODE=$(mulle-sourcetree mode)
if [ "$MODE" = "flat" ]; then
    echo "Operating in flat mode"
elif [ "$MODE" = "share" ]; then
    echo "Operating in share mode"
elif [ "$MODE" = "recurse" ]; then
    echo "Operating in recursive mode"
fi
```

## SOURCETREE MODES

### share (Default)
- Dependencies are shared between projects
- Stash directory contains shared dependencies
- Most common mode for development

### flat
- No recursive operations
- Each project manages its own dependencies
- Faster for simple projects

### recurse
- Recursive operations on subtrees
- Complex dependency management
- Used for deeply nested project structures

## MODE DETERMINATION

The mode is determined by:
1. Command-line flags (`--flat`, `--share`, `--recurse`)
2. Configuration settings
3. Default mode (share)

## USE CASES

### Debugging Mode Issues
```bash
# Check why operations behave unexpectedly
mulle-sourcetree mode
# Verify mode matches expectations
```

### Script Adaptation
```bash
# Adapt scripts based on mode
case $(mulle-sourcetree mode) in
    flat)
        # Flat mode operations
        ;;
    share)
        # Share mode operations
        ;;
    recurse)
        # Recursive mode operations
        ;;
esac
```

### Mode-Specific Configuration
```bash
# Configure based on mode
MODE=$(mulle-sourcetree mode)
if [ "$MODE" = "share" ]; then
    export SHARED_STASH=1
fi
```

## RELATIONSHIP TO FLAGS

Mode can be overridden with command-line flags:
- `--share` : Force share mode
- `--flat` : Force flat mode
- `--recurse` : Force recurse mode

## NOTES

- Shows the effective mode for current operations
- Default mode is "share"
- Mode affects recursive operations
- No options or arguments
- Safe to use in scripts

## SEE ALSO

- [mulle-sourcetree info](info.md) - Show all sourcetree information
- [mulle-sourcetree uname](uname.md) - Print platform identifier
- [mulle-sourcetree version](version.md) - Print version information
- [mulle-sourcetree --share`](list.md) - Force share mode
- [mulle-sourcetree --flat`](list.md) - Force flat mode