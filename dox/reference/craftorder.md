# craftorder

## SYNOPSIS

mulle-sourcetree **craftorder** [options]

## DESCRIPTION

Generate a build order for sourcetree nodes marked for building. This command outputs the addresses of all nodes that should be built, in the correct dependency order. It's designed for integration with build systems that need to compile dependencies before dependent projects.

The command respects the sourcetree's dependency relationships and ensures that dependencies are built before the projects that depend on them.

## OPTIONS

### Output Formatting
- `--output-eval` : Expand environment variables in output
- `--output-no-eval` : Don't expand variables (default)
- `--output-no-marks` : Suppress marks in output
- `--output-marks` : Include marks in output (default)
- `--output-absolute` : Use absolute paths
- `--output-relative` : Use relative paths (default)

### Processing Control
- `--bequeath` : Inherit from nodes marked no-bequeath (default)
- `--no-bequeath` : Don't inherit from no-bequeath nodes
- `--backwards` : Process in reverse dependency order
- `--forwards` : Process in forward dependency order (default)

### Advanced Options
- `--callback <function>` : Apply callback function to each node
- `--output-raw-userinfo` : Include raw userinfo in output
- `--no-print-env` : Suppress environment variable output

## EXAMPLES

### Basic Usage

Get standard build order:
```bash
mulle-sourcetree craftorder
```

Output with marks suppressed:
```bash
mulle-sourcetree craftorder --output-no-marks
```

### Build System Integration

Use in Makefile:
```makefile
.PHONY: build-deps
build-deps:
	@mulle-sourcetree craftorder --output-no-marks | while read dep; do \
		echo "Building $$dep..."; \
		( cd "$$dep" && make ) || exit 1; \
	done
```

Use in shell script:
```bash
#!/bin/bash
mulle-sourcetree craftorder --output-no-marks | while IFS= read -r address; do
    echo "Building $address..."
    (cd "$address" && make) || {
        echo "Failed to build $address"
        exit 1
    }
done
```

### Advanced Output Control

With variable expansion:
```bash
mulle-sourcetree craftorder --output-eval
```

Reverse dependency order:
```bash
mulle-sourcetree craftorder --backwards
```

Absolute paths:
```bash
mulle-sourcetree craftorder --output-absolute
```

### Filtering and Processing

Use callback for custom processing:
```bash
mulle-sourcetree craftorder --callback "echo Processing: \$NODE_ADDRESS"
```

With raw userinfo:
```bash
mulle-sourcetree craftorder --output-raw-userinfo
```

## OUTPUT FORMAT

### Standard Format (with marks)
```
path/to/dependency;marks
path/to/project;marks
```

### Clean Format (without marks)
```
path/to/dependency
path/to/project
```

### Example Output
```
src/zlib;zlib
src/expat;expat
src/openssl;openssl,no-require
src/curl;curl,build
src/mylib;mylib,build
```

## DEPENDENCY RESOLUTION ALGORITHM

### Phase 1: Collection
- Walks sourcetree in post-order traversal
- Collects all nodes marked for building
- Applies mark filtering and inheritance rules

### Phase 2: Augmentation
- Breadth-first traversal to collect marks
- Merges marks from related nodes
- Resolves supermarks to individual marks

### Phase 3: Ordering
- Topological sort based on dependencies
- Ensures dependencies are built before dependents
- Handles circular dependency detection

### Phase 4: Processing
- Applies callback functions if specified
- Removes amalgamated entries
- Formats output according to options

## MARK FILTERING LOGIC

### Inclusion Criteria
Nodes are included in craftorder if they:
- Have explicit "build" mark, OR
- Don't have "no-build" mark (implicit build), AND
- Don't have "share-shirk" mark (unless amalgamated), AND
- Are not marked as "no-bequeath" (unless --bequeath is used)

### Mark Resolution
- **build**: Explicitly marked for building
- **no-build**: Excluded from building
- **share-shirk**: Excluded from shared builds
- **no-bequeath**: Not inherited by subtrees

## USE CASES

### Build System Integration

**CMake Integration:**
```cmake
execute_process(
    COMMAND ${MULLE_SOURCETREE} craftorder --output-no-marks
    OUTPUT_VARIABLE BUILD_ORDER
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
string(REPLACE "\n" ";" BUILD_LIST "${BUILD_ORDER}")
foreach(DEP ${BUILD_LIST})
    add_subdirectory(${DEP})
endforeach()
```

**Make Integration:**
```makefile
DEPS := $(shell ${MULLE_SOURCETREE} craftorder --output-no-marks)

.PHONY: deps
deps: $(DEPS)

$(DEPS):
	@echo "Building $@..."
	@$(MAKE) -C $@ all
```

### CI/CD Pipelines

**GitHub Actions:**
```yaml
- name: Build Dependencies
  run: |
    for dep in $(${MULLE_SOURCETREE} craftorder --output-no-marks); do
      echo "Building $dep..."
      cd $dep
      make
      cd -
    done
```

**Jenkins Pipeline:**
```groovy
def buildOrder = sh(
    script: '${MULLE_SOURCETREE} craftorder --output-no-marks',
    returnStdout: true
).trim().split('\n')

for (dep in buildOrder) {
    dir(dep) {
        sh 'make'
    }
}
```

### Development Workflows

**Parallel Building:**
```bash
mulle-sourcetree craftorder --output-no-marks | \
    xargs -n1 -P$(nproc) -I{} bash -c 'cd {} && make'
```

**Dependency Analysis:**
```bash
# Count buildable dependencies
mulle-sourcetree craftorder | wc -l

# Show build order with marks
mulle-sourcetree craftorder | nl
```

## TROUBLESHOOTING

### Common Issues

**Empty output:**
```bash
# Check for buildable nodes
mulle-sourcetree list --marks build

# Check for no-build marks
mulle-sourcetree list --marks no-build
```

**Wrong order:**
```bash
# Verify dependency relationships
mulle-sourcetree list --output-uuid

# Check for circular dependencies
mulle-sourcetree craftorder 2>&1 | grep -i "circular"
```

**Missing nodes:**
```bash
# Check node marks
mulle-sourcetree get src/missing marks

# Add build mark if needed
mulle-sourcetree mark src/missing build
```

### Validation

Verify build order:
```bash
# Check if all dependencies exist
mulle-sourcetree craftorder --output-no-marks | while read dep; do
    [ -d "$dep" ] || echo "Missing: $dep"
done

# Validate marks
mulle-sourcetree craftorder | while IFS=';' read address marks; do
    echo "$address: $marks"
done
```

## TECHNICAL DETAILS

### Performance Characteristics
- **Time Complexity**: O(n log n) for topological sort
- **Space Complexity**: O(n) for node storage
- **I/O Operations**: Minimal (reads config only)
- **Memory Usage**: Scales linearly with node count

### Edge Cases Handled
- **Circular Dependencies**: Detected and reported
- **Missing Dependencies**: Validated before output
- **Shared Dependencies**: Correctly ordered
- **Amalgamated Nodes**: Properly deduplicated

### Integration Points
- **Callback System**: Extensible processing pipeline
- **Environment Variables**: Platform-aware building
- **Mark System**: Flexible inclusion criteria
- **Path Resolution**: Absolute/relative path support

## ENVIRONMENT VARIABLES

- `MULLE_SOURCETREE_MODE` : Affects traversal behavior

## NOTES

- Output order ensures correct build dependencies
- Respects sourcetree mode (flat/share/recurse)
- Handles shared dependencies without duplication
- Supports custom processing via callbacks
- Variables can be expanded for dynamic paths
- Amalgamated entries are automatically deduplicated
- Backwards mode useful for cleanup operations

## SEE ALSO

- [mulle-sourcetree list](list.md) - List nodes with mark information
- [mulle-sourcetree mark](mark.md) - Manage build marks on nodes
- [mulle-sourcetree sync](sync.md) - Fetch dependencies before building
- [mulle-sourcetree walk](walk.md) - Custom node traversal
- [mulle-sourcetree filter](filter.md) - Test mark filtering logic