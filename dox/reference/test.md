# test

## SYNOPSIS

mulle-sourcetree **test** <marks> <mark>

## DESCRIPTION

Test if a mark is enabled by a set of marks. This command performs the same operation used by the ENABLES function in qualifiers for the `list` command.

The test command is useful for debugging mark logic and understanding how sourcetree evaluates mark combinations.

## PARAMETERS

- `<marks>` : Comma-separated list of marks to test against
- `<mark>` : Single mark to test for enablement

## EXAMPLES

### Basic Testing
```bash
# Test if 'build' is enabled (no negative marks)
mulle-sourcetree test "" build
# Output: YES (return code 0)

# Test if 'build' is disabled
mulle-sourcetree test "no-build" build
# Output: NO (return code 2)
```

### Platform Testing
```bash
# Test platform-specific marks
mulle-sourcetree test "only-platform-linux" "platform-linux"
# Output: YES

mulle-sourcetree test "only-platform-darwin" "platform-linux"
# Output: NO
```

### Complex Mark Combinations
```bash
# Test with multiple marks
mulle-sourcetree test "no-require,build" "require"
# Output: NO (no-require disables require)

mulle-sourcetree test "build,no-delete" "build"
# Output: YES (no negative build mark)
```

## RETURN VALUES

- **0 (YES)**: The mark is enabled by the marks
- **1 (ERROR)**: Invalid marks or syntax error
- **2 (NO)**: The mark is not enabled (disabled) by the marks

## MARK LOGIC

### Enablement Rules

1. **Positive Marks**: A mark is enabled if there are no negative versions
2. **Negative Marks**: `no-<mark>` disables the mark
3. **Only Marks**: `only-<mark>` restricts to specific cases
4. **Platform Marks**: Platform-specific restrictions apply

### Examples of Mark Logic

```bash
# no-build disables build
mulle-sourcetree test "no-build" "build"  # NO

# only-linux restricts to linux
mulle-sourcetree test "only-platform-linux" "platform-linux"  # YES
mulle-sourcetree test "only-platform-linux" "platform-darwin"  # NO

# Multiple marks are combined
mulle-sourcetree test "no-require,build" "require"  # NO
mulle-sourcetree test "no-require,build" "build"   # YES
```

## USE CASES

### Debugging Mark Issues
```bash
# Debug why a node isn't being built
mulle-sourcetree test "no-build,only-linux" "build"
# Shows: NO - explains why build is disabled
```

### Understanding Qualifier Logic
```bash
# Test qualifier components
mulle-sourcetree test "only-platform-darwin" "platform-darwin"
# Shows: YES - confirms platform match
```

### Validating Mark Combinations
```bash
# Check if marks are compatible
mulle-sourcetree test "build,no-build" "build"
# Shows: NO - conflicting marks
```

## RELATIONSHIP TO FILTER

- **test**: Simple enablement check (YES/NO)
- **filter**: Complex qualifier expressions with AND/OR/NOT

## NOTES

- Marks should be comma-separated without spaces
- Both parameters are required
- Invalid marks will cause an error (return code 1)
- Output is printed to stderr for logging
- Return codes are designed for script usage

## SEE ALSO

- [mulle-sourcetree filter](filter.md) - Test complex qualifier expressions
- [mulle-sourcetree mark](mark.md) - Add marks to nodes
- [mulle-sourcetree list](list.md) - List nodes with mark filtering
- [mulle-sourcetree walk](walk.md) - Walk nodes with qualifier filtering