# mulle-sourcetree Bash Completion Usage Guide

## Installation

To enable the completion, source the script in your shell:

```bash
source mulle-sourcetree-completion.sh
```

To make it permanent, add to your `~/.bashrc`:

```bash
# mulle-sourcetree completion
if [ -f /path/to/mulle-sourcetree-completion.sh ]; then
    source /path/to/mulle-sourcetree-completion.sh
fi
```

## Features

### 1. Command Completion

Press TAB after `mulle-sourcetree` to see all available commands:

```bash
mulle-sourcetree <TAB>
```

Shows: add, clean, config, craftorder, dbstatus, desecrate, dotdump, duplicate, editor, etc.

### 2. Option Completion

Press TAB after any command to see its options:

```bash
mulle-sourcetree add --<TAB>
```

Shows: --address, --branch, --fetchoptions, --marks, --tag, --nodetype, --url, --userinfo, --if-missing

### 3. Smart Node Address Completion

When a command expects a node address, TAB completes from your sourcetree:

```bash
mulle-sourcetree mark <TAB>
```

Shows: All node addresses from your current sourcetree

### 4. Mark Completion

When marks are expected, TAB shows known marks:

```bash
mulle-sourcetree mark mynode <TAB>
```

Shows: no-build, no-link, no-require, build, link, require, etc.

### 5. Subcommand Completion

For commands with subcommands:

```bash
mulle-sourcetree config <TAB>
```

Shows: list, copy, remove, status

### 6. Context-Aware Value Completion

**Node Types:**
```bash
mulle-sourcetree add --nodetype <TAB>
```
Shows: git, tar, zip, local, none, symlink, comment

**URL Protocols:**
```bash
mulle-sourcetree add --url <TAB>
```
Shows: https://, http://, file://

**Dedupe Modes:**
```bash
mulle-sourcetree list --dedupe-mode <TAB>
```
Shows: address, address-filename, address-marks-filename, linkorder, nodeline, none, etc.

## Examples

### Adding a Dependency

```bash
# Start typing the command
mulle-sourcetree add <TAB>
# Shows: --address, --branch, etc.

# Complete the nodetype
mulle-sourcetree add --nodetype <TAB>
# Shows: git, tar, zip, local, none, symlink, comment

# Complete the URL
mulle-sourcetree add --url <TAB>
# Shows: https://, http://, file://
```

### Marking a Node

```bash
# Complete node address
mulle-sourcetree mark <TAB>
# Shows: curl, zlib, openssl (your dependencies)

# Complete mark
mulle-sourcetree mark curl <TAB>
# Shows: no-build, no-link, build, link, etc.
```

### Listing with Options

```bash
mulle-sourcetree list --<TAB>
# Shows all list options

mulle-sourcetree list --dedupe-mode <TAB>
# Shows: address, filename, nodeline, none, etc.
```

### Getting Node Properties

```bash
# First argument: node address
mulle-sourcetree get <TAB>
# Shows: curl, zlib, openssl

# Second argument: property key
mulle-sourcetree get curl <TAB>
# Shows: all, address, branch, fetchoptions, marks, nodetype, tag, url, userinfo, uuid
```

## Performance

The completion script uses intelligent caching:

- Commands are fetched once and cached
- Node addresses are cached until shell restart
- Known marks are cached
- Subsequent completions are instant

To clear the cache (if sourcetree changes), restart your shell or run:

```bash
unset __mulle_sourcetree_cached_commands
unset __mulle_sourcetree_cached_addresses
unset __mulle_sourcetree_cached_marks
```

## Troubleshooting

**Completion not working?**

1. Ensure bash-completion is installed:
   ```bash
   apt-get install bash-completion  # Debian/Ubuntu
   brew install bash-completion@2   # macOS
   ```

2. Source the script:
   ```bash
   source mulle-sourcetree-completion.sh
   ```

3. Verify registration:
   ```bash
   complete -p mulle-sourcetree
   ```
   Should show: `complete -F _mulle_sourcetree_complete mulle-sourcetree`

**Commands not showing?**

The completion falls back to a static list if `mulle-sourcetree commands` fails.
This ensures completion works even in directories without a sourcetree.

**Addresses not completing?**

Node address completion only works when you're in a directory with a valid sourcetree.
Outside a sourcetree, it gracefully shows no suggestions.
