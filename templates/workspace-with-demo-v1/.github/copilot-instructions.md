# Workspace-with-Demo — AI Agent Instructions

This file defines the **shared operational rules** for all AI agents (GitHub Copilot, Claude Code, Codex, etc.) working in workspaces generated from the `workspace-with-demo-v1` template.

- GitHub Copilot loads this file automatically.
- Claude Code and other agents import it from their own config files.
- Single-source principle: rules live here, not duplicated per agent.

---

## PROJECT OWNERSHIP

- This project belongs to the user. Even if AI assisted in setup, all decisions belong to the user.
- If unexpected commits or changes appear, ask the user — do not interpret on your own.

---

## ROLE

Your role is to **implement, not decide**. Say "This is an architectural decision" for design questions, report security issues immediately, and ask for clarification before writing code when requirements are ambiguous.

---

## HARD RULES — STOP AND ASK

Never perform the following without explicit user confirmation:

### Security (Most Critical)
- Copy or create any `.env`, secret, API key, or credential file inside `demo/` submodule
- Modify `scripts/sync-to-demo.ps1` in a way that bypasses the `demo_sync_denylist`
- Remove secret patterns from `.gitignore`
- Move `backups/` or `development/` contents into `demo/`

### Deletion
- Delete any file
- Remove a tracked file with `git rm`

### Git
- `git push --force` (any branch)
- `git reset --hard`
- Direct commit to `main` or `develop`
- Delete any branch
- Modify or delete `snapshot/` branches (read-only by convention)
- Delete or rewrite tags

**When triggered, use this template:**
```
PAUSED
-> [intended action]
-> [affected resource]
This action may be irreversible or carry a security risk. Do you confirm?
```

---

## ALLOWED WITHOUT ASKING

- Create new files within the defined project structure
- Non-destructive edits to Markdown, YAML, PowerShell, and config files
- Read `scripts/*.ps1` for inspection purposes
- `git add` and `git commit` on active feature/fix/docs branches
- Read project files (except `.env` and credential files)
- Run `scripts/sync-to-demo.ps1 -DryRun` for dry runs
- Run linters/formatters

---

## MANDATORY WORK PLAN

> **Follow these steps in order for every work session. Cannot be skipped.**

1. **Start:** Align `develop` with `origin/develop` (`git checkout develop && git pull origin develop`).
2. **Create branch:** Open a new branch from `develop` following the **BRANCH NAMING** section below.
3. **Commit:** Commit with a descriptive message after each step.
4. **Push permission:** STOP. Wait for explicit user approval before pushing.
5. **PR permission:** STOP. Wait for explicit user approval before creating a PR.
6. **After merge:** STOP. Do not proceed to the next section without "merged" confirmation AND "continue" approval from the user.

---

## BRANCH NAMING

| Type | Format | Example | Target |
|------|--------|---------|--------|
| Feature | `feat/<scope>-<short-desc>` | `feat/auth-oauth-integration` | `develop` |
| Fix | `fix/<scope>-<issue-id>` | `fix/sync-encoding-42` | `develop` |
| Docs | `docs/<area>-<short-desc>` | `docs/installation-phase3` | `develop` |
| Milestone | `milestone/m<no>-<desc>` | `milestone/m1-public-launch` | `develop` |
| Release | `release/x.y.z` | `release/1.1.0` | `main` |
| Hotfix | `hotfix/<critical-issue>` | `hotfix/api-key-leak` | `main` (+ back-merge to `develop`) |
| Snapshot | `snapshot/<date>-<desc>` | `snapshot/2026-04-launch` | — (never merged) |

- All merges go through Pull Requests.
- `snapshot/` branches are never merged; created for milestone records only.
- Hotfix branches are back-merged to `develop` after merging to `main`.

---

## COMMIT CONVENTION

```
<type>(<scope>): <subject>

<what changed and why>

<closes #issue — if applicable>
```

**Types:** `feat` · `fix` · `docs` · `style` · `refactor` · `test` · `chore`

---

## SECURITY MODEL

This template uses 3-layer defense-in-depth:

1. **Git layer:** `.gitignore` — `.env`, `secrets.*`, `*.key`, `credentials.*` are never tracked.
2. **Script layer:** `scripts/sync-to-demo.ps1` — reads `demo_sync_denylist` from manifest, skips matching files; runs API key regex scan and aborts on match.
3. **Manifest layer:** `.github/template-manifest.yml` `forbidden_globs` — CI scans every PR.

**Defense-in-depth:** Even if one layer is bypassed, the other two catch it. Never rely on a single layer.

---

## PROJECT CONTEXT

```
TYPE    : Private workspace + public demo submodule
WORKSPACE : private repository (secrets, backend, ops, full source)
DEMO      : public repository (submodule, static site, GitHub Pages)
RELATION  : parent-child (workspace = parent, demo = submodule)
SCRIPTS   : scripts/ (root-level, first-class security & ops)
DOCS      : docs/ (MkDocs, workspace-level documentation)
DEVELOPMENT: development/ (private — .gitignored in workspace)
```

### Directory Structure

```
/                           → workspace root (private repo)
.github/
  copilot-instructions.md   → this file (shared AI rules)
  template-manifest.yml     → required_dirs, required_files, forbidden_globs, demo_sync_denylist
  workflows/
    template-validation.yml
CLAUDE.md                   → Claude Code stub
scripts/
  sync-to-demo.ps1          → safe workspace → demo copy
  validate-template.ps1     → manifest validation
  verify-no-secrets-in-demo.ps1
  bump-template-version.ps1
demo/                       → public demo (git submodule)
docs/                       → MkDocs (workspace documentation)
development/                → .gitignored — private process notes, backlog, decisions
backups/
  latest.json               → tracked
  (other backups gitignored)
```

---

## USER CHANGES & DEPENDENCY MANAGEMENT

- User's direct changes **must never be deleted, overwritten, or reverted.**
- PowerShell version, GitHub Actions runner, or action versions cannot be changed without user approval.
- If unexpected commits appear in `git log`, ask the user — do not act on your own interpretation.

---

## REFERENCES

- Template manifest: `.github/template-manifest.yml`
- Sync script: `scripts/sync-to-demo.ps1`
- Security validation: `scripts/verify-no-secrets-in-demo.ps1`
- Installation guide: `docs/installation/`
- Backlog: `development/backlogs/backlog.md`
