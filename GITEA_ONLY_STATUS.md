# Gitea-Only Branch Status

## Current State

This branch contains a simplified version of CCPM that only supports Gitea (no GitHub support).

### Completed Work

1. **Forge Abstraction Simplification**
   - Removed all GitHub code from forge scripts
   - `config.sh`: Always returns "gitea", auto-detects Homebrew paths on macOS
   - `detect.sh`: Always returns "gitea"
   - All 5 issue/label scripts: Direct tea CLI usage only
   - Reduced from 480 lines to 119 lines (361 lines removed)

2. **Documentation Updates**
   - Updated README with Gitea-only installation instructions
   - Clear notice that this is a fork without GitHub support
   - Installation: clone repo → copy `ccpm/` to `.claude/`

3. **Bug Fixes**
   - Fixed macOS SSH environment PATH issue
   - Auto-detect tea CLI in `/opt/homebrew/bin` and `/usr/local/bin`
   - Removed unnecessary `.claude` directory creation in init.sh

### Known Limitations

1. **tea CLI Interactive Requirement**
   - tea CLI requires interactive terminal (TTY) for confirmation prompts
   - Cannot be tested via SSH non-interactive sessions
   - Should work fine in real Claude Code environment (has terminal)

2. **Incomplete Work**
   - `epic-sync.md` still uses GitHub sub-issues syntax (needs update for task lists)
   - Other pm commands not fully reviewed for Gitea-only compatibility
   - No real-world testing in Claude Code environment yet

### Test Repository

- Location: `ssh://ginas/ivan/ccpm-forge-test.git`
- Contains full `.claude/` directory structure
- Ready for testing on Mac with Claude Code

### Next Steps (When Resumed)

1. Update `epic-sync.md` to use tea CLI and task lists
2. Review all pm commands for Gitea compatibility
3. Test in actual Claude Code environment on Mac
4. Consider whether to add direct Gitea API support (using curl) as fallback

### Decision Point

Paused to evaluate whether a Gitea-only fork is the right approach vs. maintaining dual platform support.

---

**Branch**: gitea-only  
**Last Updated**: 2025-10-10  
**Status**: Development paused pending direction decision
