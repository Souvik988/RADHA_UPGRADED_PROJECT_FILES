# RADHA — Repository Convergence Report

Resolves the local-Codex vs GitHub-remote divergence (sprint Phases 0–2).

## Canonical roots (Git-verified against `origin/main`)
- **Remote:** `https://github.com/Souvik988/RADHA_UPGRADED_PROJECT_FILES.git`
- **`origin/main` = `bd4710b`** ("upgrade") — the **canonical monorepo**, confirmed by
  `git ls-tree -r origin/main`:
  - **Canonical Flutter root: `apps/mobile/`** (package **`radha_mobile`**)
  - **Canonical backend root: `server/`** (NestJS — feature-complete; payments + subscriptions modules present)
  - `packages/shared-types/`, `pnpm-workspace.yaml`
- A **real backend exists** and a **real 38-file Flutter test suite exists** on `origin/main`.

## The local discrepancy (what went wrong)
The local clone's branches carried a **destructive partial export**. Commit `ba818fd`
("add") **deleted the entire monorepo tree** (`apps/mobile/`, `server/`, `packages/`,
`pnpm-workspace.yaml`) and committed a standalone **`radha_app/`** copy (package
`radha_app`) in its place. The Codex work (catalog source-state + UI v2 foundation) was
then built on top of that export.

- Earlier sessions concluded "radha_app is canonical, no backend exists" — that was true
  only of the **diverged local branch**, never of `origin/main`. **Corrected here.**
- `radha_app` is byte-content-identical to `apps/mobile@origin/main` (cross-tree diff =
  line-ending normalization on 26 files), so the Codex changes port cleanly.

## Reconciliation decision — CASE B (clean worktree, port file-by-file)
Local `HEAD` technically descends from `origin/main`, **but only through the destructive
`ba818fd`** — merging/pushing the local branch onto `main` would delete the monorepo.
Therefore CASE B was chosen (per the sprint protocol):

1. **Safety first (Phase 0):** full `git bundle --all`
   (`../radha-codex-local-safety.bundle`, ~496 MB), working-tree patch (0 B — clean),
   and a 2-patch series of the Codex commits (`../radha-codex-format-patches/`). Manifest:
   `radha_app/docs/LOCAL_CODEX_WORK_RECOVERY_MANIFEST.md`.
2. **Clean worktree from `origin/main`:**
   `git worktree add -b codex/radha-production-converged ../radha-production-converged origin/main`.
   All further work happens here, in the canonical monorepo.
3. **Ported file-by-file** (imports rewritten `radha_app` → `radha_mobile`):

| Ported file (now under `apps/mobile/`) | Type |
|---|---|
| `lib/features/catalog/providers/product_browse_providers.dart` | catalog source-state + logging |
| `lib/features/catalog/product_browse_screen.dart` | honest source banner + retry |
| `lib/core/router/root_shell.dart` | RadhaBottomNavigation wiring |
| `lib/design/widgets/radha_bottom_navigation.dart` | new shared component |
| `lib/design/widgets/radha_status_chip.dart` | new shared component |
| `test/design/{radha_bottom_navigation,radha_status_chip,theme}_test.dart` | tests |
| `test/features/catalog/catalog_source_test.dart` | mocked-HTTP catalog tests |

### Intentionally NOT ported
- `radha_app/` UI_V2 / convergence docs that describe the *diverged export's* (incorrect)
  "no backend" premise — superseded by this report. (Recovery manifest retained in the
  bundle.)
- The destructive `ba818fd` history and the standalone `radha_app/` tree itself.
- The `apps/mobile/` (empty) skeleton left in the local export — untracked, ignored.

## Validation (in the canonical worktree)
- `flutter pub get` ✓ · `gen-l10n` ✓ · generated `.g.dart` committed (19).
- `flutter analyze --fatal-infos` on ported files ✓ **No issues found**.
- `flutter test` (ported design + catalog tests, alongside existing suite) ✓ **22 passing**.

## Commit mapping
| Local (export) branch `codex/radha-production-convergence` | Canonical branch `codex/radha-production-converged` |
|---|---|
| `98209f6` catalog source honesty | folded into → `9d9814e` |
| `585c2f0` UI v2 foundation | folded into → `9d9814e` |
| (base `ba818fd` destructive export) | **dropped** (replaced by clean port onto `origin/main`) |

`codex/radha-production-converged`: `9d9814e` → `bd4710b` (origin/main) → `1bfecc5`.

## Push status
- Not pushed (no write authorization assumed; **CASE C fallback applies**). The work is
  preserved as: (a) the safety bundle, (b) the format-patch series, (c) the committed
  `codex/radha-production-converged` branch in the worktree. To publish:
  `git push -u origin codex/radha-production-converged` when credentials permit. **Do not
  push this branch onto `main`** without review (it is a clean superset of `origin/main`).

## Remaining repository risks
- **Active external auto-commit/reset tool** on the local clone (terse "add" commits;
  reflog shows `reset → ba818fd`). It can move local refs; it does not affect the worktree
  branch's committed objects or the bundle. Recommend disabling it.
- Local `main` (`b24cbd6`) still points at the destructive export; leave untouched, do not
  push.
