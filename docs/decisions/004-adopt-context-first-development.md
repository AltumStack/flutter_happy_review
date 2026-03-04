# ADR-004: Adopt Context-First Development

## Status

Accepted

## Date

2026-03-04

## Context

As the project grows, AI-assisted development sessions start without context about architectural decisions, conventions, or current work state. The existing CLAUDE.md was a monolithic file mixing architecture details, commands, and conventions — effective for a small project but not scalable.

## Decision

Adopt Context-First Development (CFD) methodology with:

1. **CLAUDE.md as Level 0 index** — compact root file (~100-150 lines) that references specialized documents
2. **Level 1 domain documents** in `docs/`:
   - `ARCHITECTURE.md` — system diagram, layers, module map
   - `STACK.md` — technologies and versions
   - `CONVENTIONS.md` — code style, testing, git, naming
   - `CURRENT_STATUS.md` — dynamic file updated every session
3. **Level 2 decisions** in `docs/decisions/` — ADRs with strict format
4. **Slash commands** in `.claude/commands/` — automated context maintenance

Key principles applied:
- Single Source of Truth: CLAUDE.md references docs, never duplicates
- Decisions as first-class citizens: every significant choice gets an ADR
- English as context language: optimized for LLM tokenizers
- Session discipline: start with `/project:status`, close by updating `CURRENT_STATUS.md`

## Alternatives Considered

1. **Keep monolithic CLAUDE.md** — Rejected because it doesn't scale and mixes concerns
2. **AGENTS.md standard** — Considered for interoperability but CFD is more comprehensive; can add AGENTS.md later if needed
3. **No formal methodology** — Rejected because repeated context loss wastes time and tokens

## Consequences

- Every session starts with accurate, structured context (~500-1,500 tokens vs 20,000+ for code scanning)
- New contributors (human or AI) can orient themselves from docs/ without reading source code
- Small overhead per session (start + close routine ~5-8 minutes)
- ADRs create persistent memory of why decisions were made
