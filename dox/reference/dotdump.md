# dotdump

## SYNOPSIS

mulle-sourcetree **dotdump** [options]

## DESCRIPTION

Produces a visual representation of your sourcetree by emitting Graphviz .dot output. The dotdump command generates diagrams that show the structure and relationships of your sourcetree nodes, which can be rendered into images using Graphviz tools.

The output can be either simple node graphs with color-coded status information or detailed HTML tables containing comprehensive node metadata.

## OPTIONS

### Layout Options
- `--lr` : Use left-to-right layout (default)
- `--td` : Use top-to-bottom layout

### Output Options
- `--output-html` : Emit HTML Graphviz nodes with detailed information
- `--no-output-html` : Emit simple nodes (default)
- `--output-eval` : Show evaluated values (expanded variables)
- `--no-output-eval` : Show raw values (default)
- `--output-state` : Show filesystem state information
- `--no-output-state` : Don't show filesystem state (default)

### Data Source Options
- `--walk-config` : Traverse the config file (default)
- `--walk-db` : Walk over information contained in the database

### Filtering Options
- `-n <types>` : Node types to include (default: ALL)
- `-m <marks>` : Marks to match (e.g., build)
- `-p <permissions>` : Specify permissions filter

## EXAMPLES

### Basic Visualization
```bash
# Generate basic .dot output
mulle-sourcetree dotdump > sourcetree.dot

# Convert to PNG image
dot -Tpng sourcetree.dot -o sourcetree.png
```

### Detailed HTML Output
```bash
# Generate HTML table nodes with full details
mulle-sourcetree dotdump --output-html > sourcetree.dot
```

### Different Layouts
```bash
# Top-down layout
mulle-sourcetree dotdump --td > sourcetree.dot

# Left-right layout (default)
mulle-sourcetree dotdump --lr > sourcetree.dot
```

### Filtered Output
```bash
# Only show build nodes
mulle-sourcetree dotdump -m build > build-nodes.dot

# Only show git repositories
mulle-sourcetree dotdump -n git > git-repos.dot
```

### Database vs Config
```bash
# Visualize from database (after sync)
mulle-sourcetree dotdump --walk-db > synced.dot

# Visualize from config files
mulle-sourcetree dotdump --walk-config > config.dot
```

## OUTPUT FORMATS

### Simple Format (Default)
```
digraph sourcetree
{
   rankdir=LR;
   node [ shape="box"; style="filled" ]

   "mylib" [ shape="folder", color="limegreen", label="mylib" ]
   "zlib" [ shape="folder", color="goldenrod", label="zlib" ]
   "mylib" -> "src/mylib"
   "src/mylib" -> "src/mylib/zlib"
}
```

### HTML Format (--output-html)
```
digraph sourcetree
{
   rankdir=LR;
   node [ shape="box"; style="filled" ]

   "mylib" [ label=<
     <TABLE>
     <TR><TD BGCOLOR="blue" COLSPAN="2"><FONT COLOR="white">mylib</FONT></TD></TR>
     <TR><TD>address</TD><TD>src/mylib</TD></TR>
     <TR><TD>nodetype</TD><TD>git</TD></TR>
     <TR><TD>url</TD><TD>https://github.com/user/mylib.git</TD></TR>
     <TR><TD>marks</TD><TD>build,no-require</TD></TR>
     </TABLE>
   >, shape="none" ]
}
```

## NODE COLORS AND SHAPES

### Colors (indicate filesystem status)
- **limegreen** : Ready (synced and up-to-date)
- **darkorchid** : Database exists but not synced
- **goldenrod** : Config exists but no database
- **dodgerblue** : Regular folder/file
- **black** : Missing
- **magenta** : Shared node
- **maroon** : Shared but missing

### Shapes
- **folder** : Directory
- **note** : File
- **none** : HTML table nodes

## NODE TYPES

Different node types are color-coded:
- **git** : Blue background
- **tar/zip** : Dodger blue background
- **svn** : Coral background
- **file** : Green background
- **script** : Red background

## RENDERING

To convert .dot files to images, use Graphviz:

```bash
# PNG output
dot -Tpng sourcetree.dot -o sourcetree.png

# SVG output
dot -Tsvg sourcetree.dot -o sourcetree.svg

# PDF output
dot -Tpdf sourcetree.dot -o sourcetree.pdf
```

## USE CASES

### Documentation
```bash
# Generate architecture diagrams
mulle-sourcetree dotdump --output-html | dot -Tpng -o architecture.png
```

### Debugging
```bash
# Visualize node relationships
mulle-sourcetree dotdump --walk-db > current-state.dot
```

### Analysis
```bash
# Show only problematic nodes
mulle-sourcetree dotdump --output-state > status.dot
```

## NOTES

- Requires Graphviz (`dot` command) for image generation
- HTML output provides much more detail but larger files
- Database walking shows actual synced state
- Config walking shows intended configuration
- Layout direction affects readability for different tree structures
- Colors and shapes follow consistent conventions

## SEE ALSO

- [mulle-sourcetree list](list.md) - List nodes in text format
- [mulle-sourcetree status](status.md) - Show sourcetree status
- [mulle-sourcetree walk](walk.md) - Execute commands on nodes
- `dot` - Graphviz layout command