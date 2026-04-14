# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this workspace.

## Operational Rules (Shared AI Agent Instructions)

Shared operational rules for all AI agents are defined in `.github/copilot-instructions.md`. That file is the single source of truth; rules are not repeated here.

@.github/copilot-instructions.md

**Claude Code-specific notes:**

- Project ownership, hard rules, mandatory work plan, and commit convention are covered by the import above.
- Push, PR creation, and post-merge steps require **explicit user approval**. No `git push` or `gh pr create` without approval.
- Direct commits to `main` are forbidden.

---

## What This Workspace Is

This workspace was generated from the `workspace-with-demo-v1` Harmonia template. It is a **private workspace** (full source, secrets, ops) paired with a **public demo** repository linked as a Git submodule at `demo/`.

Two-layer structure — do not confuse:

- **Workspace root (`/`):** The private repository. Source code, secrets, infrastructure, CI pipelines. Never pushed to public.
- **`demo/` (submodule):** A separate public repository. Contains only the static demo site. Secrets must never reach here.

## Security — Always Top of Mind

The `demo/` submodule is public. Before any operation that touches `demo/`:

1. Does this file contain secrets, `.env` content, or API keys? → **Stop.**
2. Is this file in `demo_sync_denylist` in `.github/template-manifest.yml`? → **Stop.**
3. Run `pwsh ./scripts/verify-no-secrets-in-demo.ps1` after any sync operation.

## Available Scripts

All scripts are in the root `scripts/` directory (not `development/scripts/`).

| Script | Purpose |
|--------|---------|
| `sync-to-demo.ps1` | Copy safe content from workspace to demo submodule |
| `validate-template.ps1` | Validate manifest against filesystem |
| `verify-no-secrets-in-demo.ps1` | Scan demo/ for secret patterns |
| `bump-template-version.ps1` | Bump TEMPLATE_VERSION + README + CHANGELOG |

Run with: `pwsh ./scripts/<script-name>.ps1 [-DryRun]`

## `development/` Policy

The `development/` folder is **gitignored in this workspace** — it stays local, never pushed to the remote. It contains private process notes, backlog, decisions, and sprint tracking.

## Language

Respond in Turkish. Documents and changelogs in Turkish (ASCII-friendly). Code and workflow messages in English.
