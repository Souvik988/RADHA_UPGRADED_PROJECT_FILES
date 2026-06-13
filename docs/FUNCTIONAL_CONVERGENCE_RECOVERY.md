# RADHA — Functional Convergence Recovery (Phase 0)

Safety snapshot taken **before** any modification this phase.

## Repository
- **Local repo:** `RADHA_UPGRADED_PROJECT_FILES/` · **Remote:** `origin` =
  `https://github.com/Souvik988/RADHA_UPGRADED_PROJECT_FILES.git`.
- **Worktrees:**
  - `RADHA_UPGRADED_PROJECT_FILES/` — branch `codex/radha-production-convergence`, HEAD
    `585c2f0` (the **export** tree: `radha_app/`, `radha_backend/`, **`radha_dashboard/`**).
  - `radha-production-converged/` — branch `codex/radha-production-converged`, HEAD `d0530f5`
    (the **canonical monorepo** from `origin/main` + this sprint's mobile work).
- `origin/main` = `bd4710b` (canonical monorepo: `apps/mobile`, `server`, `packages`).

## Branch ↔ content map
| Branch | Tree | Holds |
|---|---|---|
| `origin/main` / `codex/radha-production-converged` | canonical monorepo | apps/mobile (radha_mobile), server, packages |
| `codex/radha-production-convergence` / `main` | export | radha_app, radha_backend, **radha_dashboard** |

The **dashboard lives only on the export branch**; the **mobile sprint work lives only on
the converged branch**. Unifying them into one monorepo is the convergence goal.

## Uncommitted at snapshot
14 files in the export working tree (LF/CRLF + codegen churn on `radha_app`, from earlier
sessions) — captured in the patch below; none are dashboard source edits.

## Existing Codex commits (converged branch, on origin/main)
`9d9814e · 8640a51 · 6a99a8e · 86cb725 · a1f3b0a · 1c9ca8c · e7d445e · d0530f5`
(catalog port, docs, product-detail states, payment engine, subscription contract,
subscription page, payment-state-machine doc, validation report).

## Safety artifacts (created, verified)
| Artifact | Path | Size |
|---|---|---|
| Full bundle (`--all`, all branches) | `../radha-functional-convergence.bundle` | ~496 MB |
| Working-tree patch (`git diff --binary`) | `../radha-functional-convergence.patch` | 1.3 KB |
| (prior sprint bundle) | `../radha-codex-local-safety.bundle` | ~496 MB |

Restore: `git clone radha-functional-convergence.bundle <dir>`.

## Push status
Not pushed (no write auth assumed — CASE C). All work preserved on local branches + bundles.

## ⚠️ Active hazard
External auto-commit/reset tool on the export branch (resets to `ba818fd`). The converged
branch + bundles are unaffected; verify HEAD after commits.
