# plugin

## SYNOPSIS

mulle-sourcetree **plugin**

mulle-sourcetree **plugins**

## DESCRIPTION

List all available sourcetree plugins. The plugin command searches through configured plugin directories and displays the names of all discovered plugins.

Both `plugin` and `plugins` commands are equivalent and can be used interchangeably.

## OPTIONS

This command has no options.

## EXAMPLES

### List All Plugins
```bash
mulle-sourcetree plugin
```

or

```bash
mulle-sourcetree plugins
```

### Sample Output
```
git
tar
zip
svn
local
symlink
```

## PLUGIN SEARCH PATH

The command searches for plugins in the following locations (in order):

1. **Environment Path**: `MULLE_SOURCETREE_PLUGIN_PATH`
2. **Installation Directory**: `share/mulle-sourcetree/plugins` (relative to executable)
3. **System Paths**:
   - `/usr/local/share/mulle-sourcetree/plugins`
   - `/usr/share/mulle-sourcetree/plugins`
4. **Built-in Plugins**: `libexec/plugins` (relative to executable)

## PLUGIN DISCOVERY

Plugins are discovered by:
1. Scanning all directories in the search path
2. Finding all `.sh` files
3. Extracting the filename without extension
4. Displaying the plugin name

## USE CASES

### Check Available Plugins
```bash
# See what plugins are available
mulle-sourcetree plugin
```

### Debug Plugin Loading
```bash
# Verify plugins are found in expected locations
mulle-sourcetree plugin
```

### Custom Plugin Development
```bash
# Check if custom plugin is detected
mulle-sourcetree plugin
```

## ENVIRONMENT VARIABLES

- `MULLE_SOURCETREE_PLUGIN_PATH`: Colon-separated list of additional plugin directories

## NOTES

- Lists plugin names only, not full paths
- Shows all discovered plugins, not just loaded ones
- No distinction between built-in and external plugins
- Plugins are loaded on-demand when needed
- Empty output means no plugins were found

## SEE ALSO

- [mulle-sourcetree list](list.md) - List nodes in the sourcetree
- [mulle-sourcetree status](status.md) - Show sourcetree status
- [mulle-sourcetree walk](walk.md) - Execute commands on nodes