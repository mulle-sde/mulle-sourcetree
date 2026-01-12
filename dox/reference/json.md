# json

## SYNOPSIS

mulle-sourcetree **json** [options]

## DESCRIPTION

Output the sourcetree configuration as JSON. This command provides a machine-readable representation of the sourcetree nodes, suitable for processing by other tools and scripts.

The JSON output can include expanded variables, raw encoded values, and supports filtering to show only specific types of nodes.

## OPTIONS

### Output Control
- `--expand` : Expand environment variables in URLs, branches, and tags
- `--no-expand` : Don't expand variables (default)
- `--raw` : Keep userinfo as base64 encoded instead of decoding
- `--no-raw` : Decode userinfo from base64 (default)

### Filtering
- `--marks <value>` : Filter nodes by marks (e.g., "build", "no-require")
- `--nodetype <value>` : Filter nodes by type (e.g., "git", "tar", "local")
- `--qualifier <value>` : Apply qualifier filtering (same as `list` command)

## EXAMPLES

### Basic Usage

Output complete sourcetree as JSON:
```bash
mulle-sourcetree json
```

Expand all variables in output:
```bash
mulle-sourcetree json --expand
```

Keep userinfo encoded:
```bash
mulle-sourcetree json --raw
```

### Filtering Examples

Show only Git repositories:
```bash
mulle-sourcetree json --nodetype git
```

Show only buildable nodes:
```bash
mulle-sourcetree json --marks build
```

Show nodes without expansion:
```bash
mulle-sourcetree json --no-expand --raw
```

### Advanced Filtering

Combine multiple filters:
```bash
mulle-sourcetree json --nodetype git --marks "no-require" --expand
```

Use qualifier syntax:
```bash
mulle-sourcetree json --qualifier "ENABLES(build)"
```

## OUTPUT FORMAT

The output is a JSON array containing one object per node:

```json
[
  {
    "address": "src/mylib",
    "branch": "${MYLIB_BRANCH:-main}",
    "fetchoptions": "",
    "marks": "no-require,build",
    "nodetype": "git",
    "raw_userinfo": "base64:YWxpYXNlcz1SZWxlYXNlOmN1cmwsRGVidWc6Y3VybC1kCg==",
    "tag": "${MYLIB_TAG:-v1.0.0}",
    "url": "${MYLIB_URL:-https://github.com/user/mylib.git}",
    "userinfo": {
      "aliases": "Release:curl,Debug:curl-d"
    },
    "uuid": "78cfb19c-00ec-4df6-9c13-00a6aa134000"
  }
]
```

### Field Details

**Core Fields:**
- `address` : Node address in the project filesystem
- `nodetype` : Type of node (git, tar, zip, local, none, comment, symlink)
- `uuid` : Unique identifier for the node

**Version Control Fields:**
- `url` : Repository or archive URL
- `branch` : Git branch name
- `tag` : Git tag name

**Configuration Fields:**
- `marks` : Comma-separated list of sourcetree marks
- `fetchoptions` : Options passed to mulle-fetch
- `userinfo` : Decoded authentication information
- `raw_userinfo` : Base64-encoded authentication data

### Variable Expansion

When `--expand` is used, variables in URLs, branches, and tags are resolved:

**Without expansion:**
```json
{
  "url": "${MYLIB_URL:-https://github.com/user/mylib.git}",
  "branch": "${MYLIB_BRANCH:-main}",
  "tag": "${MYLIB_TAG:-v1.0.0}"
}
```

**With expansion:**
```json
{
  "url": "https://github.com/user/mylib.git",
  "branch": "main",
  "tag": "v1.0.0"
}
```

## USE CASES

### Tool Integration

Process sourcetree data in scripts:
```bash
# Count Git repositories
mulle-sourcetree json --nodetype git | jq '. | length'

# Extract all URLs
mulle-sourcetree json --expand | jq -r '.[].url'

# Find nodes with specific marks
mulle-sourcetree json | jq '.[] | select(.marks | contains("build")) | .address'
```

### Configuration Analysis

Analyze sourcetree structure:
```bash
# Show mark distribution
mulle-sourcetree json | jq -r '.[].marks' | tr ',' '\n' | sort | uniq -c

# Find duplicate URLs
mulle-sourcetree json --expand | jq -r '.[].url' | sort | uniq -d
```

### CI/CD Integration

Use in automated pipelines:
```bash
# Export dependency list for CI
mulle-sourcetree json --expand --marks build > dependencies.json

# Validate configuration
mulle-sourcetree json | jq 'all(.address; . != "")' || echo "Invalid addresses found"
```

### Documentation Generation

Generate reports:
```bash
# Create dependency report
mulle-sourcetree json --expand | jq -r '
  .[] | select(.nodetype == "git") |
  "- \(.address): \(.url)@\(.branch)"
' > DEPENDENCIES.md
```

## TROUBLESHOOTING

### Common Issues

**Empty output:**
```bash
# Check if sourcetree exists
mulle-sourcetree config status

# Verify config file exists
ls -la $(mulle-sourcetree etc-dir)/config
```

**Invalid JSON:**
```bash
# Use --raw to avoid decoding issues
mulle-sourcetree json --raw

# Check for malformed userinfo
mulle-sourcetree json 2>&1 | head -20
```

**Missing fields:**
```bash
# Some fields are optional and only included when non-empty
mulle-sourcetree json | jq '.[] | keys'
```

### Validation

Verify JSON structure:
```bash
# Check JSON validity
mulle-sourcetree json | jq . >/dev/null && echo "Valid JSON"

# Count total nodes
mulle-sourcetree json | jq '. | length'
```

## TECHNICAL DETAILS

### Processing Pipeline

1. **Load Configuration**: Read sourcetree config file
2. **Apply Filters**: Filter nodes by marks, nodetype, qualifier
3. **Variable Expansion**: Expand environment variables (if --expand)
4. **Userinfo Decoding**: Decode base64 userinfo (unless --raw)
5. **JSON Serialization**: Convert to JSON format
6. **Output**: Write to stdout

### Data Types

- **Strings**: All field values are strings
- **Optional Fields**: Empty fields are omitted from output
- **Arrays**: Output is always a JSON array
- **Encoding**: UTF-8 with proper escaping

### Performance Notes

- **Memory Usage**: Loads entire config into memory
- **Filtering**: Applied before JSON serialization
- **Expansion**: Variable expansion can be expensive for large configs
- **Output Size**: JSON can be significantly larger than config files

## ENVIRONMENT VARIABLES

- `MULLE_SOURCETREE_CONFIG_NAME` : Configuration file to read
- `MULLE_SOURCETREE_CONFIG_DIR` : Directory containing config files

## NOTES

- Output is always a flat array (no hierarchical structure)
- Empty fields are omitted to reduce output size
- Filtering uses the same logic as the `list` command
- JSON is valid and can be parsed by any standard JSON parser
- Use `--expand` for human-readable output, `--raw` for machine processing
- Large sourcetrees may produce significant output

## SEE ALSO

- [mulle-sourcetree list](list.md) - Human-readable node listing
- [mulle-sourcetree get](get.md) - Retrieve individual node properties
- [mulle-sourcetree info](info.md) - Display sourcetree metadata
- [mulle-sourcetree status](status.md) - Show synchronization status
- `jq` - JSON processing tool