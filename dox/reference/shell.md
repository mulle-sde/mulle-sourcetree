# mulle-sourcetree shell

Start an interactive shell with mulle-sourcetree environment configured.

## Synopsis

```bash
mulle-sourcetree shell [options] [command]
```

## Description

The `shell` command starts an interactive shell session with the mulle-sourcetree environment fully configured. This provides access to all mulle-sourcetree commands and environment variables in an interactive session, making it easier to work with sourcetree operations.

## Options

- `--bash` : Start bash shell (default on Linux)
- `--zsh` : Start zsh shell
- `--fish` : Start fish shell
- `--sh` : Start POSIX shell
- `--command <cmd>` : Execute command and exit
- `--no-rc` : Don't load shell configuration files
- `--quiet` : Suppress startup messages
- `--help` : Show help and exit

## Examples

### Basic Usage
```bash
# Start interactive shell
mulle-sourcetree shell

# Start specific shell
mulle-sourcetree shell --bash
mulle-sourcetree shell --zsh

# Execute command and exit
mulle-sourcetree shell --command "mulle-sourcetree status"
```

### Shell Configuration
```bash
# Start shell without configuration
mulle-sourcetree shell --no-rc

# Start quiet shell
mulle-sourcetree shell --quiet

# Show available shells
mulle-sourcetree shell --list-shells
```

### Integration with Scripts
```bash
# Use in automation scripts
mulle-sourcetree shell --command "mulle-sourcetree sync && make"

# Chain commands
mulle-sourcetree shell --command "
  mulle-sourcetree list
  mulle-sourcetree status
  echo 'Done'
"

# Use with environment variables
mulle-sourcetree shell --command "echo \$MULLE_SOURCETREE_VAR"
```

## Shell Environment

### Environment Variables
The shell session includes these mulle-sourcetree specific variables:

- **MULLE_SOURCETREE_CONFIG_DIR**: Path to configuration directory
- **MULLE_SOURCETREE_PROJECT_DIR**: Path to project root
- **MULLE_SOURCETREE_VAR_DIR**: Path to variable data directory
- **MULLE_SOURCETREE_SHARE_DIR**: Path to shared resources
- **MULLE_SOURCETREE_LIBEXEC_DIR**: Path to internal executables

### PATH Modifications
```bash
# mulle-sourcetree binaries are in PATH
which mulle-sourcetree  # Should find the binary

# Internal tools may be available
which mulle-sourcetree-helper  # If in libexec

# Project-specific scripts
which project-script  # If in project bin/
```

### Shell Configuration
```bash
# Custom prompt showing sourcetree status
export PS1="(mulle-sourcetree) $PS1"

# Aliases for common commands
alias st='mulle-sourcetree status'
alias sl='mulle-sourcetree list'
alias sa='mulle-sourcetree add'

# Auto-completion (if available)
source /path/to/mulle-sourcetree-completion.bash
```

## Use Cases

### Interactive Development
```bash
# Start development shell
mulle-sourcetree shell

# Inside shell, use short commands
st      # status
sl      # list
sa url  # add dependency

# Exit shell
exit
```

### Batch Operations
```bash
# Execute multiple commands
mulle-sourcetree shell --command "
  mulle-sourcetree add https://github.com/lib1
  mulle-sourcetree add https://github.com/lib2
  mulle-sourcetree sync
  mulle-sourcetree status
"
```

### Debugging Sessions
```bash
# Start shell for debugging
mulle-sourcetree shell

# Check environment
env | grep MULLE

# Test commands interactively
mulle-sourcetree status --verbose
mulle-sourcetree list --debug

# Exit when done
exit
```

## Shell Types

### Bash Shell
```bash
# Default on Linux
mulle-sourcetree shell --bash

# Features in bash:
# - Command history
# - Tab completion
# - Job control
# - Scripting capabilities
```

### Zsh Shell
```bash
# Advanced shell with features
mulle-sourcetree shell --zsh

# Additional features:
# - Better completion
# - Spelling correction
# - Theming support
# - Plugin system
```

### Fish Shell
```bash
# User-friendly shell
mulle-sourcetree shell --fish

# Features:
# - Syntax highlighting
# - Autosuggestions
# - Web-based configuration
# - Friendly error messages
```

### POSIX Shell
```bash
# Minimal shell for compatibility
mulle-sourcetree shell --sh

# Features:
# - POSIX compliance
# - Minimal resource usage
# - Broad compatibility
```

## Integration with Other Commands

### With status
```bash
# Show status in shell context
mulle-sourcetree shell --command "mulle-sourcetree status"

# Interactive status checking
mulle-sourcetree shell
$ mulle-sourcetree status --watch  # Monitor changes
```

### With config
```bash
# Configure in shell
mulle-sourcetree shell --command "mulle-sourcetree config set key value"

# Interactive configuration
mulle-sourcetree shell
$ mulle-sourcetree config list
$ mulle-sourcetree config set editor vim
```

### With sync
```bash
# Sync in shell environment
mulle-sourcetree shell --command "mulle-sourcetree sync --verbose"

# Interactive sync with monitoring
mulle-sourcetree shell
$ mulle-sourcetree sync --progress
$ watch mulle-sourcetree status
```

## Advanced Features

### Custom Shell Configuration
```bash
# Load custom configuration
mulle-sourcetree shell --rcfile ~/.mulle-sourcetree-shellrc

# Set custom environment
mulle-sourcetree shell --env VAR=value

# Use custom shell options
mulle-sourcetree shell --shell-option "-O vi"
```

### Session Management
```bash
# Save shell session
mulle-sourcetree shell --save-session session-name

# Restore previous session
mulle-sourcetree shell --restore-session session-name

# List saved sessions
mulle-sourcetree shell --list-sessions
```

### Remote Shell Access
```bash
# Start shell on remote system
ssh user@host "mulle-sourcetree shell --command 'mulle-sourcetree status'"

# Use with tmux/screen
mulle-sourcetree shell --command "tmux new-session -s mulle-dev"

# Remote development
mulle-sourcetree shell --remote user@host
```

## Troubleshooting

### Common Issues
```bash
# Shell not found
mulle-sourcetree shell --list-shells  # See available shells

# Environment not configured
mulle-sourcetree shell --debug-env

# Command not found in shell
which mulle-sourcetree  # Check PATH
```

### Configuration Issues
```bash
# Shell configuration problems
mulle-sourcetree shell --no-rc  # Skip configuration

# Environment variable issues
mulle-sourcetree shell --debug-env

# PATH problems
mulle-sourcetree shell --show-path
```

### Compatibility Issues
```bash
# Shell compatibility problems
mulle-sourcetree shell --sh  # Use POSIX shell

# Feature not available
mulle-sourcetree shell --check-features

# Version conflicts
mulle-sourcetree shell --version-check
```

## Integration with Development Workflow

### IDE Integration
```bash
# Configure IDE terminal
# In VS Code settings.json:
{
  "terminal.integrated.shell.linux": "/usr/bin/bash",
  "terminal.integrated.shellArgs.linux": ["-c", "mulle-sourcetree shell"]
}

# Use with editor commands
# In vim/init.vim:
command! MulleShell :terminal mulle-sourcetree shell
```

### Build System Integration
```bash
# Use in Makefiles
.PHONY: shell
shell:
	mulle-sourcetree shell

# Integration with build scripts
build.sh:
	#!/bin/bash
	mulle-sourcetree shell --command "
		mulle-sourcetree sync
		make
		make test
	"
```

### CI/CD Integration
```bash
# Use in CI scripts
- name: Setup mulle-sourcetree
  run: |
    mulle-sourcetree shell --command "
      mulle-sourcetree status
      mulle-sourcetree sync
    "

# Docker integration
FROM mulle-sourcetree-base
RUN mulle-sourcetree shell --command "mulle-sourcetree init"
```

## Performance Considerations

- Shell startup time varies by shell type
- Use `--quiet` for faster startup in scripts
- Consider shell features vs. performance trade-offs
- Cache shell configuration for faster startup

## Security Considerations

### Shell Security
```bash
# Use restricted shell
mulle-sourcetree shell --restricted

# Validate shell environment
mulle-sourcetree shell --secure

# Audit shell commands
mulle-sourcetree shell --audit
```

### Environment Security
```bash
# Sanitize environment
mulle-sourcetree shell --clean-env

# Check for malicious environment
mulle-sourcetree shell --env-check

# Secure shell options
mulle-sourcetree shell --secure-options
```

## Notes

- Shell inherits current environment
- mulle-sourcetree commands are available in PATH
- Environment variables are set automatically
- Shell configuration can be customized

## See Also

- [`status`](status.md) - Show project status
- [`config`](config.md) - Manage configuration
- [`sync`](sync.md) - Synchronize sourcetree
- [`tool-env`](tool-env.md) - Show tool environment