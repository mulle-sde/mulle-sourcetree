# unmark

## SYNOPSIS

mulle-sourcetree **unmark** [options] <node> <mark>

## DESCRIPTION

Remove a negative mark from a node. A node stores only marks prefixed by either "no-" or "only-". All positive marks are implicit set. This command effectively removes negative marks by applying their positive equivalents.

## OPTIONS

- `--regex` : use regular expression to find node address
- `--extended-mark` : allow the use of non-predefined marks

## EXAMPLES

Remove a negative mark from a node:
```bash
mulle-sourcetree unmark src/mylib no-build
```

Remove multiple marks:
```bash
mulle-sourcetree unmark src/mylib "no-build,no-require"
```

Use regex to match multiple nodes:
```bash
mulle-sourcetree unmark --regex "src/lib.*" no-update
```

Remove extended marks:
```bash
mulle-sourcetree unmark --extended-mark src/mylib custom-mark
```

## HOW IT WORKS

The unmark command works by:

1. **Converting the mark**: Transforms the input mark to its negative form
   - `build` → `no-build`
   - `require` → `no-require`
   - `no-build` → `build` (removes the negative mark)

2. **Applying as positive**: The converted mark is applied as a positive mark, which removes any existing negative mark

3. **Supermark decomposition**: If supermarks are used, they are decomposed into individual marks before processing

## COMMON MARKS TO REMOVE

- `no-build` : Allow node to be built
- `no-delete` : Allow node to be deleted or moved
- `no-descend` : Allow recursive operations on node
- `no-require` : Make node optional
- `no-set` : Allow node properties to be changed
- `no-share` : Prevent sharing with subtree nodes
- `no-update` : Allow node to be updated

## NOTES

- Only removes negative marks that are explicitly stored
- Positive marks are implicit and cannot be "unmarked"
- Use `list` command to see current marks on nodes
- Extended marks require the `--extended-mark` option
- Regex matching requires the `--regex` option
- Supermarks are automatically decomposed

## SEE ALSO

- [mulle-sourcetree mark](mark.md) - Add marks to nodes
- [mulle-sourcetree list](list.md) - List nodes with their marks
- [mulle-sourcetree knownmarks](knownmarks.md) - List all known marks
- [mulle-sourcetree set](set.md) - Change node properties