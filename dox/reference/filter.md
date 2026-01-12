# filter

## SYNOPSIS

mulle-sourcetree **filter** [options] <marks> <qualifier>

## DESCRIPTION

Apply a qualifier expression on a set of marks and report if it matches or not. The filter command is used to test whether marks satisfy complex filtering conditions defined by qualifier expressions.

This command is useful for:
- Testing mark matching logic
- Debugging qualifier expressions
- Validating mark combinations
- Understanding how qualifiers work with marks

## OPTIONS

- `-h`, `--help` : Show help information

## PARAMETERS

- `<marks>` : Comma-separated list of marks to test
- `<qualifier>` : Qualifier expression to evaluate against the marks

## QUALIFIER SYNTAX

The qualifier language supports complex expressions:

```
<expr>  ::= <sexpr> AND <expr>
         | <sexpr> OR <expr>
         | <sexpr>

<sexpr> ::= (<expr>)
         | NOT <sexpr>
         | ENABLES <mark>
         | MATCHES <pattern>
         | VERSION <version_spec>

<pattern> ::= <mark> '*'
            | <mark>

<mark> ::= only-[a-z-]*
        | no-[a-z-]*
        | version-[a-z-]*
```

## EXAMPLES

### Basic Filtering
```bash
# Test if marks contain 'no-foo'
mulle-sourcetree filter "no-foo,build" "ENABLES foo"
# Output: NO (because no-foo means foo is disabled)

# Test if marks match a pattern
mulle-sourcetree filter "no-foo,build" "MATCHES build"
# Output: YES
```

### Version Filtering
```bash
# Test version constraints
mulle-sourcetree filter "version-max-darwin-10.99.0" "VERSION version-max-darwin >= 11.0.0"
# Output: NO (10.99.0 is less than 11.0.0)

mulle-sourcetree filter "version-max-darwin-12.0.0" "VERSION version-max-darwin >= 11.0.0"
# Output: YES (12.0.0 is greater than 11.0.0)
```

### Complex Expressions
```bash
# Test multiple conditions
mulle-sourcetree filter "no-foo,build,only-darwin" "MATCHES build AND ENABLES darwin"
# Output: YES

# Test with NOT operator
mulle-sourcetree filter "no-foo,build" "NOT ENABLES foo"
# Output: YES
```

### Platform-Specific Filtering
```bash
# Test platform constraints
mulle-sourcetree filter "only-linux,no-windows" "MATCHES only-linux"
# Output: YES

mulle-sourcetree filter "only-linux,no-windows" "ENABLES windows"
# Output: NO
```

## RETURN VALUES

- `YES` : The marks match the qualifier expression
- `NO` : The marks do not match the qualifier expression

## USE CASES

### Debugging Mark Logic
```bash
# Debug why a node isn't being processed
mulle-sourcetree filter "no-build,only-linux" "MATCHES build"
# Output: NO - explains why build commands skip this node
```

### Testing Qualifier Expressions
```bash
# Test qualifier before using in walk command
mulle-sourcetree filter "build,no-require" "MATCHES build AND NOT ENABLES require"
# Output: YES
```

### Validating Mark Combinations
```bash
# Check if marks are compatible
mulle-sourcetree filter "only-darwin,no-linux" "ENABLES darwin"
# Output: YES

mulle-sourcetree filter "only-darwin,no-linux" "ENABLES linux"
# Output: NO
```

## NOTES

- The command returns exactly 'YES' or 'NO' (no quotes)
- Marks should be comma-separated without spaces
- Qualifier expressions are case-sensitive
- Complex expressions can use AND/OR/NOT operators
- Parentheses can be used for grouping in complex expressions
- VERSION qualifiers support comparison operators (>=, <=, ==, !=)

## SEE ALSO

- [mulle-sourcetree walk](walk.md) - Walk nodes with qualifier filtering
- [mulle-sourcetree mark](mark.md) - Add marks to nodes
- [mulle-sourcetree unmark](unmark.md) - Remove marks from nodes
- [mulle-sourcetree list](list.md) - List nodes with mark filtering