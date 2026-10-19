## 1.9.0

* improved sync speed by reducing the number of forks done
* `sync --quick` skips the whole sync when config files, environment and destinations are unchanged since the last successful sync
* database lookups by address and uuid use an in-memory cache instead of grepping every db file, greatly speeding up sync on large sourcetrees
* `--no-quick` forces a full sync; `--quick-check` remains as an alias for `--quick`
* a failed fetch is now retried on the next `--quick` sync instead of being silently skipped
* `mulle-sourcetree-graph` and graphviz output draw edges to embedded dependencies (no-build,no-share) with a round gray (dot) arrowhead





* `--recurse`/`--recursive` now operate on the shared sourcetree and accept the short `-r` alias
* Default graph options ignore `mulle-objc-tools` instead of `mulle-objc-list`

* new command dblist
* new command graphviz

* properly use `MULLE_SDE_REFLECT_DIR` in created file paths


## 1.8.0




* `--recurse`/`--recursive` now operate on the shared sourcetree and accept the short `-r` alias
* Default graph options ignore `mulle-objc-tools` instead of `mulle-objc-list`

* new command dblist
* new command graphviz

* properly use `MULLE_SDE_REFLECT_DIR` in created file paths


### 1.7.0

* improvements and fixes to mulle-sourcetree-to-cmake and command handling

### 1.6.4



* support for no-actual-build (needed for "none" projects with a sourcetree)
