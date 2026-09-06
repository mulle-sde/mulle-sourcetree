# mulle-sourcetree Library Documentation for AI
<!-- Keywords: sourcetree, dependency, node, marks, fetch, sync, database -->

## 1. Introduction & Purpose

`mulle-sourcetree` is a **bash/shell** tool (not a C library) that maintains the
*source tree* of a project: the ordered, qualified list of external dependencies
(git/svn repositories, tar/zip archives, local subprojects, symlinks) and local
nodes that make up a mulle-sde project. Its companion generators
(`mulle-sourcetree-to-c`, `mulle-sourcetree-to-cmake`) turn that tree into
`#include`/build files.

It solves the problem of composing a project freely from many repositories and
archives across platforms (Android, BSDs, Linux, macOS, SunOS, Windows), in the
correct build order, inheriting dependencies from dependency projects, and
overriding upstream sources with local ones.

High-level features:

- Maintain local (file/folder) or external tree nodes (archive, repository).
- Inherit sourcetrees from dependencies and share nodes between projects.
- Override external dependencies via symlinks of local projects.
- Emit build sub-projects (craftorder) in the correct order.
- Create platform-specific `#ifdef` and `#include` statements.
- Acquire platform-specific dependencies.
- Backed by a persistent on-disk *database* created during `sync`.

It is the dependency-composition layer of the mulle-sde toolchain; it does not
build anything itself (that is `mulle-craft`/`mulle-make`) and depends on
`mulle-bashfunctions` for its framework and `mulle-fetch` for fetch/update.

## 2. Key Concepts & Design Philosophy

- **Sourcetree.** An ordered list of *nodes*. A node is a named, typed entry
  with a URL (for remotes) and a place in the project filesystem (its
  *address*).
- **Node fields.** A node has up to nine fields: `address`, `branch`,
  `fetchoptions`, `marks`, `nodetype`, `tag`, `url`, `userinfo`, `uuid`.
  Only `address` and `nodetype` are required. `uuid` is an internal identifier
  that must not be copied or edited.
- **Nodetypes.** `git`, `svn`, `local`, `symlink`, `tar`, `zip`. Each type
  uses/ignores the optional fields differently (e.g. `tar`/`zip` treat `tag`
  through URL expansion).
- **Marks.** Nodes are decorated with marks that drive behaviour. The default
  is that a node carries *all* marks; marks are removed by prefixing a mark with
  `no-` (e.g. `no-delete`), and a few marks are opt-in and prefixed `only-`.
  Marks are divided into families used by `sync`/`clean` (`bequeath`,
  `descend`, `fs`, `require`, `require-os-<u>`, `set`, `share`, `update`,
  `delete`), by `mulle-sourcetree-to-c` (`dependency`, `header`, `import`,
  `public`, `require`, ...), and by `mulle-sourcetree-to-cmake`
  (`cmake-add`, `static-link`, `dynamic-link`, `all-load`, ...).
- **Database.** `sync` materializes the (possibly inherited) logical tree into
  a persistent database on disk. `dbstatus`, `status`, `df`, `isuptodate`, etc.
  query that database. `reset` clears it so the next `sync` is forced.
- **Sourcetree modes.** Operations run in one of three modes: `--flat` (only
  the local tree), `--recurse` (also descend into subtrees), `--share`
  (recurse, but nodes with identical URLs are fetched only once). `--share`
  is the default and recommended.
- **Config files & deferral.** The tree lives in configuration files under
  `.mulle/etc/sourcetree/` (config name `config` by default, plus
  platform-specific `config.<os>` and dependency-specific
  `config.<depname>`). The tool searches upward for an enclosing source tree
  unless deferral is disabled with `-N`/`--no-defer`.
- **Environment-tagged fields.** `nodetype`, `branch`, `tag`, `url`,
  `fetchinfo` are *expandable*: environment variables affect their contents
  (order: `branch`/`tag`, then `url`, then `fetchinfo`). Expanded values are
  exported as `MULLE_BRANCH`, `MULLE_TAG`, `MULLE_TAG_OR_BRANCH`, `MULLE_URL`.
  This allows overriding versions and hosts of inherited dependencies.

## 3. Core API & Data Structures

There are no C headers; the public interface is (a) the `mulle-sourcetree`
command-line dispatcher, and (b) the namespaced bash functions in each
`src/*.sh` module. Below, function names are copied verbatim from the sources.
Shell functions receive arguments positionally (`$1`, `$2`, ...) and, by
convention in this codebase, return *output* through the global variable `RVAL`.

### 3.1. Entry point: `mulle-sourcetree` (the `sourcetree` namespace)

The main shell script defines `sourcetree::main()`, `sourcetree::usage()`, and
`sourcetree::print_commands()`, then dispatches on the first non-flag argument.
It includes the appropriate `sourcetree::<module>` and invokes that module's
`*_main` function.

**Flags (global):** `-N|--no-defer`, `-R|--defer-root`, `-T|--defer-this`,
`-P|--defer-parent`, `--virtual-root`, `--flat`, `--recurse`, `--share`,
`--mode <mode>`, `--config-dir <dir>`, `--config-name <name>`, `--config-file
<path>`, `-d|--directory <dir>`, `--no-are`, `-f|--force`, `-lxx`, `-lxw`.

**Commands (from `mulle-sourcetree commands`, i.e. the standard API):**
`add`, `clean`, `config`, `craftorder`, `dbstatus`, `desecrate`, `dotdump`,
`duplicate`, `etc-dir`, `eval-add`, `filter`, `fix`, `get`, `info`, `json`,
`knownmarks`, `libexec-dir`, `list`, `mark`, `move`, `plugin`, `project-dir`,
`pwd`, `rcopy`, `remove`, `rename`, `rename-marks`, `reset`, `reuuid`,
`rewrite`, `set`, `sourcetree-dir`, `star-search`, `status`, `supermark`,
`sync`, `test`, `touch`, `uname`, `unmark`, `var-dir`, `version`, `wrap`.
Additional aliases: `update` (=`sync`), `stash-dir`/`share-dir`, `mode`,
`editor`, `tool-env`, `shell`.

**Primary (default) commands:**
- `add [--url <u>] [--nodetype <t>] [--branch|--tag] [--marks <m>]
  [--userinfo] <address>` — append a node to the current sourcetree.
- `remove <address>` — remove a node.
- `set <address> [--url|--nodetype|--branch|--tag|--fetchoptions|--userinfo]` —
  change node properties.
- `get <address>` — print a node's properties.
- `mark <address> <mark>` / `unmark <address> <mark>` — toggle marks.
- `move <address> <top|bottom|u|d|N|before:X|after:X>` — reorder nodes.
- `list [-r|--recurse] [--format <fmt>] [--output-eval] [--output-no-...]` —
  print nodes; `-r` recurses.
- `json` — print the tree as a JSON array of node objects.
- `sync` — fetch external nodes and update the database (refreshes the working
  tree); the default command when none is given.
- `clean` — remove files created by a previous `sync` (honours `delete` mark).
- `status` — report state of the tree/database.
- `craftorder` — emit nodes marked `build`, in dependency order (fast; skips
  sane-stash check).
- `dbstatus` — fast database state query without needing a share directory.
- `walk [--filter ...] [--callback ...]` — visit every node with a callback.
- `config` — manipulate the sourcetree config files (`list`, `status`,
  `copy`, `remove` subcommands).
- `dotdump` — emit the tree (or the database) as Graphviz `.dot`.

### 3.2. Node module — `src/mulle-sourcetree-node.sh`

Concerns a single node's representation and conversion to a nodeline string.

- `sourcetree::node::r_uuidgen()` — emit a new UUID into `RVAL`.
- `sourcetree::node::r_sanitized_address() <address>` — normalize an address
  into `RVAL`.
- `sourcetree::node::r_sanitized_marks() <marks>` — normalize a marks string.
- `sourcetree::node::r_encode_userinfo() <userinfo>` /
  `sourcetree::node::r_decode_raw_userinfo() <userinfo>` — base64 (de)code
  userinfo so it can be binary-safe.
- `sourcetree::node::r_to_nodeline() <address> <nodetype> <branch> <marks>
  <rawuserinfo> <tag> <url> <fetchoptions> <uuid>` — assemble the canonical
  nodeline string into `RVAL`.
- `sourcetree::node::to_nodeline()` — same, but prints to stdout.
- `sourcetree::node::type_filter() <nodetype>` — check/print the type.
- `sourcetree::node::same_string() <a> <b>` — string equality check.
- `sourcetree::node::printf()` — format a node per a `--format` string (see
  `printf_format_help`); `sourcetree::node::_r_get_format_key()` is a helper.
- `mulle_sourcetree_inititalize()` — (legacy spelling) initialization hook.

### 3.3. Nodeline module — `src/mulle-sourcetree-nodeline.sh`

A *nodeline* is the textual, colon/space separated single-line representation
of a node. All `r_*` functions emit their result via `RVAL`.

- `sourcetree::nodeline::r_get_address() <nodeline>` — address part.
- `sourcetree::nodeline::r_get_nodetype() <nodeline>` — nodetype part.
- `sourcetree::nodeline::r_get_uuid() <nodeline>` — uuid part.
- `sourcetree::nodeline::r_get_url() <nodeline>` — raw url part; the evaled
  variant is `r_get_evaled_url()` (performs environment expansion).
- `sourcetree::nodeline::parse() <nodeline>` — validate/set defaults.
- `sourcetree::nodeline::r_index() <nodeline> <file>` — index of a nodeline in
  a file; `_r_find`, `r_find`, `r_find_by_url`, `r_find_by_evaled_url`,
  `r_find_by_uuid`, `r_find_by_index`, `r_find_by_address_url_uuid()` search a
  file for a matching nodeline.
- `sourcetree::nodeline::has_duplicate() <address> <file>` — duplicate check.
- `sourcetree::nodeline::remove() <nodeline> <file>` — remove from a file.
- `sourcetree::nodeline::printf_header()` / `printf()` — format nodelines using
  `--format`/`--output-*` options; `r_get_sep()`, `r_get_formatstring()` are
  helpers.
- `sourcetree::nodeline::r_diff()` — compare two sets of nodelines.
- `sourcetree::nodeline::initialize()` — initialization hook.

### 3.4. Marks module — `src/mulle-sourcetree-marks.sh`

Manipulates and tests the comma-separated *marks* string of a node.

- `sourcetree::marks::r_add() <marks> <mark>` — add one mark, emit result in
  `RVAL`; `_r_add()` is the internal variant.
- `sourcetree::marks::r_remove() <marks> <mark>` — remove one mark (result in
  `RVAL`); `_r_remove()` internal.
- `sourcetree::marks::r_enable() <marks> <markprefix>` /
  `sourcetree::marks::r_disable() <marks> <markprefix>` — enable/disable by
  prefix (e.g. turn off the whole `no-` prefix family). `enable()` and
  `disable()` print instead of returning via `RVAL`.
- `sourcetree::marks::r_enable_multi_marks() <marks> <list>` /
  `sourcetree::marks::r_disable_multi_marks() <marks> <list>` — bulk variants.
- `sourcetree::marks::contain() <marks> <mark>` — test membership (the internal
  `_contain()` is the strict checker; `sourcetree::marks::_key_check()`).
- `sourcetree::marks::match() <marks> <markexpr>` — match against an
  expression (supports `no-`, prefixes); `version_match()` handles version
  qualifiers.
- `sourcetree::marks::compatible_with_marks() <marks> <required>` — test
  superset compatibility (used to decide e.g. "is this node cmake-able").
- `sourcetree::marks::intersect() <marks> <othermarks>` — true if they share a
  mark.
- `sourcetree::marks::r_simplify() <marks>` — remove redundant `no-`/`only-`
  forms; `r_sort()` sorts; `r_clean_marks()` normalizes.
- `sourcetree::marks::do_filter_expr() <expr>` and friends (`do_filter_iexpr`,
  `do_filter_sexpr`, `filter_with_qualifier`) — evaluate filter expressions.
- `sourcetree::marks::walk() <marks> [--callback ...]` — iterate marks with a
  callback.
- `sourcetree::marks::assert_sane() <marks>` / `assert_sane_nodemark()`
  / `is_sane_nodemark()` — sanity checks for marks syntax.
- `sourcetree::marks::check_consistency()` (+ `framework_consistency_check`,
  `no_cmake_inherit_consistency_check`) — cross-mark consistency validation.
- `sourcetree::marks::r_diff() <a> <b>` — diff two mark sets into `RVAL`.

### 3.5. Database module — `src/mulle-sourcetree-db.sh`

Manages the on-disk database recording the physical state of nodes (directories,
fetch state, ownership, graveyards/zombies).

- `sourcetree::db::memorize()` / `sourcetree::db::recall()` /
  `sourcetree::db::forget()` — create/read/delete a database entry keyed by
  nodeline; `bury()` marks an entry dead.
- Lookup functions by key: `fetch_nodeline_for_uuid()`, `fetch_uuid_for_address()`,
  `r_fetch_uuid_for_evaledurl()`, `fetch_evaledurl_for_uuid()`,
  `fetch_filename_for_uuid()`, `fetch_nodeline_for_filename()`,
  `fetch_all_uuids()`, `fetch_all_nodelines()`, `fetch_all_filenames()`,
  `r_files()`.
- `sourcetree::db::set_memo() <key> <value>` / `add_memo()` / `add_missing()` —
  store extra per-entry metadata.
- Database-type handling: `get_dbtype()` / `set_dbtype()` / `clear_dbtype()`,
  `is_recurse()`, `ensure_compatible_dbtype()`, `ensure_consistency()`.
- State flags: `is_ready()` / `set_ready()` / `clear_ready()`,
  `get_timestamp()`, `is_updating()` / `set_update()` / `clear_update()`,
  `exists()`, `dir_exists()`.
- Share directory: `set_shareddir()` / `get_shareddir()` / `clear_shareddir()`;
  `r_share_filename()`.
- Graveyard/zombie handling: `has_graveyard()`, `graveyard_dir()`,
  `is_graveyard()`, `is_uuid_alive()`, `set_uuid_alive()`,
  `is_filename_inuse()`, `zombify_nodes()`, `zombify_nodelines()`,
  `bury_zombies()`, `bury_flat_zombies()`, `bury_zombie_nodelines()`,
  `do_bury_zombiefile()`, `safe_bury_dbentry()`, `state_description()`.
- `sourcetree::db::reset()` — wipe the database.
- `sourcetree::db::environment()`, `print_db_done()` — report DB location/state.
- Internal path helpers `_nodeline`, `_owner`, `_filename`, `_index`, `_evaledurl`,
  `__common_*` compute database layout and filenames.

### 3.6. Walk module — `src/mulle-sourcetree-walk.sh`

Generic tree-walking engine used by many commands to visit every node.

- `sourcetree::walk::main() [--filter <expr>] [--callback <code>]
  [--dedupe-mode <mode>] [--lenient] [--share|--recurse|--flat]` — walk all
  nodes (from config and database) invoking the callback for each.
- `sourcetree::walk::usage()` — usage text.
- `sourcetree::walk::_callback_permissions()` / `_descend_permissions()` —
  internal permission checks during the walk.

During a walk, the callback sees a set of exported variables: `NODE_ADDRESS`,
`NODE_BRANCH`, `NODE_FETCHOPTIONS`, `NODE_MARKS`, `NODE_RAW_USERINFO`,
`NODE_TAG`, `NODE_TYPE`, `NODE_URL`, plus `WALK_DATASOURCE`.

### 3.7. Action module — `src/mulle-sourcetree-action.sh`

Implements the sync "actions" performed on nodes (fetch, update, remove, bury).

- `sourcetree::action::do_actions_with_nodeline() <nodeline>` /
  `do_actions_with_nodelines()` / `do_actions_with_nodelines_parallel()` —
  run the fetch/update/clobber actions for one, many, or (in parallel) many
  nodes based on their nodetype and marks.
- `sourcetree::action::do_operation() ...` — core single operation dispatcher
  (`_do_fetch_operation()` is the fetch implementation).
- `sourcetree::action::r_fetch_eval_options()` — compute fetch options incl.
  environment; `is_embedded()`.
- Update/move safety: `update_safe_move_node()`, `update_safe_remove_node()`,
  `update_safe_clobber()`, `is_squatted_filename()`,
  `r_update_actions_for_node()`, `__update_perform_item()`,
  `__update_perform_actions()`.
- `sourcetree::action::r_is_fetchable() <marks> <nodetype>` — consult `fs`/`set`
  marks and nodetype to decide whether to fetch.
- `sourcetree::action::write_fix_info()` — persist "fix" bookkeeping for the
  `fix` command.
- `sourcetree::action::_memorize_node_in_db()` — record node in the database.
- `sourcetree::action::has_system_include()` — probe system include.
- `sourcetree::action::initialize()` — initialization hook.

### 3.8. Sync module — `src/mulle-sourcetree-sync.sh`

Top-level implementation of the `sync` command.

- `sourcetree::sync::main() [--dry-run] ...` — entry point.
- Modes: `sync_only_share()` / `sync_share()` / `sync_recurse()` /
  `sync_flat()` — the three pipelined sync strategies (+ `_style_for_*` and
  `_sync_*` internal helpers).
- `sourcetree::sync::descend_config_nodelines()` /
  `descend_db_nodelines()` (+ `descend_config_nodeline`/`descend_db_nodeline`)
  — descend into nested sourcetrees; `__get_db_descendinfo()`,
  `__get_config_descendinfo()`, `check_descend_nodeline()` support this.
- `sourcetree::sync::nodeline_sync_only_share()` — single-node share sync.
- `sourcetree::sync::write_cachedir_tag()` — write the tag marking the fetch
  cache directory; `start()`; `warn_dry_run()`.
- `sourcetree::sync::initialize()` — initialization hook.

### 3.9. Environment module — `src/mulle-sourcetree-environment.sh`

Establishes the working directories, share/stash dir, config discovery and DB
mode before any command runs.

- `sourcetree::environment::default [<sharedir>] [<configdir>] [<configname>]
  [<use_fallback>] [<defer>]` — standard setup used by most commands.
- `sourcetree::environment::config`, `minimal`, `basic` — lighter setups.
- `sourcetree::environment::set_share_dir() <dir>` — set share/stash dir.
- `sourcetree::environment::check_sane_stash_dir()` — validate the stash.
- `sourcetree::environment::set_default_db_mode() <database> <usertype>` —
  choose `flat`/`recurse`/`share` DB type.
- `sourcetree::environment::_set_sourcetree_global()` — export globals.
- `sourcetree::environment::setup()` / `initialize()`.

Key globals exported: `MULLE_SOURCETREE_PROJECT_DIR`, `MULLE_SOURCETREE_ETC_DIR`,
`MULLE_SOURCETREE_STASH_DIR` (default `stash`), `MULLE_SOURCETREE_VAR_DIR`,
`MULLE_SOURCETREE_CONFIG_NAME` (default `config`), plus `SOURCETREE_MODE`,
`SOURCETREE_START`, `SOURCETREE_CONFIG_NAME/DIR`, `SOURCETREE_DB_FILENAME`,
`SOURCETREE_FIX_FILENAME`.

### 3.10. Other modules

- `src/mulle-sourcetree-commands.sh` — the `sourcetree::commands::*_main`
  functions backing `add`, `copy`, `get`, `duplicate`, `info`, `knownmarks`,
  `mark`, `move`, `rcopy`, `rename`, `rename-marks`, `remove`, `set`, `unmark`.
- `src/mulle-sourcetree-clean.sh` — `clean` (and `desecrate`) via
  `sourcetree::clean::main`, `walk`, `bury`.
- `src/mulle-sourcetree-craftorder.sh` — `craftorder::main` computes the build
  order of `build`-marked nodes via topological/dependency ordering.
- `src/mulle-sourcetree-config.sh` — `config::main` with `list_main`,
  `status_main`, `copy_main`, `remove_main` subcommands.
- `src/mulle-sourcetree-list.sh` / `json.sh` / `dotdump.sh` / `status.sh` /
  `dbstatus.sh` — the corresponding `*::main` printers.
- `src/mulle-sourcetree-fetch.sh` — fetch orchestration used by sync/actions.
- `src/mulle-sourcetree-fix.sh`, `marks-map`, `plugin.sh`, `filter.sh`,
  `test.sh`, `callback.sh`, `wrap.sh`, `rewrite.sh`, `reset.sh`, `reuuid.sh`,
  `eval-add.sh`, `supermarks.sh` — support commands; each exposes a
  `<ns>::main` entry.
- `src/mulle-sourcetree-cfg.sh` — low-level config file read/write helpers used
  throughout (the `sourcetree::cfg` include).

## 4. Performance Characteristics

- **Config/database access** is via flat on-disk text files under
  `.mulle/etc/sourcetree/` and the variant directory; lookups (e.g.
  `r_find_by_*`) are linear scans (O(n) in node count). For typical project
  sizes this is negligible; `list`, `json`, `dotdump` read the whole tree.
- **Walking** (`walk`, `list -r`, `status`, `dotdump`, `craftorder`) visits
  every node once — O(n) — plus per-node lookups into the database.
- **Craftorder** computes a dependency order; cost is dominated by the graph
  size, not asymptotically heavy.
- **Sync/action phases** dominate runtime: each external node may trigger a
  network fetch/update via `mulle-fetch`. `sync_share` deduplicates roots with
  identical URLs so each is fetched once. `do_actions_with_nodelines_parallel`
  performs fetch actions concurrently.
- **Thread safety:** bash/zsh scripts are single-threaded except where the
  tool explicitly runs child processes in parallel (parallel fetch actions).
  Do not run multiple `mulle-sourcetree` invocations against the same tree
  concurrently (the tool issues a single-instance warning).

## 5. AI Usage Recommendations & Patterns

- **Best Practices**
  - Drive everything through the `mulle-sourcetree` CLI rather than reading
    the internal text/config files directly; the tool enforces invariants that
    manual edits would silently break.
  - Prefer `--share` (the default) mode for `sync`/`list` to minimize re-fetch
    and deduplicate nodes.
  - Use the environment-expansion scheme for URLs/tags so inherited
    dependencies remain overridable: write
    `--url '${FOO_URL:-https://...}' --tag '${FOO_TAG:-1.2.3}'`.
  - Use `--output-*` / `--format` options of `list` for machine consumption
    (JSON via `json` is the canonical exchange format).
  - After editing a tree (`add`/`remove`/`set`/`mark`/`move`), run `sync` so
    the database and filesystem reflect the change; run `clean` to remove what
    a prior `sync` created.
- **Common Pitfalls**
  - Do not edit or copy a node `uuid` — it is an internal identifier.
  - Do not touch the database/fix files under the var directory directly.
  - Be aware userinfo can be raw/binary (base64-encoded on the wire); use
    `r_encode_userinfo`/`r_decode_raw_userinfo` rather than treating it as
    plain text.
  - The `nofs`/`fs`/`set` marks control whether a node is actually materialized
    or fetched; setting marks wrongly can make `sync` skip or fail a node.
  - URLs/tags with `tar`/`zip` only apply if the URL itself uses the tag via
    expansion; a plain URL won't be affected by the `tag` field.
  - When calling library functions that use the `RVAL` convention, consume
    `RVAL` immediately (the next `r_*` call overwrites it).
- **Idiomatic Usage**
  - For scripts, source `mulle-bashfunctions`, then `include "sourcetree::db"`
    (or the relevant module) and call the `sourcetree::*` functions — this is
    exactly how the bundled dispatcher composes its modules.
  - Use `walk` with a `--callback` snippet (reading the exported `NODE_*`
    variables) to iterate nodes generically rather than reimplementing walking.

## 6. Integration Examples

The project is a shell tool, so the idiomatic "API" is the CLI; internal
library functions are used from shell scripts and follow the `RVAL` output
convention (3-space indent, Allman braces).

### Example 1: Create a sourcetree and add an overridable archive dependency

```bash
# Initialize a fresh project's sourcetree by adding the first node.
# -N stays in the current directory (no searching for an enclosing tree).
mulle-sourcetree -N add \
   --nodetype tar \
   --tag '${ZLIB_TAG:-2.0.0}' \
   --url '${ZLIB_URL:-https://github.com/madler/zlib/archive/${MULLE_TAG}.tar.gz}' \
   external/zlib

# Fetch dependencies and build the database.
mulle-sourcetree sync

# Show the resulting tree as JSON (address, nodetype, url, uuid).
mulle-sourcetree json
```

### Example 2: Mark, reorder, list, and remove nodes

```bash
# Add a git dependency, then narrow its behaviour with marks.
mulle-sourcetree -N add --nodetype git \
   --marks "no-delete,no-update,no-share" \
   --url '${EXPAT_URL:-https://github.com/libexpat/libexpat.git}' \
   external/expat

# Put zlib before expat in the build/link order.
mulle-sourcetree move external/zlib top

# Print a tab-formatted, evaluated listing with no header.
mulle-sourcetree list --output-no-header --output-eval

# Remove a node from the tree, then drop its files from disk.
mulle-sourcetree remove external/expat
```

### Example 3: Query the database and craft order from a script

```bash
# 'craftorder' emits build-marked nodes in dependency order (fast path).
for project in $(mulle-sourcetree craftorder)
do
   echo "building ${project}"
done

# 'walk' visits every known node; act on each via the exported NODE_* vars.
mulle-sourcetree walk --callback '
   printf "%s\t%s\t%s\n" "${NODE_ADDRESS}" "${NODE_TYPE}" "${NODE_MARKS}"
'
```

### Example 4: Consume a library module from a script (RVAL convention)

```bash
# Load the marks module and manipulate a marks string.
include "sourcetree::marks"

marks="no-delete,set,share"

# Add a mark, result returned via RVAL.
sourcetree::marks::r_add "${marks}" "update"
marks="${RVAL}"

# Test membership.
if sourcetree::marks::contain "${marks}" "set"
then
   echo "node is settable"
fi
```

## 7. Dependencies

Direct `mulle-sde` dependencies (deduced from sources; no
`config.sourcetree` present in this checkout):

- `mulle-bashfunctions` — provides the shell framework, `include`, `exekutor`,
  `options_*`, `fail`, and the `array`, `base64`, `case`, `etc`, `file`,
  `parallel`, `path`, `sort`, `string`, `version` includes used throughout.
- `mulle-fetch` — performs the actual fetch/update of repository and archive
  nodes during `sync`.
- `mulle-vararg` — optional support functions referenced by code.

Related companion tools (not runtime dependencies of the core): 
`mulle-sourcetree-to-c`, `mulle-sourcetree-to-cmake`, `mulle-sourcetree-graph`
(together with `mulle-sde`, `mulle-craft`, `mulle-make` form the wider
toolchain).

## 8. Shortcut

No `asset/dox/api/toc/index.md` existed before this write (the directory was
empty), so this document covers the full current API state at `3b9d4c5`.