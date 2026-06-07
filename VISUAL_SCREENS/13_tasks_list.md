# 13 · Tasks List — `/tasks`
Mode: **business** · Tab/Stack: **root tab 4 of 5** · Gate: none

> Tasks is the store's operational nerve center — the to-do system that keeps the team aligned.
> It must feel organized, priority-coded, and action-ready without being overwhelming.
> Governed by the Bible.

---

## Story arc
**Human beat** (what does the team need to do today?) →
**Substance** (priority-sorted, filterable task list with assignee + due-date context) →
**Action** (tap to view detail, FAB to create new task).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module |
|---|---|---|
| Task list | `GET /tasks?storeId=&status=&due=&cursor=` | tasks |
| Task create | `POST /tasks` | tasks |
| Task update | `PATCH /tasks/{id}` | tasks |
| Task detail | `GET /tasks/{id}` | tasks |

---

## Scroll zones (top → bottom)

### Z-HERO — Tasks header band *(~100 dp)*
- **Layout:** warm cream band. Title "Tasks" `headlineMedium` `w800` ink. Right: filter icon + add icon.
- **Summary strip:** 3 pills — "5 Due today" orange `#EA580C`, "12 Open" cat-violet `#6D5BD0`,
  "8 Completed" green `#15803D`. Tappable to filter.
- **Tokens + Motion:** same pattern as Expiry header.

### Z1 — Filter chips row *(horizontal scroll)*
- **Layout:** scrollable row of filter chips: "My Tasks · 5", "All Tasks · 17", "Completed · 8",
  "Overdue · 2". Active chip = orange tint + orange border + `w600`. Secondary = neutral.
- **Motion:** chip press-scale; active chip state transition 150 ms.

### Z2 — Task list *(cursor-paginated, grouped by priority)*
- **Priority group headers:** "HIGH PRIORITY" eyebrow in accent-deep `#9A3412` with a count badge.
  "MEDIUM PRIORITY", "LOW PRIORITY" in ink-soft. Groups collapse/expand.
- **Task rows:** 72 dp rows with:
  - Left: priority indicator dot (red/amber/green 8dp) + checkbox (role-gated complete action).
  - Center: task title `titleMedium` `w600` ink; assignee avatar (24dp circular) + name
    `bodySmall` ink-soft; due date `monoLabel` colored by urgency.
  - Right: task type chip ("Audit" / "Restock" / "GRN" / "Custom") + chevron.
  - Overdue rows: amber left border (4dp) + "OVERDUE" warn pill.
- **Pull-to-refresh:** custom orange.
- **Tokens:** row `space16` H; priority dot 8dp; assignee avatar `radius.full`; type chip `radius.full`.
- **A11y:** each row reads "Audit aisle 4, assigned to Rajan, due today, high priority".

### Z-FAB — Create task *(manager-only)*
- Orange FAB `+` icon. Role-gated: visible only to Manager/Admin. Routes to `17_task_create`.

### Z-NAV — Bottom navigation
Home · Scan · Expiry · **Tasks (active orange)** · Profile.

---

## Sub-surfaces
- **S1 · Sort/filter sheet** — sort by due date, priority, assignee; filter by type.
- **S2 · Quick status sheet** — long-press a row opens "Start / Complete / Cancel" quick actions.

---

## State gallery
`default (my tasks)` · `all tasks` · `completed` · `empty (no tasks)` · `loading`.

---

## Asset checklist
| ID | Asset | Tool | Save path | Brief |
|---|---|---|---|---|
| E0 | Full Tasks List mockup | `generate_ui_mockup` | `assets/mockup/tasks-list.png` | Tasks screen. Z-HERO: "Tasks" title w800, 3 stat pills "5 Due today (orange), 12 Open (violet), 8 Completed (green)". Filter chips row "My Tasks active (orange), All Tasks, Completed, Overdue". Task list with priority group header "HIGH PRIORITY" in accent-deep. 3 high-priority task rows: each row has a red dot + checkbox, task title like "Audit Aisle 4 — verify 12 EANs", assignee avatar + "Rajan" name, due "Today 3pm" in amber mono, "Audit" type chip, chevron. One row has "OVERDUE" amber pill. 2 medium-priority rows below. Orange FAB bottom-right. Tasks tab active in nav. Warm cream #FFFBF5, violet #6D5BD0 tint on Open pill, orange #EA580C, amber #B45309. iPhone 15. Plus Jakarta Sans + JetBrains Mono. No watermarks. |
| E1 | Task empty + completed states | `generate_ui_mockup` | `assets/mockup/tasks-states.png` | Two panels: LEFT = "No tasks" empty state: tonal clipboard badge on accent-tint circle, "All done!" title w700, "No open tasks assigned to you" subtitle, orange "Create new task" CTA (manager) or "All tasks complete — great job!" with a small sparkle. RIGHT = Completed tab: 3 task rows with green checkmark icons, strikethrough-style task titles in ink-soft, "Completed" green status chip on each, completion timestamp in mono. Warm cream palette. Two-panel iPhone 15. |

---

## Done gate
mockup beaten ✓ · tokens-only ✓ · priority-coding clear ✓ · role-gating (FAB) present ✓ · empty state personality ✓.
