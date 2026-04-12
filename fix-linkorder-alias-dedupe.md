# Fix: linkorder duplicate emission for aliased amalgamation nodes

## Problem

When a node declares aliases (e.g. `mulle-stacktrace` with
`aliases=mulle-core-all-load,mulle-stacktrace` in `mulle-testallocator`),
and the amalgam itself (`mulle-core-all-load`) is also present in the tree
via another path (e.g. `mulle-objc-runtime`), the linkorder emits both —
causing duplicate `-lmulle-core-all-load` in the link command.

The craftorder avoids this via the shirk mechanism: it does a pre-pass over
the flat db, collects `no-share-shirk` nodes, builds a shadow list, and
suppresses standalone nodes whose names appear in it.

The linkorder walk is recursive/tree-structured and has no equivalent
pre-pass — it never sees the `src/mulle-stacktrace` entry inside
`mulle-core-all-load` (which carries `no-link`, so it's skipped), so the
shadow list is never built and the standalone node is never suppressed.

## Proposed Fix

In `sourcetree::walk::r_has_visited` (mulle-sourcetree-walk.sh), after
computing the lineid for the current node, also check all aliases of the
node against `VISITED`. If any alias is already in `VISITED`, treat the
node as already visited.

This is better than only using the first alias as the dedupe key in
`r_get_dedupe_lineid_from_node`, because:
- Any alias could be the one matching the already-visited amalgam node
- `r_has_visited` already has access to `VISITED`, so no restructuring needed
- All aliases are checked, not just the first

## Sketch

```bash
sourcetree::walk::r_has_visited()
{
   local mode="$1"

   local lineid

   if ! sourcetree::walk::r_get_dedupe_lineid_from_node "${mode}"
   then
      RVAL=""
      return 1
   fi
   lineid="${RVAL}"

   if find_line "${VISITED}" "${lineid}"
   then
      log_walk_debug "A node with lineid \"${lineid}\" has already been visited"
      return 0
   fi

   # Also check aliases — if any alias matches an already-visited address,
   # treat this node as visited (handles amalgamation shirk for linkorder)
   case "${_raw_userinfo}" in
      *aliases=*)
         sourcetree::node::r_decode_raw_userinfo "${_raw_userinfo}"
         local _aliases="${RVAL#*aliases=}"
         _aliases="${_aliases%%$'\n'*}"
         local _alias
         .foreachitem _alias in ${_aliases}
         .do
            if find_line "${VISITED}" "${_alias};DEFAULT" || \
               find_line "${VISITED}" "${_alias};"*
            then
               log_walk_debug "Node \"${_address}\" alias \"${_alias}\" already visited"
               return 0
            fi
         .done
      ;;
   esac

   RVAL="${lineid}"
   return 2
}
```

## Affected file

`/home/src/srcS/mulle-sourcetree/src/mulle-sourcetree-walk.sh`

## Test case

`/home/src/srcO/MulleUI/MulleCGNanovg/test` — after fix, `mulle-sde test link-args`
should show only one `-lmulle-core-all-load`.
