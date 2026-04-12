# Platform Fetch Test

Tests the cross-platform fetch logic in `sourcetree::action::r_is_fetchable()`.

## What it tests

When `MULLE_SOURCETREE_PLATFORMS` contains multiple platforms (e.g., `linux:windows`), 
dependencies should be fetched for ALL platforms, not just the current one (`MULLE_UNAME`).

### Test Cases

1. **Single platform, blocked**: `no-platform-linux` on Linux with `PLATFORMS=linux` → should NOT fetch
2. **Cross-platform, blocked on current**: `no-platform-linux` on Linux with `PLATFORMS=linux:windows` → SHOULD fetch (needed for Windows)
3. **Multiple platforms, some blocked**: `no-platform-linux,no-platform-windows` with `PLATFORMS=linux:windows:darwin` → SHOULD fetch (needed for Darwin)
4. **All platforms blocked**: `no-platform-linux,no-platform-windows` with `PLATFORMS=linux:windows` → should NOT fetch
5. **Explicit only-platform**: `only-platform-windows` with `PLATFORMS=linux:windows` → SHOULD fetch
6. **no-fetch blocks all**: `no-fetch` → should NOT fetch regardless of platforms
7. **no-fetch-platform works like no-platform**: `no-fetch-platform-linux` with cross-platform → SHOULD fetch

## Bug Fix

This test validates the fix for the cross-compilation fetch bug where dependencies marked 
`no-platform-<current>` were not being fetched even when needed for other platforms in 
`MULLE_SOURCETREE_PLATFORMS`.

The fix adds a check: if a node is blocked for the current platform, check if ANY platform 
in `MULLE_SOURCETREE_PLATFORMS` is NOT blocked by the node's marks.
