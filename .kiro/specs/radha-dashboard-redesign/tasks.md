# Implementation Plan: RADHA Dashboard Premium UI Redesign

## Overview

This plan transforms the RADHA Admin Dashboard from generic SaaS scaffolding to a premium, editorial, warm-Indian-retail dashboard. All changes are visual-layer-only — no backend, auth, RBAC, or data logic changes. Work is organized in 6 phases: Foundation → Shell → Components → Features → Login → Verification.

## Tasks

- [x] 1. Create spec documents (requirements.md, design.md, tasks.md, .config.kiro)

- [x] 2. Add useIntersectionObserver hook to lib/hooks/use-intersection-observer.ts

- [x] 3. Add CSS stagger utilities and slide-in keyframe to globals.css

- [x] 4. Fix DashShell viewport bug — replace h-screen with min-h-[100dvh]

- [x] 5. Redesign Sidebar active state and transitions

- [x] 6. Redesign TopBar — backdrop-blur, remove explicit shadow

- [x] 7. Rebuild StoreSwitcher as Radix Popover pill chip

- [x] 8. Upgrade Button primary variant with shadow-sm

- [x] 9. Upgrade DataTable — remove zebra, fix header background

- [x] 10. Upgrade KpiTile with hover shadow

- [x] 11. Upgrade MonoNumber with IntersectionObserver trigger

- [x] 12. Upgrade OhsGauge with IntersectionObserver trigger

- [x] 13. Convert LineTrend to AreaChart with gradient fill

- [x] 14. Upgrade PageHeader with border and entrance animation

- [x] 15. Redesign KpiBento asymmetric bento grid with stagger

- [x] 16. Redesign AlertsPanel as row-based (no per-alert card wrappers)

- [x] 17. Redesign ActivityFeed as timeline with vertical connector line

- [x] 18. Fix TrendCard — use LineTrend directly

- [x] 19. Redesign login page split-screen layout

- [x] 20. Playwright verification — Overview and shell (light + dark mode)

- [x] 21. Playwright verification — all remaining routes, fix any issues

## Task Dependency Graph

```json
{
  "waves": [
    {
      "wave": 1,
      "tasks": [1, 2, 3, 4]
    },
    {
      "wave": 2,
      "tasks": [5, 6, 8, 9, 13]
    },
    {
      "wave": 3,
      "tasks": [7, 10, 11, 12, 14]
    },
    {
      "wave": 4,
      "tasks": [15, 16, 17, 18, 19]
    },
    {
      "wave": 5,
      "tasks": [20]
    },
    {
      "wave": 6,
      "tasks": [21]
    }
  ]
}
```

## Notes

- All changes are visual-layer-only: zero backend, auth, RBAC, API, or Zod schema changes
- Every component preserves its existing props interface — no breaking changes to parent pages
- The auto-review hook is configured — changes auto-apply without user approval prompts
- kiro-gpt-bridge MCP was not connected during spec creation; asset generation will proceed when available
- Playwright verification runs after implementation phases are complete
