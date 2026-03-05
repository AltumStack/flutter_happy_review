Validate the CFD context structure for this project. Check the following:

1. **Root file**: Read CLAUDE.md and verify all @references point to existing files
2. **Architecture**: Verify doc/ARCHITECTURE.md exists and has the required sections (System Diagram, Layer Structure, Module Map)
3. **Stack**: Verify doc/STACK.md exists and matches pubspec.yaml dependencies
4. **Conventions**: Verify doc/CONVENTIONS.md exists
5. **Current Status**: Verify doc/CURRENT_STATUS.md exists and check freshness:
   - Run `git log -1 --format="%ar" -- doc/CURRENT_STATUS.md` to see last update
   - Warn if older than 1 working day
6. **Decisions**:
   - Verify doc/decisions/_index.md exists
   - Check that all ADR files in doc/decisions/ (matching [0-9]*.md) are listed in _index.md
   - Check that all files referenced in _index.md actually exist
7. **Slash commands**: Verify .claude/commands/ contains: start-session.md, new-decision.md, validate-context.md

Report:
- What's valid
- What's missing or broken
- What's stale and needs updating

Do NOT modify any files — this is a read-only validation.
