# supermark

## SYNOPSIS

mulle-sourcetree **supermark** [options] <command> [arguments]

## DESCRIPTION

Manage supermarks, which are macros for combinations of marks. Supermarks provide a convenient way to work with common mark combinations. For example, the supermark 'Tool' decomposes to 'no-header,no-link'.

Supermarks are only used during input and output. The actual sourcetree algorithms work with individual marks, not supermarks.

## COMMANDS

### list
List all known supermarks.

**Examples:**
```bash
# List all available supermarks
mulle-sourcetree supermark list
```

**Sample Output:**
```
Amalgamated
Embedded
Info
Library
Local
Optional
Subproject
Tool
TreeLeaf
TreePrivate
WriteProtect
```

### compose
Try to compose supermarks from given marks.

**Examples:**
```bash
# Compose supermarks from individual marks
mulle-sourcetree supermark compose no-header,no-link
# Output: Tool

mulle-sourcetree supermark compose no-require
# Output: Optional,no-require

mulle-sourcetree supermark compose no-build,no-header,no-link,no-share
# Output: Embedded,no-build,no-header,no-link,no-share
```

### decompose
Decompose supermarks into individual marks.

**Examples:**
```bash
# Decompose a supermark
mulle-sourcetree supermark decompose Tool
# Output: no-header,no-link

mulle-sourcetree supermark decompose Library
# Output: no-build,no-delete,no-dependency,no-fs,no-update

mulle-sourcetree supermark decompose Optional
# Output: no-require
```

## SUPERMART DEFINITIONS

### Predefined Supermarks

- **Amalgamated**: `no-build,no-clobber,no-header,no-link,no-readwrite,no-share,no-share-shirk`
- **Embedded**: `no-build,no-header,no-link,no-share,no-readwrite`
- **Info**: `build,no-delete,no-share,no-update,no-header,no-link`
- **Library**: `no-build,no-delete,no-dependency,no-fs,no-update`
- **Local**: `no-delete,no-public,no-share`
- **Optional**: `no-require`
- **Subproject**: `no-delete,no-mainproject,no-share,no-update`
- **Tool**: `no-header,no-link`
- **TreeLeaf**: `no-recurse`
- **TreePrivate**: `no-bequeath`
- **WriteProtect**: `no-readwrite`

## USE CASES

### Understanding Mark Combinations
```bash
# See what marks are included in a supermark
mulle-sourcetree supermark decompose Tool
# Shows: no-header,no-link
```

### Finding Appropriate Supermarks
```bash
# Find supermarks for common scenarios
mulle-sourcetree supermark compose no-require
# Shows: Optional

mulle-sourcetree supermark compose no-header,no-link
# Shows: Tool
```

### Configuration Analysis
```bash
# Analyze what supermarks could be used
mulle-sourcetree supermark compose no-build,no-delete,no-share
# Shows possible supermark combinations
```

## RELATIONSHIP TO MARKS

Supermarks are converted to individual marks during processing:

1. **Input**: Supermarks in commands are decomposed to marks
2. **Processing**: Algorithms work with individual marks
3. **Output**: Marks can be composed back to supermarks for display

## EXTENDING SUPERMARTS

You can add custom supermarks using plugins:

```bash
# Plugin example (reference implementation in mulle-sde)
sourcetree::supermarks::add_supermarks "MyCustom"
sourcetree::supermarks::add_decomposers "my_decomposer_function"
```

## NOTES

- Supermarks are case-sensitive
- Multiple supermarks can be composed/decomposed at once
- Unknown supermarks in decompose will cause an error
- Compose may not find a perfect match for all mark combinations
- Supermarks are expanded automatically when used in commands

## SEE ALSO

- [mulle-sourcetree mark](mark.md) - Add/remove individual marks
- [mulle-sourcetree unmark](unmark.md) - Remove marks from nodes
- [mulle-sourcetree list](list.md) - List nodes with marks
- [mulle-sourcetree filter](filter.md) - Test mark filtering