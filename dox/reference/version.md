# version

## SYNOPSIS

mulle-sourcetree **version**

## DESCRIPTION

Print the version of mulle-sourcetree. The version command displays the current version number of the mulle-sourcetree executable.

## EXAMPLES

### Get Version Information
```bash
# Print mulle-sourcetree version
mulle-sourcetree version
```

### Sample Output
```
1.5.0
```

### Use in Scripts
```bash
# Check version in shell scripts
VERSION=$(mulle-sourcetree version)
echo "Using mulle-sourcetree v$VERSION"
```

### Version Comparison
```bash
# Compare versions
CURRENT=$(mulle-sourcetree version)
if [ "$CURRENT" = "1.5.0" ]; then
    echo "Running expected version"
fi
```

## VERSION FORMAT

The version follows semantic versioning:
- **Major.Minor.Patch** (e.g., 1.5.0)
- Major version changes indicate breaking changes
- Minor version changes add new features
- Patch version changes are bug fixes

## USE CASES

### Compatibility Checking
```bash
# Check if version meets requirements
VERSION=$(mulle-sourcetree version)
if [ "${VERSION%%.*}" -ge 1 ]; then
    echo "Compatible with v1.x features"
fi
```

### Bug Reporting
```bash
# Include version in bug reports
echo "mulle-sourcetree version: $(mulle-sourcetree version)"
```

### Documentation
```bash
# Document which version was used
echo "Generated with mulle-sourcetree $(mulle-sourcetree version)"
```

### CI/CD Integration
```bash
# Verify expected version in CI
EXPECTED="1.5.0"
ACTUAL=$(mulle-sourcetree version)
if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "Version mismatch: expected $EXPECTED, got $ACTUAL"
    exit 1
fi
```

## NOTES

- Returns only the version number
- No additional output or formatting
- Safe to use in scripts and automation
- No options or arguments accepted
- Version is embedded in the executable

## SEE ALSO

- [mulle-sourcetree uname](uname.md) - Print platform identifier
- [mulle-sourcetree mode](mode.md) - Print sourcetree mode
- [mulle-sourcetree info](info.md) - Show all system information